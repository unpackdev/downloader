// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

library SVG {
    /* MAIN ELEMENTS */

    function line(string memory _props) internal pure returns (string memory) {
        return string.concat("<line ", _props, "/>");
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return string.concat('<rect height="1" width="1" ', _props, "/>");
    }

    /* COMMON */

    // an SVG attribute
    function prop(string memory _key, string memory _val) internal pure returns (string memory) {
        return string.concat(_key, "=", '"', _val, '" ');
    }
}
