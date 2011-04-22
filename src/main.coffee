"use strict"

$ = jQuery

PIT_RADIUS = 20
POPUP_WIDTH = 100
POPUP_HEIGHT = 100

PEGS =

    yellow: 0
    red: 1
    blue: 2
    white: 3
    black: 4
    green: 5
    orange: 6
    violet: 7
    cyan: 8
    purple: 9

    none: 10
    active: 11

PEG_COLORS = [
    '#DEA83D'
    '#9A1821'
    '#1964BE'
    '#DDDDDD'
    '#3D3D3D'
    '#4EA41D'
    '#D05E00'
    '#7540AA'
    '#009C9C'
    '#BC5ABC'
    '#DDD'
    '#88D'
]

colornames = [
    'yellow'
    'red'
    'blue'
    'white'
    'black'
    'green'
    'orange'
    'violet'
    'cyan'
    'purple'
]

$('body').delegate 'a[href=#]', 'click', (e) ->
    e.preventDefault()

$.fn.newGame = (game) ->
    gameBox = $ this
    gameBox.empty()

    pegBoxMarkup = """
    <div id=pegBox>
        #{("<div class=\"peg-wrap\"><div data-val=\"#{String.fromCharCode 97 + i}\" class=\"#{colornames[i]} peg\"/></div>" for i in [0...game.choices]).join ''}
    </div>
    """

    showcaseMarkup = """
    #{('<div class="empty peg">?</div>' for i in [1..game.guessLength]).join ''}
    <span class=repeat-status>Repeat #{if game.repeat then 'on' else 'off'}
    """

    slotMarkup = """
    <div class="slot">
        <div class="empty peg"/>
    </div>
    """

    pebbleMarkup = """
    <div class="pebble">
    </div>
    """

    indicatorMarkup = """
    <div class="indicator">
        #{(pebbleMarkup for i in [1..game.guessLength]).join ''}
        <a href="#" class=check-btn>Check</a>
    </div>
    """

    slotRowMarkup = """
    <div class="slot-row">
        #{(slotMarkup for i in [1..game.guessLength]).join('')}
        #{indicatorMarkup}
    </div>
    """

    boardMarkup = """
    <div id=boardBox>
        #{(slotRowMarkup for i in [1..game.trials]).join('')}
    </div>
    """

    clearFixMarkup = '<br style=clear:both />'

    gameBox.append(pegBoxMarkup + boardMarkup + clearFixMarkup)
    pegBox = $ '#pegBox'
    showcaseBox = $('#showcaseBox').html(showcaseMarkup)

    $.fn.mkPeg = do ->

        onStart = (e, ui) ->
            th = $ this
            th.addClass 'dragging'

        onStop = (e, ui) ->
            th = $ this
            th.removeClass 'dragging'

        -> this.draggable
            addClasses: no
            cancel: 'no-drag'
            containment: gameBox
            scope: 'pegs'
            revert: 'invalid'
            start: onStart
            stop: onStop

    pegBox.find('div.peg').mkPeg()

    $.fn.mkSlot = do ->

        onOver = (e, ui) ->
            if ui.draggable.parent()[0] != this
                $(this).addClass 'peg-hover'
            else
                $(this).children('div.empty.peg').addClass 'peg-hover'

        onOut = (e, ui) ->
            if ui.draggable.parent()[0] != this
                $(this).removeClass 'peg-hover'
            else
                $(this).children('div.empty.peg').removeClass 'peg-hover'

        onDrop = (e, ui) ->
            peg = $ ui.draggable
            slot = $ this

            peg.siblings('div.empty.peg').removeClass('go-behind')

            peg.css
                left: 'auto'
                top: 'auto'

            if peg.parent().is('.peg-wrap')
                clonedPeg = peg.parent().clone()
                clonedPeg.find('div.peg').mkPeg().removeClass('dragging ui-draggable-dragging')
                    .css(width: 0, height: 0, top: 18, left: 18)
                    .animate({ width: 36, height: 36, 'slow', top: 0, left: 0 }, 'fast')
                peg.parent().after clonedPeg

            emptyPeg = slot.find('div.empty.peg').addClass('go-behind')

            if peg.parent()[0] isnt slot[0]
                emptyPeg.siblings('div.peg').remove()

            pegParent = peg.parent()
            slot.removeClass('peg-hover').append(peg)

            if pegParent.is('.peg-wrap')
                pegParent.remove()

            updateRoundFillStatus()

        -> this.droppable
            addClasses: no
            scope: 'pegs'
            over: onOver
            out: onOut
            drop: onDrop

    round = do ->

        value = 0

        getSlotRow = ->
            $ "div.slot-row:eq(#{game.trials - value - 1})"

        activate = ->
            slotRow = getSlotRow().addClass('active')
            slotRow.find('div.slot').mkSlot()
            console.info slotRow.siblings('.active').removeClass('active')
                .find('div.slot').droppable('option', 'scope', 'pegs-fin').droppable('option', 'scope')

        inc = ->
            ++value
            activate()

        activate()

        {
            getValue: -> value
            toString: -> value.toString()
            getSlotRow
            inc
            activate
        }

    updateRoundFillStatus = ->
        emptySlots = game.guessLength - round.getSlotRow().find('div.empty.peg.go-behind').length

        if emptySlots is 0
            round.getSlotRow().find('.check-btn').show()
        else
            round.getSlotRow().find('.check-btn').hide()

    $('#boardBox').delegate '.check-btn', 'click', (e) ->
        slotRow = $(this).hide().closest('div.slot-row')
        chosenPegs = slotRow.find('div.peg:not(.empty)')

        matchStr = chosenPegs.map(-> $(this).data 'val').toArray().join ''
        match = guess.match matchStr

        console.info 'You guessed', matchStr, guess.match(matchStr)

        pebbles = slotRow.find('div.pebble')

        pebbles.slice(0, match.exact).addClass('exact')
        pebbles.slice(match.exact, match.exact + match.present).addClass('present')

        slotRow.after slotRow.clone().addClass('finished')
        slotRow.remove()

        if match.exact is guess.getLength()
            alert 'finished game!'
            openShowCase()
            return

        if round.getValue() is game.trials - 1
            alert 'Oops! Better luck next time'
            openShowCase()
            return

        round.inc()

    guess = do ->

        value = ''

        if game.guess?
            value = game.guess
        else
            while value.length isnt game.guessLength
                c = String.fromCharCode Math.floor Math.random() * game.choices + 97
                if game.repeat or c not in value
                    value += c

        console.info 'Try and guess', value

        match = (mstr) ->

            console.info 'match with', mstr

            out =
                present: 0
                exact: 0

            if mstr is value
                out.exact = value.length
                return out

            for i in [0...mstr.length]

                c = mstr[i]

                if value[i] is c
                    ++out.exact
                else if value.indexOf(c) isnt -1
                    ++out.present

            out

        {
            toString: -> value
            getValue: -> value
            getLength: -> value.length
            match
        }

    openShowCase = ->
        for c in guess.getValue()
            showcaseBox.find('div.empty.peg:first').replaceWith pegBox.find("div.peg[data-val=#{c}]").clone()

    gameBox.data { game, guess, openShowCase }

$('#gameBox').newGame
    trials: 10
    guessLength: 4
    choices: 6
    repeat: no
