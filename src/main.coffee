R = Raphael

BUBBLE_RADIUS = 20
POPUP_WIDTH = 100
POPUP_HEIGHT = 100

tries = 9
guessLength = 4
choices = 7

colors = [
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
]

class Board

    constructor: (@root, @rows, @cols) ->
        console.info 'constructing O_o board'

        @paper = R root, 200 + guessLength * 2 * BUBBLE_RADIUS, tries * 2 * BUBBLE_RADIUS

        @tries = @rows

        @round = 0

        @bubbles = {}
        @pegs = []

        gap = 20
        rad = BUBBLE_RADIUS
        pad = 2 + 2 * rad + gap

        for row in [0...@rows]

            @bubbles[row] = {}

            for col in [0...@cols]
                # b = R.placeBubble pad + rad + 2 * rad * col, rad + 2 * rad * row, rad - 2
                b = new Bubble @paper, pad + rad + 2 * rad * col, rad + 2 * rad * row, rad - 2

                # $(b.node).data('r', b).attr
                #     'data-row': row
                #     'data-col': col

                @bubbles[row][col] = b

                # if row is @rows - 1
                #     GameContext.dropTargets.push b

            new Checker @paper, pad + gap + rad + 2 * rad * col, rad + 2 * rad * row

        for row in [0...choices]

            p = new Peg this, rad + 2, rad + 2 * rad * row, rad - 2
            p.setColor colors[row]

            @pegs.push p

        @setRound()

    setRound: (r=@round) ->
        @dropTargets = []

        for col, bubble of @bubbles[@tries - r - 1]
            bubble.setColor '#888'
            @dropTargets.push bubble


class Bubble

    constructor: (@paper, x, y, r) ->
        @elem = @paper.circle x, y, r

        @elem.attr
            fill: '#DDD'
            stroke: null

        @elem.hover ((e) -> @attr 'stroke-opacity', 1), ((e) -> @attr 'stroke-opacity', 0)

        @elem.click (e) ->
            @elem = paper.rect x - (POPUP_WIDTH/2), y - r - POPUP_HEIGHT, POPUP_WIDTH, POPUP_HEIGHT, 2

            @elem.attr
                fill: 'white'

    setColor: (color) ->
        @elem.attr 'fill', color


class Peg

    constructor: (@board, x, y, r) ->
        @paper = @board.paper

        @elem = @paper.circle x, y, r

        @elem.attr
            stroke: null

        self = this
        @elem.drag ((dx, dy) -> self.move this, dx, dy), (-> self.start this), (-> self.finish this)

    setColor: (color) ->
        @elem.attr 'fill', color

    start: (de) ->

        # storing original coordinates
        de.ox = de.attr 'cx'
        de.oy = de.attr 'cy'

        # Put a clone in its place
        cl = de.clone()
        cl.attr cx: de.ox, cy: de.oy
        mkPeg cl
        cl.insertAfter de

        # Bring it to front
        de.toFront()

    move: (de, dx, dy) ->
        # move will be called with dx and dy
        de.attr cx: de.ox + dx, cy: de.oy + dy

        overlapAreas = {}
        maxOverlapElem =
            elem: null
            area: 0

        for target in @board.dropTargets

            box1 = de.getBBox()
            box2 = target.elem.getBBox()

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
                        target: target
                        area: area

        if maxOverlapElem.area > 80 and maxOverlapElem.target?
            de.placeTarget = maxOverlapElem.target

    finish: (de) ->

        de.placeTarget?.elem.attr
            fill: de.attr 'fill'

        de.remove()


class Checker

    constructor: (@paper, x, y) ->
        irad = 5
        for dx in [-1, 1]
            for dy in [-1, 1]
                c = @paper.circle x + dx * (irad + 2), y + dy * (irad + 2), irad
                c.attr
                    fill: '#BBB'
                    stroke: null


new Board 'gameBox', tries, guessLength
