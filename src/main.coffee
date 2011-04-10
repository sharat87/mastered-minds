R = Raphael

PIT_RADIUS = 20
POPUP_WIDTH = 100
POPUP_HEIGHT = 100

tries = 10
guessLength = 4
choices = 10

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

class Director

    constructor: (@length, @spaceSize) ->
        @guess = ''

        while @guess.length isnt @length
            n = Math.floor(Math.random() * @spaceSize).toString()
            if @guess.indexOf(n) isnt -1
                continue
            @guess += n

    match: (mstr) ->

        console.info 'match with', mstr

        out =
            present: 0
            exact: 0

        for i in [0...mstr.length]

            c = mstr[i]

            if @guess[i] is c
                ++out.exact
            else if @guess.indexOf(c) isnt -1
                ++out.present

        out


class Board

    constructor: (@root, @rows, @cols) ->
        console.info 'constructing O_o board'

        @director = new Director @cols, choices
        console.info 'guess', @director.guess

        @paper = R root, 200 + guessLength * 2 * PIT_RADIUS, tries * 2 * PIT_RADIUS

        @tries = @rows

        @round = 0

        @pits = {}
        @pitRows = []
        @pegs = []

        gap = 20
        rad = PIT_RADIUS
        pad = 2 + 2 * rad + gap

        for row in [0...@rows]

            # @pits[row] = {}

            r = new Row this, @cols, pad, 2 * rad * row, rad
            @pitRows.push r

            # for col in [0...@cols]
            #     b = new Pit @paper, pad + rad + 2 * rad * col, rad + 2 * rad * row, rad - 2
            #     @pits[row][col] = b

            # new Checker @paper, pad + gap + rad + 2 * rad * col, rad + 2 * rad * row

        for row in [0...choices]

            p = new Peg this, rad + 2, rad + 2 * rad * row, rad - 2
            p.setState row
            # p.setColor PEG_COLORS[row]

            @pegs.push p

        @setRound()

    setRound: (r=@round) ->
        @round = r
        @activePitRow = @pitRows[tries - r - 1]
        @activePitRow.setActive()


class Pit

    constructor: (@paper, x, y, r) ->
        @elem = @paper.circle x, y, r

        @isEmpty = yes

        @setColor PEGS.none

        @elem.attr
            stroke: null

        @elem.hover ((e) -> @attr 'stroke-opacity', 1), ((e) -> @attr 'stroke-opacity', 0)

        @elem.click (e) ->
            @elem = paper.rect x - (POPUP_WIDTH/2), y - r - POPUP_HEIGHT, POPUP_WIDTH, POPUP_HEIGHT, 2

            @elem.attr
                fill: 'white'

    setColor: (@state) ->
        @elem.attr 'fill', PEG_COLORS[@state]


class Row

    constructor: (@board, @cols, x, y, rad) ->
        @paper = @board.paper

        gap = 20
        @pits = []

        for col in [0...@cols]
            b = new Pit @paper, x + rad + 2 * rad * col, y + rad, rad - 2
            @pits.push b

        @checker = new Checker @board, x + gap + rad + 2 * rad * col, y + rad

    setActive: ->
        for b in @pits
            b.setColor PEGS.active

    updateCheckBtn: ->
        for pit in @pits
            if pit.isEmpty
                return

        @checker.showCheckBtn()

    match: ->
        matchResult = @board.director.match((pit.state for pit in @pits).join(''))
        @checker.display matchResult

        @board.setRound(@board.round + 1)


class Peg

    constructor: (@board, x, y, r) ->
        @paper = @board.paper

        @elem = @paper.circle x, y, r

        @elem.attr
            stroke: null

        @setState PEGS.none
        @movable()

    setState: (@state) ->
        @elem.attr 'fill', PEG_COLORS[@state]

    setColor: (color) ->
        @elem.attr 'fill', color

    movable: (e=@elem) ->
        self = this
        e.drag ((dx, dy) -> self.move this, dx, dy), (-> self.start this), (-> self.finish this)

    start: (de) ->

        # storing original coordinates
        de.ox = de.attr 'cx'
        de.oy = de.attr 'cy'

        # Put a clone in its place
        @clone = de.clone()
        @clone.attr cx: de.ox, cy: de.oy
        @movable @clone
        @clone.insertAfter de

        # Bring it to front
        de.toFront()

    move: (de, dx, dy) ->
        # move will be called with dx and dy
        de.attr cx: de.ox + dx, cy: de.oy + dy

        overlapAreas = {}
        maxOverlapElem =
            elem: null
            area: 0

        for targetPit in @board.activePitRow.pits

            box1 = de.getBBox()
            box2 = targetPit.elem.getBBox()

            # Check if a corner of box1 lies inside box2
            # Starting with top-left corner, clockwise
            cs = [
                { x: box1.x, y: box1.y }
                { x: box1.x + box1.width, y: box1.y }
                { x: box1.x, y: box1.y + box1.height }
                { x: box1.x + box1.width, y: box1.y + box1.height }
            ]

            overlappingCorner = null
            i = 0

            for c in cs
                if box2.x <= c.x <= box2.x + box2.width and box2.y <= c.y <= box2.y + box2.height
                    # The corner `c` lies in the box
                    overlappingCorner = c
                    break
                ++i

            if overlappingCorner?
                owidth = oheight = 0
                if i is 0 or i is 2
                    owidth = box2.x + box2.width - box1.x
                else
                    owidth = box1.x + box1.width - box2.x
                if i is 0 or i is 1
                    oheight = box2.y + box2.height - box1.y
                else
                    oheight = box1.y + box1.height - box2.y
                area = owidth * oheight

                if area > maxOverlapElem.area
                    maxOverlapElem =
                        targetPit: targetPit
                        area: area

        if maxOverlapElem.area > 80 and maxOverlapElem.targetPit?
            de.placeTarget = maxOverlapElem.targetPit

    finish: (de) ->

        de.placeTarget?.setColor @state

        de.placeTarget?.isEmpty = no

        de.remove()

        @board.activePitRow.updateCheckBtn()
        @elem = @clone
        @clone = null


class Checker

    constructor: (@board, @x, @y) ->
        @paper = @board.paper
        @dead = no

        @indicators = []

        irad = 5
        for dx in [-1, 1]
            for dy in [-1, 1]
                c = @paper.circle @x + dx * (irad + 2), @y + dy * (irad + 2), irad
                @indicators.push c
                c.attr
                    fill: '#BBB'
                    stroke: null

    showCheckBtn: ->

        width = 60
        height = 22

        console.info 'adding the button'

        # btn = @paper.rect @x - (width/2), @y - (height/2), width, height, 4
        # btn.attr
        #     fill: 'blue'

        @matchBtn = $('<a href="#" class="check-btn" style="position: absolute;">Check</a>').appendTo('#gameBox')
            .click(=> @board.activePitRow.match()).offset(top: @y, left: @x)

        # t = @paper.text @x, @y, 'Check', @paper.getFont('Inconsolata'), 14
        # t.attr
        #     'text-color': 'white'

    display: (matchResult) ->
        j = 0

        i = 0
        while i < matchResult.exact
            @indicators[j].attr
                fill: 'black'
            ++i
            ++j

        i = 0
        while i < matchResult.present
            @indicators[j].attr
                fill: 'white'
            ++i
            ++j

        @matchBtn.remove()
        @dead = yes


new Board 'gameBox', tries, guessLength
