// SPDX-License-Identifier: UNLICENSED
// Copyright 2022 Arran Schlosberg
pragma solidity >=0.8.0 <0.9.0;

import "./Maths.sol";
import "./PRNG.sol";
import "./DynamicBuffer.sol";
import "./Strings.sol";
import "./base64.sol";

/**
@notice Rendering library for the generative-art collection, The Kiss Precise.
 */
library Kiss {
    using Maths for int256;
    using PRNG for PRNG.Source;
    using DynamicBuffer for bytes;
    using Strings for uint256;

    /**
    @notice Full description of the style (yes, rarity) parameters of a single
    Kiss rendering.
     */
    struct Style {
        // Does the image extend beyond the borders of the surrounding square?
        bool overflow;
        // Packing density before the algorithm returns.
        Density density;
        // Stroke width x32 to allow for fractional width when the SVG viewBox
        // shrinks it.
        uint16 strokeWidthMul32;
        uint8 strokeOpacity;
        // Use the horizontal diameter instead of the vertical one.
        bool horizontal;
        // Packing occurs on a single side of the diameter; if horizontal &&
        // !reflect then we have the effect of gravity having pulled on the
        // circles to the bottom.
        bool reflect;
        // When seeding a gasket off the midline, how many pairs deep before the
        // algorithm returns.
        uint16 nonMidlineDepth;
        uint16 midlineDepth;
        // If true, all Descartes circles in the same Pappus chain are coloured
        // identically;
        bool pappusColouring;
        // An outline renders as a standard Apollonian gasket, without explicit
        // circle colouring.
        bool outline;
        // Colours are hard!!!
        Palette palette;
        // A random cycling of the colour palette.
        uint8 paletteRotation;
        // A random index within the palette to use for the background and
        // midline-circle colours.
        uint8 backgroundIndex;
        uint8 midlineIndex;
        // On each iteration of the algorithm, the Circle of interest is
        // randomly split along the diameter to create an "arbelos". Using a
        // constant fraction (/256) is aesthetically pleasing. Zero value
        // indicates random fraction on each split.
        uint8 constantArbelosNumerator;
    }

    /**
    @notice Pseudo-enum describing how densely packed a Kiss rendering is.
    @dev There's a bug in abigen such that it doesn't properly support enums, so
    we have to use a custom type instead.
     */
    type Density is uint8;

    /**
    @notice Returns a == b.
     */
    function eq(Density a, Density b) internal pure returns (bool) {
        return Density.unwrap(a) == Density.unwrap(b);
    }

    /**
    @notice Possible Density pseudo-enum values.
     */
    Density internal constant LOW_DENSITY = Density.wrap(0);
    Density internal constant MED_DENSITY = Density.wrap(1);
    Density internal constant HIGH_DENSITY = Density.wrap(2);

    /**
    @notice Values for Style.constantArbelosNumerator.
     */
    uint8 internal constant SMALL_CONSTANT_NUMERATOR = 64;
    uint8 internal constant LARGE_CONSTANT_NUMERATOR = 192;

    /**
    @notice Returns a random Style from the seed.
     */
    function randomStyle(bytes32 seed)
        internal
        pure
        returns (Style memory style)
    {
        PRNG.Source src = PRNG.newSource(seed);
        uint256 rand;

        style.outline = src.read(5) == 0;
        if (style.outline) {
            bool light = src.read(5) < 11; // ~1/3
            bool kiss = !light && src.read(1) == 0;
            style.palette = outlinePalette(light, kiss);
            style.strokeWidthMul32 = 32;
            style.strokeOpacity = 50;
        } else {
            style.palette = palette(uint8(src.read(6)));

            style.backgroundIndex = uint8(src.read(2));
            style.midlineIndex = uint8(src.read(3));
            style.strokeWidthMul32 = style.palette.alwaysStroke ? 28 : 4;
            style.strokeOpacity = style.palette.alwaysStroke ? 15 : 100;
        }

        // Common
        // ------

        // Most of these choices (thresholds and proportions) were subjective
        // and chosen through experimentation while looking at thousands of
        // output images.

        style.reflect = true;
        style.paletteRotation = uint8(src.read(4));
        style.horizontal = src.read(4) == 0;
        style.pappusColouring = src.read(3) == 0;

        rand = src.read(5);
        if (!style.outline && rand < 4) {
            style.density = LOW_DENSITY;
        } else if (style.outline || rand < 16) {
            style.density = HIGH_DENSITY;
        } else {
            style.density = MED_DENSITY;
        }

        style.midlineDepth = 2 + uint16(src.read(3));
        if (style.midlineDepth > 8) {
            style.midlineDepth = 8;
        }
        if (style.outline && style.midlineDepth < 4) {
            style.midlineDepth = 4;
        }

        if (style.midlineDepth <= 5) {
            rand = src.read(4);
            if (rand == 0 && !eq(style.density, HIGH_DENSITY)) {
                style.nonMidlineDepth = 2;
            } else if (rand < 8 || (style.outline && rand < 12)) {
                style.nonMidlineDepth = 1;
            }
        }

        if (src.read(6) == 0) {
            style.constantArbelosNumerator = src.read(1) == 0
                ? SMALL_CONSTANT_NUMERATOR
                : LARGE_CONSTANT_NUMERATOR;
            style.pappusColouring = true;
            if (style.midlineDepth < 6) {
                style.midlineDepth = 6;
            }
            style.nonMidlineDepth = 0;
        }

        // End Common
        // ----------

        // Grails
        // ------

        bool gravity = src.read(5) < 3; // 3/32 ~10%
        if (gravity) {
            style.constantArbelosNumerator = 0; // turned off
            if (!style.outline) {
                style.strokeWidthMul32 = 20;
                style.strokeOpacity = 25;
            }
            style.reflect = false;
            style.horizontal = true;
            style.pappusColouring = false;
        }

        style.overflow = src.read(4) == 0; // 1/16
        if (style.overflow) {
            if (style.midlineDepth < 3) {
                style.midlineDepth = 3;
            }

            uint8 maxDepth = eq(style.density, HIGH_DENSITY) ? 4 : 7;
            if (style.midlineDepth > maxDepth) {
                // Reduce the chance of these failing due to having too many
                // circles due to high depth + high outer radius + small radius
                // lower bound.
                style.midlineDepth = maxDepth;
            }
            if (eq(style.density, HIGH_DENSITY)) {
                style.nonMidlineDepth = 0;
            }
        }

        if (gravity && style.overflow) {
            style.pappusColouring = src.read(3) < 3; // Really hope someone gets one of these!
            style.midlineDepth = 5;
            style.density = HIGH_DENSITY;
        }

        return style;
    }

    /**
    @notice Pseudo-functions implemented on the Kiss "VM" (it's a call stack,
    not an entire set of instructions).
    @dev This project is as much about aesthetics as it is about minimalist
    implementation; we are stripped of the most basic functionality that modern
    programmers take for granted. Note that the images are self-similar in their
    construction—repeating the same algorithm to pack circles ad infinitum—which
    naturally lends itself to recursive function calls. But where's the fun in
    that?! No recursive functions allowed! Only fundamentals? Ok, it's all just
    a single for loop ;)
     */
    enum Function {
        CreateInternal,
        Pack
    }

    /**
    @notice A frame on the Kiss call stack.
     */
    struct StackFrame {
        Function func;
        bool executed;
        // Args for CreateInternal()
        uint256 ancestor;
        uint16 depth;
        // Args for Pack()
        uint256[2] staticAnchors; // [outer containing, inner kissing]
        uint256 floatingAnchor;
    }

    /**
    @notice Couples Maths.Circle, a purely geometric construct, with stylistic
    information.
     */
    struct Circle {
        Maths.Circle geom;
        // We only generate circles along the right side and must later mirror
        // them. Internal gaskets must be mirrored more than once, so tracking
        // their parent is necessary for knowing the line of reflection. The
        // reflectOver field is transitive and reflection ends when it is equal
        // to the Circle's index in the buffer.
        uint256 reflectOver;
        // Index into the palette.
        uint8 colourIdx;
    }

    /**
    @notice Allocates a buffer, passes it to drawTo() for creation of an SVG,
    and returns the buffer.
     */
    function draw(bytes32 seed, Style memory style)
        internal
        pure
        returns (
            bytes memory svg_,
            uint16 numCircles,
            bool unbounded
        )
    {
        bytes memory svg = DynamicBuffer.allocate(2**18);
        assembly {
            svg_ := svg
        }
        (numCircles, unbounded) = drawTo(svg, seed, style);
    }

    int256 private constant CENTER = 500 * 2**64;

    /**
    @notice Draws a full SVG to the bytes buffer, with the layout determined
    from the seed.
    @param svg Output buffer, expected to be created with cxkoda's
    DynamicBuffer.
    @return numCircles Total number of circles generated by the packing
    algorithm.
    @return unbounded Whether the outer circle has the same colour as the
    background, thus giving the impression of being unbounded.
     */
    function drawTo(
        bytes memory svg,
        bytes32 seed,
        Style memory style
    ) internal pure returns (uint16 numCircles, bool unbounded) {
        Circle[2**13] memory circles;
        Maths.Circle[2] memory pair;
        PRNG.Source src = PRNG.newSource(seed);

        circles[0].geom.center.x = CENTER;
        circles[0].geom.center.y = CENTER;
        // Overflow fills the entire 1000x1000 square; its diagonal from the
        // centre is sqrt(2)*500 ~= 708.
        circles[0].geom.radius = style.overflow
            ? 708 * Maths.ONE
            : 400 * Maths.ONE;
        circles[0].reflectOver = 0; // i.e. itself therefore not reflected
        circles[0].colourIdx = uint8(src.read(4)); // [0,16)
        uint16 nextCircle = 1;

        int256 radiusLowerBound = circles[0].geom.radius; // never complete the Pappus chain
        if (eq(style.density, MED_DENSITY)) {
            radiusLowerBound = 50 * Maths.ONE;
        } else if (eq(style.density, HIGH_DENSITY)) {
            radiusLowerBound = 10 * Maths.ONE;
        }

        StackFrame[2**8] memory stack;
        stack[0].func = Function.CreateInternal;
        stack[0].ancestor = 0;
        stack[0].depth = style.midlineDepth;

        // The current frame is mirrored into args for ease of use—this uses a
        // little bit more memory and compute, but greatly eases readability.
        StackFrame memory args;

        uint256 pushTo;

        // When popping from the stack we use unchecked decrement of frame. If
        // this empties the stack then there will be a (deliberate) underflow,
        // causing frame == 2^256-1 > stack.length.
        for (uint256 frame = 0; frame < stack.length; ) {
            // Each "function" call is implemented by checking the respective
            // enum in the frame. Function-specific parameters are mirrored to
            // non-stack variables of the same name and type.
            args = stack[frame];

            if (args.executed) {
                // We've reached the current frame by a higher one being popped
                // (i.e. a function "return") and we've already executed this
                // frame so pop again.
                unchecked {
                    frame--;
                }
                continue;
            }
            stack[frame].executed = true;

            // Implementation of the respective functions. Woot!
            if (args.func == Function.CreateInternal) {
                pair = arbelos(
                    circles[args.ancestor].geom,
                    src,
                    style.constantArbelosNumerator
                );

                uint256[2] memory pairIdx;
                for (uint256 i = 0; i < 2; i++) {
                    circles[nextCircle].geom = pair[i];

                    // Reflecting over oneself implies no reflection, so mirror
                    // (pun intended) this behaviour in descendents.
                    circles[nextCircle].reflectOver = circles[args.ancestor]
                        .reflectOver != args.ancestor
                        ? circles[args.ancestor].reflectOver
                        : nextCircle;

                    pairIdx[i] = nextCircle;
                    nextCircle++;
                }

                // By definition of being in CreateInternal(), the ancestor is a
                // containing circle therefore we use a negative radius.
                circles[args.ancestor].geom.radius = -Maths.abs(
                    circles[args.ancestor].geom.radius
                );

                circles[nextCircle].geom = descartesRight(
                    circles[args.ancestor],
                    circles[pairIdx[0]],
                    circles[pairIdx[1]]
                );
                circles[nextCircle].reflectOver = args.ancestor;
                uint256 floatingAnchor = nextCircle;
                nextCircle++;

                // The colourIdx property is only used when Pappus colouring is
                // enabled, in which case we want the arbelos pair to match the
                // entire chain (the rest of the chain has its index copied from
                // the floatingAnchor).
                uint8 rand = uint8(src.read(4));
                circles[pairIdx[0]].colourIdx = rand;
                circles[pairIdx[1]].colourIdx = rand;
                circles[floatingAnchor].colourIdx = rand;

                // Pack()'s algorithm doesn't add the extra circle between the
                // first floating anchor and the two new midline ones.
                circles[nextCircle].geom = descartesRight(
                    circles[pairIdx[0]],
                    circles[pairIdx[1]],
                    circles[floatingAnchor]
                );
                circles[nextCircle].reflectOver = args.ancestor;
                nextCircle++;

                // Using the pseudo-function stack has a shortcoming in that we
                // can't return to a specific point in the code. Therefore all
                // "calls" must be at the end. As we wish to pack circles using
                // both the top and the bottom of the midline pair as anchors,
                // we must push _two_ frames to the stack.

                // Ancestor, _top_ circle, and new Descartes' circle as anchors.
                pushTo = frame + 1;
                stack[pushTo].func = Function.Pack;
                stack[pushTo].executed = false;
                stack[pushTo].staticAnchors[0] = args.ancestor;
                stack[pushTo].staticAnchors[1] = pairIdx[0]; // top
                stack[pushTo].floatingAnchor = floatingAnchor;

                // Ancestor, _bottom_ circle, and new Descartes' circle as
                // anchors.
                pushTo++;
                stack[pushTo].func = Function.Pack;
                stack[pushTo].executed = false;
                stack[pushTo].staticAnchors[0] = args.ancestor;
                stack[pushTo].staticAnchors[1] = pairIdx[1]; // bottom
                stack[pushTo].floatingAnchor = floatingAnchor;

                // Create a gasket inside first-level kissing circles.
                if (
                    style.nonMidlineDepth > 0 &&
                    circles[args.ancestor].geom.center.x == CENTER
                ) {
                    pushTo++;
                    stack[pushTo].func = Function.CreateInternal;
                    stack[pushTo].executed = false;
                    stack[pushTo].ancestor = floatingAnchor;
                    stack[pushTo].depth = style.nonMidlineDepth;
                }

                // Recursively call CreateInternal() by marking the current
                // frame as not executed. When the calls to Pack() "return",
                // this frame will therefore be entered again but using the
                // largest of the arbelos circles as the ancestor.
                stack[frame].depth--;
                if (stack[frame].depth > 0) {
                    stack[frame].executed = false;
                    // Larger circle is filled.
                    stack[frame].ancestor = pairIdx[
                        circles[pairIdx[0]].geom.radius >
                            circles[pairIdx[1]].geom.radius
                            ? 0
                            : 1
                    ];
                }

                // Start at the last function pushed to the stack because
                // each "return" is simply frame--.
                frame = pushTo;
            } else if (args.func == Function.Pack) {
                // Anchors may have had their radii set to negative if used in
                // CreateInternal(). The first one is the surrounding circle so
                // its radius is negated.
                circles[args.staticAnchors[0]].geom.radius = -Maths.abs(
                    circles[args.staticAnchors[0]].geom.radius
                );
                circles[args.staticAnchors[1]].geom.radius = Maths.abs(
                    circles[args.staticAnchors[1]].geom.radius
                );
                circles[args.floatingAnchor].geom.radius = Maths.abs(
                    circles[args.floatingAnchor].geom.radius
                );

                for (
                    uint256 lastFloating = args.floatingAnchor;
                    circles[args.floatingAnchor].geom.radius > radiusLowerBound;

                ) {
                    // The next circle in the Pappus chain around the secondary
                    // static anchor.
                    circles[nextCircle].geom = descartesRight(
                        circles[args.staticAnchors[0]],
                        circles[args.staticAnchors[1]],
                        circles[args.floatingAnchor]
                    );
                    circles[nextCircle].reflectOver = args.staticAnchors[0];
                    circles[nextCircle].colourIdx = circles[args.floatingAnchor]
                        .colourIdx;
                    args.floatingAnchor = nextCircle;
                    nextCircle++;

                    // The circle between the new one in the Pappus chain and
                    // each of the static anchors.
                    for (uint256 i = 0; i < 2; i++) {
                        circles[nextCircle].geom = descartesRight(
                            circles[args.floatingAnchor],
                            circles[lastFloating],
                            circles[args.staticAnchors[i]]
                        );
                        circles[nextCircle].reflectOver = args.staticAnchors[0];
                        nextCircle++;
                    }

                    lastFloating = args.floatingAnchor;
                }

                unchecked {
                    frame--; // return
                }
            } else {
                require(false, "Unimplemented function");
            }
        }

        // Reflect across midlines. This is a transitively inherited property
        // that ends when a Circle is denoted as reflecting over itself.
        if (style.reflect) {
            Circle memory c;
            Circle memory midline;
            for (uint256 i = 1; i < nextCircle; i++) {
                c = circles[i];

                for (uint256 over = c.reflectOver; over != i; ) {
                    midline = circles[c.reflectOver];

                    circles[nextCircle].geom.radius = c.geom.radius;
                    circles[nextCircle].geom.center.y = c.geom.center.y;
                    circles[nextCircle].geom.center.x =
                        2 *
                        midline.geom.center.x -
                        c.geom.center.x;
                    circles[nextCircle].colourIdx = c.colourIdx;

                    if (midline.reflectOver == c.reflectOver) {
                        // Neither this nor the new circle need to be reflected
                        // again. However, don't update c.reflectOver because that
                        // breaks the inheritance chain.
                        over = i;
                        circles[nextCircle].reflectOver = nextCircle;
                    } else {
                        // Transitively inherit reflection over the same ancestor.
                        c.reflectOver = midline.reflectOver;
                        circles[nextCircle].reflectOver = midline.reflectOver;
                    }

                    nextCircle++;
                }
            }
        }

        // nextCircle is now also the length of the circles buffer.
        return (nextCircle, generateSVG(svg, circles, nextCircle, style));
    }

    /**
    @notice Unwraps the style Circles and uses their geometries to determine the
    two other kissing circles. In the orientation in which the packing algorithm
    works, these will always be left and right, only one of which is returned as
    the mirroring fills in the left.
     */
    function descartesRight(
        Circle memory c0,
        Circle memory c1,
        Circle memory c2
    ) internal pure returns (Maths.Circle memory) {
        Maths.Circle[3] memory c;
        c[0] = c0.geom;
        c[1] = c1.geom;
        c[2] = c2.geom;
        return Maths.descartes(c)[0];
    }

    /**
    @notice For a given outer circle, split it randomly along the vertical
    diameter and return the two kissing circles that result; this is known as an
    "arbelos".
    @param constantNumerator Override the random splitting to use a constant
    fraction with a denominator of 256.
     */
    function arbelos(
        Maths.Circle memory outer,
        PRNG.Source src,
        uint8 constantNumerator
    ) internal pure returns (Maths.Circle[2] memory) {
        Maths.Circle[2] memory inner;
        inner[0].center.x = outer.center.x;
        inner[1].center.x = outer.center.x;

        if (constantNumerator > 0) {
            // An interesting side effect of this approach is that it leaves the
            // least significant bits untouched, which results in all midline
            // circles having identical colours because their 3 lsb are used as
            // surrogate random numbers in choosing a colour!
            int256 r = outer.radius * int16(uint16(constantNumerator));
            assembly {
                r := sar(8, r) // divide by 256
            }
            inner[0].radius = r;
        } else {
            // Never allow the smaller one to be <1/32 of the outer circle.
            int256 padding = outer.radius;
            assembly {
                padding := sar(5, padding)
            }
            inner[0].radius = int256(
                src.readLessThan(uint256(outer.radius - 2 * padding))
            );
            inner[0].radius += padding;
        }
        inner[1].radius = outer.radius - inner[0].radius;

        inner[0].center.y = outer.center.y - outer.radius + inner[0].radius;
        inner[1].center.y =
            inner[0].center.y +
            inner[0].radius +
            inner[1].radius;

        return inner;
    }

    /**
    @notice Returns an SVG representation of the circles and style.
    @return unbounded Whether the outer circle has the same colour as the
    background, thus giving the impression of being unbounded.
     */
    function generateSVG(
        bytes memory svg,
        Circle[2**13] memory circles,
        uint16 numCircles,
        Style memory style
    ) internal pure returns (bool unbounded) {
        // To fake fractional elements of the fixed-point scheme, the integers
        // are scaled up by 2^5 by Maths.toString(), as are the default
        // stroke-width + viewBox dimensions + rotational center, thus
        // compensating and resulting in no scaling.
        svg.appendUnchecked(
            "<svg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000' viewBox='0 0 32000 32000'>"
        );

        // #t for texture; inspired by rough paper from
        // https://tympanus.net/codrops/2019/02/19/svg-filter-effects-creating-texture-with-feturbulence/
        // and modified to blend with the underlying image.
        svg.appendUnchecked(
            "<filter id='t' x='0%' y='0%' width='100%' height='100%'>"
        );
        svg.appendUnchecked(
            "<feTurbulence type='fractalNoise' baseFrequency='0.04' result='n' numOctaves='5' />"
        );
        svg.appendUnchecked(
            "<feDiffuseLighting in='n' lighting-color='white' surfaceScale='0.4' diffuseConstant='1.35' result='l'>"
        );
        svg.appendUnchecked("<feDistantLight azimuth='-90' elevation='45' />");
        svg.appendUnchecked("</feDiffuseLighting>");
        svg.appendUnchecked(
            "<feBlend in='SourceGraphic' in2='l' mode='multiply'/>"
        );
        svg.appendUnchecked("</filter>");

        // CSS
        svg.appendUnchecked("<style>");
        // All circles
        svg.appendUnchecked("circle{stroke:");
        svg.appendUnchecked(hexColour(style.palette.stroke));
        svg.appendUnchecked(";stroke-width:");
        svg.appendUnchecked(bytes(uint256(style.strokeWidthMul32).toString()));
        svg.appendUnchecked(";stroke-opacity:");
        svg.appendUnchecked(bytes(uint256(style.strokeOpacity).toString()));
        svg.appendUnchecked("%}");
        // Fills
        for (uint256 i = 0; i < style.palette.foreground.length; i++) {
            svg.appendUnchecked(".c");
            svg.appendUnchecked(bytes(i.toString()));
            svg.appendUnchecked("{fill:");
            svg.appendUnchecked(hexColour(style.palette.foreground[i]));
            svg.appendUnchecked("}");
        }
        for (uint256 i = 0; i < style.palette.midline.length; i++) {
            svg.appendUnchecked(".m");
            svg.appendUnchecked(bytes(i.toString()));
            svg.appendUnchecked("{fill:");
            svg.appendUnchecked(hexColour(style.palette.midline[i]));
            svg.appendUnchecked("}");
        }
        svg.appendUnchecked("</style>");

        // Texture
        svg.appendUnchecked("<g filter='url(#t)'>");

        // Background rectangle
        svg.appendUnchecked("<rect width='32000' height='32000' fill='");
        svg.appendUnchecked(
            hexColour(style.palette.background[style.backgroundIndex])
        );
        svg.appendUnchecked("'/>");

        // Rotation
        svg.appendUnchecked("<g transform='rotate(");
        svg.appendUnchecked(style.horizontal ? bytes("90") : bytes("0"));
        svg.appendUnchecked(",16000,16000)'>");

        uint256 color;
        for (uint256 i = 0; i < numCircles; i++) {
            svg.appendUnchecked("<circle cx='");
            svg.appendUnchecked(
                bytes(Maths.toString(circles[i].geom.center.x, 5))
            );
            svg.appendUnchecked("' cy='");
            svg.appendUnchecked(
                bytes(Maths.toString(circles[i].geom.center.y, 5))
            );
            svg.appendUnchecked("' r='");
            svg.appendUnchecked(
                bytes(Maths.toString(Maths.abs(circles[i].geom.radius), 5))
            );

            svg.appendUnchecked("' class='");
            if (
                !style.pappusColouring &&
                (i == 1 || i == 2) &&
                style.palette.midline[0] != IGNORE_COLOUR
            ) {
                svg.appendUnchecked("m");
                svg.appendUnchecked(
                    bytes(uint256(style.midlineIndex).toString())
                );
            } else {
                svg.appendUnchecked("c");
                color = style.pappusColouring
                    ? circles[i].colourIdx
                    : uint8(uint256(circles[i].geom.center.y & 15));
                // When pappusColouring==false the big circle will always have
                // the same background unless we rotate the palette.
                color = (color + style.paletteRotation) & 15;
                svg.appendUnchecked(bytes(color.toString()));

                // If the primary circle as the same colour as the background,
                // the drawing gives the impression of being unbounded. This is
                // an artifact of the drawing process, not explicitly part of
                // the input style, so we have to compute it here.
                if (
                    i == 0 &&
                    !style.outline &&
                    !style.overflow &&
                    style.palette.foreground[color] ==
                    style.palette.background[style.backgroundIndex]
                ) {
                    unbounded = true;
                }
            }

            svg.appendUnchecked("'/>");
        }

        // Close texture and rotation groups.
        for (uint256 i = 0; i < 2; i++) {
            svg.appendUnchecked("</g>");
        }
        svg.appendUnchecked("</svg>");
    }

    bytes16 private constant HEX_CHARS = "0123456789abcdef";

    /**
    @notice Returns a CSS-compatible string represention of the colour.
     */
    function hexColour(uint24 _col) internal pure returns (bytes memory) {
        // bytes3 are easier to work with than uint24 because they have indexing
        // whereas we'd ideally have uint24 in little-endian (bgr) colour
        // ordering.
        bytes3 col = bytes3(_col);
        bytes memory rgb = new bytes(7);
        rgb[0] = "#";
        for (uint256 i = 0; i < 3; i++) {
            rgb[i * 2 + 1] = HEX_CHARS[uint8(col[i]) / 16];
            rgb[i * 2 + 2] = HEX_CHARS[uint8(col[i]) & 15];
        }
        return rgb;
    }

    /**
    @notice Palette describing possible colours for different parts of a Kiss
    image, with RGB encoded as a uint24 such that Solidity numerical literals
    are equivalent to CSS hex.
     */
    struct Palette {
        string name;
        uint24[4] background;
        uint24[8] midline;
        uint24[16] foreground;
        uint24 stroke;
        // Indicates that the stroke-width must always be thick enough to be
        // visible. In all other cases, the stroke is present but very faint as
        // a means of demonstrating the underlying construction (like an
        // artist's sketch).
        bool alwaysStroke;
    }

    /**
    @notice A flag value indicating that a colour should be ignored rather than
    used literally. As we don't utilise black #000000 it is a suitable choice.
     */
    uint24 constant IGNORE_COLOUR = 0;

    /**
    @notice Returns one of the Kiss palettes, weighted for different
    proportional occurrence. @param weightedIndex A uniformly random number
    [0,64).
     */
    function palette(uint256 weightedIndex)
        internal
        pure
        returns (Palette memory p)
    {
        // Confirms an external invariant, therefore not revert.
        assert(weightedIndex < 64);

        // TODO: update the names
        if (weightedIndex < 8) {
            return
                Palette({
                    name: "Descartes",
                    background: [0xfbf9eb, 0xfbf9eb, 0xda6746, 0x1f2a33],
                    midline: [
                        0xda6746,
                        0xda6746,
                        0x8cb3b8,
                        0x8cb3b8,
                        0xe6bc6e,
                        0xe6bc6e,
                        0x1f2a33,
                        0x1f2a33
                    ],
                    foreground: [
                        0xda6746,
                        0xda6746,
                        0xda6746,
                        0x8cb3bb,
                        0x8cb3bb,
                        0x8cb3bb,
                        0x8cb3bb,
                        0xe6bc6e,
                        0xe6bc6e,
                        0xe6bc6e,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0xfbf9eb,
                        0xfbf9eb,
                        0xfbf9eb
                    ],
                    stroke: 0x4a8184,
                    alwaysStroke: false
                });
        } else if (weightedIndex < 16) {
            return
                Palette({
                    name: "Oh",
                    background: [0xfbf9eb, 0x4a8184, 0x1f2a33, 0xffad9e],
                    midline: [
                        0xfbf8f4,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0xd98f89,
                        0xd98f89,
                        0xd98f89
                    ],
                    foreground: [
                        0xfbf9eb,
                        0xfbf9eb,
                        0xfbf9eb,
                        0xfbf9eb,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0x4a8184,
                        0x4a8184,
                        0x4a8184,
                        0x4a8184,
                        0xffad9e,
                        0xffad9e,
                        0xffad9e,
                        0xffad9e
                    ],
                    stroke: 0x8cb3b8,
                    alwaysStroke: false
                });
        } else if (weightedIndex < 24) {
            return
                Palette({
                    name: "Mirzakhani",
                    background: [0xf2e2c4, 0xd4e2d4, 0x77a688, 0x8cb3b8],
                    midline: [
                        0xd4e2d4,
                        0xd4e2d4,
                        0x8cb3b8,
                        0x8cb3b8,
                        0x1f2a33,
                        0x1f2a33,
                        0x4a8184,
                        0x4a8184
                    ],
                    foreground: [
                        0x77a688,
                        0x77a688,
                        0x77a688,
                        0xf2e2c4,
                        0xf2e2c4,
                        0xf2e2c4,
                        0x8cb3b8,
                        0x8cb3b8,
                        0x8cb3b8,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0x4a8184,
                        0x4a8184,
                        0x4a8184,
                        0xd4e2d4
                    ],
                    stroke: 0xc84947,
                    alwaysStroke: false
                });
        } else if (weightedIndex < 32) {
            return
                Palette({
                    name: "Keen",
                    background: [0x8cb3b8, 0x1f2a33, 0xfbf8f4, 0xe4dfd5],
                    midline: [
                        0xffad9e,
                        0xffad9e,
                        0xc84947,
                        0xc84947,
                        0xdbc7ac,
                        0xdbc7ac,
                        0x4a8184,
                        0x4a8184
                    ],
                    foreground: [
                        0xc84947,
                        0xc84947,
                        0xc84947,
                        0xdbc7ac,
                        0xdbc7ac,
                        0x4a8184,
                        0x4a8184,
                        0x4a8184,
                        0x4a8184,
                        0xe4dfd5,
                        0xe4dfd5,
                        0xe4dfd5,
                        0xe4dfd5,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33
                    ],
                    stroke: 0x1b998b,
                    alwaysStroke: false
                });
        } else if (weightedIndex < 35) {
            return
                Palette({
                    name: "Riemann",
                    background: [0x65757F, 0x65757F, 0x1f2a33, 0x1f2a33],
                    midline: [
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR
                    ],
                    foreground: [
                        0x0a0d0b,
                        0x0a0d0b,
                        0x0a0d0b,
                        0x0a0d0b,
                        0xd4e2d4,
                        0xd4e2d4,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0x65757F,
                        0x65757F,
                        0x65757F,
                        0x65757F,
                        0x65757F,
                        0x65757F
                    ],
                    stroke: 0x8cb3b8,
                    alwaysStroke: true
                });
        } else if (weightedIndex < 38) {
            return
                Palette({
                    name: "Hypatia",
                    background: [0xe9c3b3, 0xe9c3b3, 0xe9c3b3, 0xe9c3b3],
                    midline: [
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR
                    ],
                    foreground: [
                        0xd98f89,
                        0xd98f89,
                        0xd98f89,
                        0xd98f89,
                        0xe9c3b3,
                        0xe9c3b3,
                        0xe9c3b3,
                        0xff9b71,
                        0xff9b71,
                        0xff9b71,
                        0x302840,
                        0x302840,
                        0x302840,
                        0x302840,
                        0x723d46,
                        0x723d46
                    ],
                    stroke: 0xc84947,
                    alwaysStroke: false
                });
        } else if (weightedIndex < 41) {
            return
                Palette({
                    name: "Soddy",
                    background: [0xfbf8f4, 0xc9cba3, 0xc9cba3, 0x203420],
                    midline: [
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR
                    ],
                    foreground: [
                        0xc9cba3,
                        0xc9cba3,
                        0xc9cba3,
                        0xd4e2d4,
                        0xd4e2d4,
                        0xd4e2d4,
                        0x203420,
                        0x203420,
                        0x203420,
                        0xe9c3b3,
                        0xe9c3b3,
                        0xe9c3b3,
                        0x919f70,
                        0x919f70,
                        0x919f70,
                        0x919f70
                    ],
                    stroke: 0x723d46,
                    alwaysStroke: false
                });
        } else if (weightedIndex < 44) {
            return
                Palette({
                    name: "Series",
                    background: [0xf4e0cd, 0xf4e0cd, 0xf4e0cd, 0xfbf8f4],
                    midline: [
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR
                    ],
                    foreground: [
                        0xd4e2d4,
                        0xd4e2d4,
                        0xd4e2d4,
                        0xd4e2d4,
                        0xff9b71,
                        0xff9b71,
                        0xff9b71,
                        0xff9b71,
                        0xff9b71,
                        0xff9b71,
                        0xff9b71,
                        0xff9b71,
                        0xfbf8f4,
                        0xfbf8f4,
                        0xfbf8f4,
                        0xfbf8f4
                    ],
                    stroke: 0x8cb3b8,
                    alwaysStroke: false
                });
        } else if (weightedIndex < 48) {
            return
                Palette({
                    name: "Noether",
                    background: [0xf4e0cd, 0xf4e0cd, 0xf4e0cd, 0xe4dfd5],
                    midline: [
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR
                    ],
                    foreground: [
                        0xc84947,
                        0xc84947,
                        0xc84947,
                        0xc84947,
                        0xf4e0cd,
                        0xf4e0cd,
                        0xf4e0cd,
                        0xf4e0cd,
                        0xe9c3b3,
                        0xe9c3b3,
                        0xe9c3b3,
                        0xe9c3b3,
                        0xd98f89,
                        0xd98f89,
                        0xd98f89,
                        0xd98f89
                    ],
                    stroke: 0xfbf8f4,
                    alwaysStroke: false
                });
        } else if (weightedIndex < 56) {
            return
                Palette({
                    name: "Klein",
                    background: [0x1f2a33, 0x8cb3b8, 0xffb433, 0xffb433],
                    midline: [
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR,
                        IGNORE_COLOUR
                    ],
                    foreground: [
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0x1f2a33,
                        0xffb433,
                        0xffb433,
                        0xfbf8f4,
                        0xfbf8f4,
                        0xfbf8f4,
                        0xfbf8f4,
                        0x4a8184,
                        0x4a8184,
                        0x4a8184,
                        0x4a8184,
                        0x8cb3b8,
                        0x8cb3b8
                    ],
                    stroke: 0x1b998b,
                    alwaysStroke: false
                });
        } else {
            return
                Palette({
                    name: "Mobius",
                    background: [0xfbf8f4, 0xfbf8f4, 0xffb433, 0x302840],
                    midline: [
                        0xd4e2d4,
                        0xd4e2d4,
                        0xd4e2d4,
                        0xd4e2d4,
                        0xffb433,
                        0xffb433,
                        0xffb433,
                        0xffb433
                    ],
                    foreground: [
                        0x1b998b,
                        0x1b998b,
                        0x1b998b,
                        0x1b998b,
                        0x302840,
                        0x302840,
                        0x302840,
                        0xd4e2d4,
                        0xd4e2d4,
                        0xd4e2d4,
                        0xffb433,
                        0xffb433,
                        0xda6746,
                        0xda6746,
                        0xda6746,
                        0xda6746
                    ],
                    stroke: 0xfbf8f4,
                    alwaysStroke: false
                });
        }
    }

    /**
    @notice Colours used by outlinePalette().
     */
    uint24 private constant KISS_RED = 0xc84947;
    uint24 private constant BLUEPRINT = 0x1f2a33;
    uint24 private constant OUTLINE = 0xfbf9eb;

    /**
    @notice Returns the palette for the specified outline (see Style)
    configuration.
    @param light Use a light background to appear like a sketch. MUST be false
    if kiss==true.
    @param kiss Use a red background if !light, otherwise a blue one.
     */
    function outlinePalette(bool light, bool kiss)
        internal
        pure
        returns (Palette memory p)
    {
        uint24 fill;

        if (kiss) {
            // Confirms an external invariant, therefore not revert.
            assert(!light);
            p.name = "Kiss";
            fill = KISS_RED;
            p.stroke = OUTLINE;
        } else {
            if (light) {
                p.name = "Sketch";
                fill = OUTLINE;
                p.stroke = BLUEPRINT;
            } else {
                p.name = "Blueprint";
                fill = BLUEPRINT;
                p.stroke = OUTLINE;
            }
        }

        for (uint256 i = 0; i < p.background.length; i++) {
            p.background[i] = fill;
        }
        for (uint256 i = 0; i < p.foreground.length; i++) {
            p.foreground[i] = fill;
        }
        for (uint256 i = 0; i < p.midline.length; i++) {
            p.midline[i] = IGNORE_COLOUR;
        }
        return p;
    }

    /**
    @notice Functions identically to ERC721.tokenURI but accepts a seed instead
    of a tokenId.
    @dev Seed management is beyond the scope of this library.
     */
    function tokenURI(uint256 tokenId, bytes32 seed)
        internal
        pure
        returns (string memory uri_)
    {
        bytes memory uri = DynamicBuffer.allocate(2**18);
        assembly {
            uri_ := uri
        }

        uri.appendUnchecked('data:application/json,{"name":"Kiss %23');
        uri.appendUnchecked(bytes(tokenId.toString()));
        uri.appendUnchecked('",');

        Style memory style = randomStyle(seed);

        // Ideally we'd be able to use drawTo() here and pass the uri buffer
        // directly, but OpenSea wasn't playing nicely with non-base64 SVGs.
        uri.appendUnchecked('"image":"data:image/svg+xml;base64,');
        (bytes memory svg, uint16 numCircles, bool unbounded) = draw(
            seed,
            style
        );
        uri.appendUnchecked(bytes(Base64.encode(svg)));

        uri.appendUnchecked('","attributes":[');

        addFirstAttribute(uri, "Palette", bytes(style.palette.name));
        addAttribute(uri, "Circles", numCircles);

        addAttribute(uri, "Depth", uint256(style.midlineDepth));
        if (style.nonMidlineDepth > 0) {
            addAttribute(
                uri,
                "Non-midline Depth",
                uint256(style.nonMidlineDepth)
            );
        }

        if (style.overflow) {
            addAttribute(uri, "", "Overflow");
        }
        if (style.horizontal) {
            addAttribute(
                uri,
                "",
                bytes(style.reflect ? "Horizontal" : "Gravity")
            );
        }

        if (style.constantArbelosNumerator != 0) {
            addAttribute(uri, "", "Constant Ratio");
        }
        if (style.outline) {
            addAttribute(uri, "", "Outline");
        } else {
            if (style.pappusColouring) {
                addAttribute(uri, "", "Pappus Chains");
            }
            if (unbounded) {
                addAttribute(uri, "", "Unbounded");
            }
        }

        bytes memory density;
        if (eq(style.density, LOW_DENSITY)) {
            density = "Low";
        } else if (eq(style.density, MED_DENSITY)) {
            density = "Medium";
        } else {
            density = "High";
        }
        addAttribute(uri, "Density", density);

        uri.appendUnchecked("]}");
    }

    /**
    @notice Add the very first attribute; i.e. without a preceding comma.
    @dev See _addAttribute().
     */
    function addFirstAttribute(
        bytes memory uri,
        bytes memory name,
        bytes memory value
    ) internal pure {
        _addAttribute(uri, name, value, true, false);
    }

    /**
    @notice Add a string attribute.
    @dev See _addAttribute().
     */
    function addAttribute(
        bytes memory uri,
        bytes memory name,
        bytes memory value
    ) internal pure {
        _addAttribute(uri, name, value, false, false);
    }

    /**
    @notice Add a numerical attribute.
    @dev See _addAttribute().
     */
    function addAttribute(
        bytes memory uri,
        bytes memory name,
        uint256 value
    ) internal pure {
        _addAttribute(uri, name, bytes(value.toString()), false, true);
    }

    /**
    @notice Writes an ERC721 metadata attribute to the URI buffer.
    @param uri A buffer allocated by DynamicBuffer and assumed to have
    sufficient capacity.
    @param first Don't prepend a comma.
    @param numerical Don't quote the value, and add an explicity display_type of
    number.
     */
    function _addAttribute(
        bytes memory uri,
        bytes memory name,
        bytes memory value,
        bool first,
        bool numerical
    ) internal pure {
        if (!first) {
            uri.appendUnchecked(",");
        }
        uri.appendUnchecked("{");

        if (name.length != 0) {
            uri.appendUnchecked('"trait_type":"');
            uri.appendUnchecked(name);
            uri.appendUnchecked('",');
        }

        uri.appendUnchecked('"value":');
        if (numerical) {
            uri.appendUnchecked(
                abi.encodePacked(value, ',"display_type":"number"')
            );
        } else {
            uri.appendUnchecked(abi.encodePacked('"', value, '"'));
        }

        uri.appendUnchecked("}");
    }
}
