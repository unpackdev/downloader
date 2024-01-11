// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Buffers.sol";

library Paths {
    using Strings for uint256;
    using Buffers for Buffers.Writer;

    bytes private constant _PATH_OPS = "ZMLHVCS";

    struct Path {
        bool fill;
        bool stroke;
        uint256 fillId;
        string d;
    }

    function getDescription(
        uint256[] memory ops,
        uint256[] memory x,
        uint256[] memory y
    ) internal pure returns (string memory) {
        uint256 xi = 1;
        uint256 yi = 1;
        bytes1 op;
        Buffers.Writer memory d = Buffers.getWriter(800);
        d.writeWords("M", x[0].toString3(), " ", y[0].toString3());

        unchecked {
            for (uint256 i; i < ops.length; ) {
                d.writeChar(op = _PATH_OPS[ops[i++]]);

                if (op == "C") {
                    d.writeSentence(
                        x[xi++].toString3(),
                        y[yi++].toString3(),
                        x[xi++].toString3(),
                        y[yi++].toString3(),
                        x[xi++].toString3(),
                        y[yi++].toString3()
                    );
                } else if (op == "L" || op == "M") {
                    d.writeSentence(x[xi++].toString3(), y[yi++].toString3());
                } else if (op == "H") {
                    d.writeWord(x[xi++].toString3());
                } else if (op == "V") {
                    d.writeWord(y[yi++].toString3());
                } else if (op == "S") {
                    d.writeSentence(
                        x[xi++].toString3(),
                        y[yi++].toString3(),
                        x[xi++].toString3(),
                        y[yi++].toString3()
                    );
                }
            }
        }

        return d.toString();
    }
}
