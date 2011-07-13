"use strict"

String.prototype.splice = (start, count, stuff) ->
    @substring(0, start) + stuff + @substring(start + count)

$ = jQuery

PIT_RADIUS = 20
POPUP_WIDTH = 100
POPUP_HEIGHT = 100

COLORNAMES =
    a: 'yellow'
    b: 'red'
    c: 'blue'
    d: 'white'
    e: 'black'
    f: 'green'
    g: 'orange'
    h: 'violet'
    i: 'cyan'
    j: 'purple'

$('body').delegate 'a[href=#]', 'click', (e) ->
    e.preventDefault()

$.fn.newGame = (game) ->
    gameBox = $ this
    gameBox.empty()
    $('#msg').removeClass('finished lost')

    pegBoxMarkup = """
    <div id=pegBox>
        #{("<div class=\"peg-wrap\"><div data-val=\"#{c}\" class=\"#{color} peg\"/></div>" for c, color of COLORNAMES)[0...game.choices].join ''}
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
        <button class=check-btn>Check</button>
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
                    .css(width: 0, height: 0, top: 21, left: 21)
                    .animate({ width: 42, height: 42, 'slow', top: 0, left: 0 }, 'fast')
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
            slotRow.siblings('.active').removeClass('active')
                # .find('div.slot').droppable('option', 'scope', 'pegs-fin').droppable('option', 'scope')

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

        pebbles = slotRow.find('div.pebble')

        pebbles.slice(0, match.exact).addClass('exact')
        pebbles.slice(match.exact, match.exact + match.present).addClass('present')

        slotRow.after slotRow.clone().addClass('finished')
        slotRow.remove()

        if match.exact is guess.getLength()
            $('#msg').html('Game finished. Click <b>New game</b> to play again.').addClass('finished')
            openShowCase()
        else if round.getValue() is game.trials - 1
            $('#msg').html('Oops! Better luck next time. Click <b>New game</b> to play again.').addClass('lost')
            openShowCase()
        else
            round.inc()

        # Collect and save the game's progress
        allGuesses = gameBox.find('div.slot-row.finished').map(->
            guessStr = $(this).find('div.peg:not(.empty)').map(-> $(this).data('val')).toArray().join ''
        ).toArray()

        localStorage.lastGameGuesses = JSON.stringify allGuesses

    guess = do ->

        value = ''

        if game.guess?
            value = game.guess
        else
            while value.length isnt game.guessLength
                c = String.fromCharCode Math.floor Math.random() * game.choices + 97
                if game.repeat or c not in value
                    value += c

        match = (mstr) ->

            out =
                present: 0
                exact: 0

            if mstr is value
                out.exact = value.length
                return out

            for i in [0...value.length]

                c = value[i]

                if mstr[i] is c
                    ++out.exact
                    mstr = mstr.splice i, 1, '_'
                else
                    pos = mstr.indexOf c
                    if pos isnt -1
                        mstr = mstr.splice pos, 1, '_'
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

    do ->
        return unless localStorage.lastGameGuesses?

        try
            lastGameGuesses = JSON.parse localStorage.lastGameGuesses
        catch err
            return

        slotRows = gameBox.find 'div.slot-row'

        activeRowIndex = slotRows.length - lastGameGuesses.length
        # slotRows.eq(activeRowIndex).addClass 'active'

        for g, i in lastGameGuesses
            row = gameBox.find("div.slot-row:eq(#{i + activeRowIndex})")

            row.find('div.empty.peg').each (j) ->
                $(this).addClass('go-behind').after """<div data-val=#{g[j]} class="#{COLORNAMES[g[j]]} peg"
                    style="position:relative;left:auto;top:auto"></div>"""

            row.find('.check-btn').click()

    gameBox.data { game, guess, openShowCase }

defaultGame =
    trials: 10
    guessLength: 4
    choices: 6
    repeat: no

do @startNewGame = (game) ->

    if game?
        localStorage.clear()
    else
        if localStorage.lastGame?
            try
                game = JSON.parse(localStorage.lastGame)
            catch err
                game = defaultGame
        else
            game = defaultGame

    gameBox = $ '#gameBox'
    gameBox.newGame game
    game.guess = gameBox.data('guess').getValue()

    localStorage.lastGame = JSON.stringify game
