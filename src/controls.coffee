gameBox = $ '#gameBox'

newGameDialog = $ '#newGameDialog'
aboutBoxContainer = $ '#aboutBoxContainer'

newGameDialog.delegate 'span.peg-sample', 'click', (e) ->
    th = $ this

    choices = th.prevAll().length + 1
    guessLength = newGameDialog.find('span.slot-option.selected').data('value')

    if guessLength > choices
        newGameDialog.find('input.repeat').attr('checked', 1)
        # alert 'You have to have at least as many pegs as the slots for a sane game.'
        # return

    th.addClass 'on'
    th.prevAll().addClass 'on'
    th.nextAll().removeClass 'on'

newGameDialog.delegate 'span.slot-option', 'click', (e) ->
    $(this).addClass('selected').siblings().removeClass('selected')

newGameForm = $('#newGameForm').submit (e) ->
    e.preventDefault()

$('#newGameOkBtn').click (e) ->

    $('#newGameCancelBtn').click()

    game = 
        trials: 10
        guessLength: newGameDialog.find('span.slot-option.selected').data('value')
        choices: newGameDialog.find('span.peg-sample.on').length
        repeat: newGameDialog.find('input.repeat').is(':checked')

    console.info 'starting game', game

    gameBox.newGame game

$('#newGameCancelBtn').click (e) ->
    newGameForm.slideUp 'fast', ->
        newGameDialog.hide()

controllers =

    newGame: (e) ->
        newGameDialog.show()
        newGameForm.slideDown 'fast'
        currentGame = gameBox.data 'game'

        newGameDialog.find('span.peg-sample').removeClass('on')
            .slice(0, currentGame.choices).addClass('on')

        newGameDialog.find('span.slot-option').removeClass('selected')
            .eq(currentGame.guessLength - 2).addClass('selected')

        if currentGame.repeat
            newGameDialog.find('input.repeat').attr('checked', 1)
        else
            newGameDialog.find('input.repeat').removeAttr('checked')

        # gameBox.newGame
        #     trials: 10
        #     guessLength: 4
        #     choices: 10

    giveUp: (e) ->
        if $('#showcaseBox div.empty.peg').length is 0
            return
        if confirm "C'mon! Give it another try. You can make it!\n\nGive up?"
            gameBox.data('openShowCase')?()
            gameBox.html gameBox.html()

    restart: (e) ->
        if confirm 'Are you sure to restart this game?'
            gameBox.newGame $.extend { guess: gameBox.data('guess').getValue() }, gameBox.data('game')

    about: (e) ->
        aboutBoxContainer.fadeIn('fast')

$('#controlBox').delegate '.control-btn', 'click', (e) ->
    controllers[$(this).data('action')].call(this, e)

aboutBoxContainer.click (e) ->
    return unless e.target is this
    aboutBoxContainer.fadeOut('fast')
