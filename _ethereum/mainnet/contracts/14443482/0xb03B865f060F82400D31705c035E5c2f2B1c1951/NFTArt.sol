// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "./RNG.sol";

library NFTArt {
    using RNG for RNG.Data;

    uint256 internal constant W_BASE = 30;
    uint256 internal constant W_RAND = 30;
    uint256 internal constant L_BASE = 30;
    uint256 internal constant L_RAND = 30;
    uint256 internal constant H_BASE = 20;
    uint256 internal constant H_RAND = 40;
    uint256 internal constant LAST_ROW_MIN_L = 55;
    uint256 internal constant FIRST_COL_MIN_W = 25;

    bytes6 internal constant FRAME_COLOR = "332E22";
    bytes6 internal constant COLOR1 = "E8E4DC";
    bytes internal constant COLOR2 = "6688EE6688EEFCBC18FDBD2EFE514EF2532DE7AC52EC6B2558C9EDEC6B25457DB6FCD265999999C3B89FF4AB13208793";
    bytes internal constant COLOR3 = "EE6666EE666628A7914561CC6CC2820B9594639AA0639AA0EF8FA3623A53DC5357DC505355555550978E9FBBC1C92B28";
    bytes internal constant BG_COLOR = "FBF5E9FBF5E9FBECE9F7F2E6ECEBE8EAEAEAF5EEE6";

    int256 internal constant LOGO_LENGTH = 112 * 35; // logo scale: 35
    int256 internal constant SCALE = 100;
    int256 internal constant OFFSET_X = ((600 / 2) + 0) * SCALE;
    int256 internal constant OFFSET_Y = ((600 / 2) + 20) * SCALE;
    int256 internal constant COS_30 = 86602540;
    int256 internal constant SIN_30 = 50000000;

    /**
     * w:       block width
     * l:       block length
     * h:       block height
     * (p, q):  block position in virtual plane
     * (x, y):  block position in projected plane
     */

    function isometric(int256 p, int256 q) internal pure returns (int256 x, int256 y) {
        unchecked {
            x = ((p + q) * COS_30) / 1e8 + OFFSET_X;
            y = ((q - p) * SIN_30) / 1e8 + OFFSET_Y;
        }
    }

    function intToString(int256 value) internal pure returns (bytes5 buffer) {
        assert(value >= 0 && value <= 99999);
        unchecked {
            // prettier-ignore
            buffer = bytes5(0x3030303030 + uint40(
                ((((uint256(value) / 1e0) % 10)) << 0) |
                ((((uint256(value) / 1e1) % 10)) << 8) |
                ((((uint256(value) / 1e2) % 10)) << 16) |
                ((((uint256(value) / 1e3) % 10)) << 24) |
                ((((uint256(value) / 1e4) % 10)) << 32)
            ));
        }
    }

    function pickColor(bytes memory choices, uint256 rand) internal pure returns (bytes6 picked) {
        unchecked {
            uint256 i = (rand % (choices.length / 6)) * 6;
            assembly {
                picked := mload(add(add(choices, 32), i))
            }
        }
    }

    struct Plane {
        int256 ax;
        int256 ay;
        int256 bx;
        int256 by;
        int256 cx;
        int256 cy;
        int256 dx;
        int256 dy;
    }

    function makeBlock(
        int256 p,
        int256 q,
        int256 w,
        int256 l,
        int256 h,
        bytes6 color,
        bool addLogo
    ) internal pure returns (bytes memory blk) {
        unchecked {
            Plane memory ground;
            (ground.ax, ground.ay) = isometric(p, q);
            (ground.bx, ground.by) = isometric(p + w, q);
            (ground.cx, ground.cy) = isometric(p + w, q + l);
            (ground.dx, ground.dy) = isometric(p, q + l);

            Plane memory cover = Plane({
                ax: ground.ax,
                ay: ground.ay - h,
                bx: ground.bx,
                by: ground.by - h,
                cx: ground.cx,
                cy: ground.cy - h,
                dx: ground.dx,
                dy: ground.dy - h
            });

            // prettier-ignore
            bytes memory coverCode = abi.encodePacked(
                '<path d="M', intToString(cover.ax), ",", intToString(cover.ay),
                "L", intToString(cover.bx), ",", intToString(cover.by),
                "L", intToString(cover.cx), ",", intToString(cover.cy),
                "L", intToString(cover.dx), ",", intToString(cover.dy), 'Z" fill="#', color, '"/>'
            );
            // prettier-ignore
            bytes memory sides = abi.encodePacked(
                '<path d="M', intToString(cover.ax), ",", intToString(cover.ay),
                "L", intToString(cover.dx), ",", intToString(cover.dy),
                "L", intToString(cover.cx), ",", intToString(cover.cy),
                "V", intToString(ground.cy),
                "L", intToString(ground.dx), ",", intToString(ground.dy),
                "L", intToString(ground.ax), ",", intToString(ground.ay), 'Z"/>'
            );
            blk = abi.encodePacked(sides, coverCode);

            if (addLogo) {
                (int256 x, int256 y) = isometric(p + w / 2, q + (l - LOGO_LENGTH) / 2);
                blk = abi.encodePacked(blk, '<use href="#logo" x="', intToString(x), '" y="', intToString(y - h), '"/>');
            }
        }
    }

    function makeBlocks(Config memory cfg) internal pure returns (bytes[8] memory rows) {
        unchecked {
            int256 qMemo = 0;
            for (uint256 q = 0; q < cfg.nrow; q++) {
                bytes[8] memory bs;
                int256 l = int256(cfg.ls[q]);

                uint256 i = 0;
                for (uint256 p = cfg.ncol - 1; p != type(uint256).max; --p) {
                    bytes6 color = cfg.colors[cfg.result % 3];
                    int256 w = int256(cfg.ws[p]);
                    int256 h = int256(cfg.hs[q][p]);
                    int256 pAdjusted = cfg.offsetP + int256(p == 0 ? 0 : cfg.wsCumSum[p - 1]);
                    int256 qAdjusted = cfg.offsetQ + qMemo;
                    bool addLogo = q == cfg.nrow - 1 && p == 0;

                    bs[i++] = makeBlock(pAdjusted, qAdjusted, w, l, h, color, addLogo);
                    cfg.result /= 3;
                }
                rows[q] = abi.encodePacked(bs[0], bs[1], bs[2], bs[3], bs[4], bs[5], bs[6], bs[7]);
                qMemo += l;
            }
        }
    }

    function makeSvg(Config memory cfg) internal pure returns (bytes memory svg) {
        bytes[8] memory rows = makeBlocks(cfg);
        svg = abi.encodePacked(
            '<svg viewBox="0 0 60000 60000" xmlns="http://www.w3.org/2000/svg">'
            '<def><g id="logo" fill="#332E22" stroke-width="0" transform="scale(35)">'
            '<path d="M18 20c2 1 2.3 2.3.6 3.2S14 24 12 23c-2-1-2.2-2.4-.6-3.2s4.6-1 6.6.1zm5.3 12.6c1.7-1 1.4-2.3-.6-3.2s-5-1-6.5-.2-1.3 2.3.6 3.2c2 1 4.8 1 6.5.2z"/>'
            '<path fill-rule="evenodd" d="M80 19.5C84.6 1 29.2-3.6 11 8-8.7 17.8 1 48 35.7 44.4c.2.2.5.3.8.4l23 9.8c1.8.8 4.3.7 6-.2L99.8 35c1.6-1 1.6-2.2.1-3.2l-19-12c-.3-.2-.6-.3-1-.4zM48.6 34C16.5 51-6.8 22.3 16 10.5 10 22 78 15.4 48.6 34zm45.2-.6l-13 7.4c-3-1-9.8-6.7-13.5-4.3-4.4 2 6.6 5.5 8.6 7L71 46.3c-3-1-11-6.5-14-4-3.8 2 7.4 5.2 9.5 6.6l-4 2.3L42.8 43l35-19.7 16 10.2z"/>'
            "</g></def>"
            '<rect width="60000" height="60000" fill="#',
            cfg.frameColor,
            '"/>'
            '<rect x="2500" y="2500" width="55000" height="55000" stroke="#332E22" stroke-width="200" fill="#',
            cfg.bgColor,
            '"/>'
            '<g fill="#332E22" stroke="#332E22" stroke-width="100">'
        );
        svg = abi.encodePacked(svg, rows[0], rows[1], rows[2], rows[3], rows[4], rows[5], rows[6], rows[7], "</g></svg>");
    }

    // ------- config -------

    struct Config {
        uint256 result;
        uint256 ncol;
        uint256 nrow;
        int256 offsetP;
        int256 offsetQ;
        uint256[8] ws;
        uint256[8] ls;
        uint256[8][8] hs;
        uint256[8] wsCumSum;
        bytes6[3] colors;
        bytes6 bgColor;
        bytes6 frameColor;
    }

    function generateConfig(
        uint256 result,
        uint256 ncol,
        uint256 nrow,
        uint256 salt
    ) internal pure returns (Config memory cfg) {
        RNG.Data memory rng = RNG.Data(salt, 0);

        cfg.result = result;
        cfg.ncol = ncol;
        cfg.nrow = nrow;

        cfg.colors[0] = COLOR1;
        cfg.colors[1] = pickColor(COLOR2, rng.rand());
        cfg.colors[2] = pickColor(COLOR3, rng.rand());
        cfg.bgColor = pickColor(BG_COLOR, rng.rand());
        cfg.frameColor = FRAME_COLOR;

        while (true) {
            // generate widths
            unchecked {
                uint256[8] memory ws = cfg.ws;
                uint256[8] memory wsCumSum = cfg.wsCumSum;
                uint256 rand = rng.rand();
                uint256 memo = 0;
                for (uint256 p = 0; p < ncol; ++p) {
                    uint256 w = (W_BASE + ((rand >> (8 * p)) % W_RAND)) * uint256(SCALE);
                    if (p == 0 && w < FIRST_COL_MIN_W) w = FIRST_COL_MIN_W;
                    wsCumSum[p] = (memo += (ws[p] = w));
                }
                cfg.offsetP = -int256(memo) / 2;
            }

            // generate lengths
            unchecked {
                uint256[8] memory ls = cfg.ls;
                uint256 rand = rng.rand();
                uint256 memo = 0;
                for (uint256 q = 0; q < nrow; ++q) {
                    uint256 l = (L_BASE + ((rand >> (8 * q)) % L_RAND)) * uint256(SCALE);
                    if (q == nrow - 1 && l < LAST_ROW_MIN_L) l = LAST_ROW_MIN_L;
                    memo += (ls[q] = l);
                }
                cfg.offsetQ = -int256(memo) / 2;
            }

            // ensure no "out of canvas"
            (int256 x0, ) = isometric(cfg.offsetP, cfg.offsetQ);
            if (x0 >= 3000) break;
        }

        // generate heights
        unchecked {
            uint256[8][8] memory hs = cfg.hs;
            for (uint256 q = 0; q < nrow; ++q) {
                uint256 rand = rng.rand();
                for (uint256 p = 0; p < ncol; ++p) {
                    hs[q][p] = (H_BASE + ((rand >> (8 * p)) % H_RAND)) * uint256(SCALE);
                }
            }
        }
    }

    // ------- entry point -------

    function drawSVG(
        uint256 result,
        uint256 ncol,
        uint256 nrow,
        uint256 salt
    ) internal pure returns (bytes memory svg) {
        return makeSvg(generateConfig(result, ncol, nrow, salt));
    }
}
