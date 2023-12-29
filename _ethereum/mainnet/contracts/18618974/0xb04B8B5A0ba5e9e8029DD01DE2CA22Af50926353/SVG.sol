// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

// Core SVG utility library which helps us construct
// onchain SVG's with a simple, web-like API.
// Credit to w1nt3r.eth for the base of this.
library svg {
  /* MAIN ELEMENTS */

  function line(string memory _props) internal pure returns (string memory) {
    return string.concat("<line ", _props, "/>");
  }

  /* COMMON */

  // an SVG attribute
  function prop(string memory _key, string memory _val) internal pure returns (string memory) {
    return string.concat(_key, "=", '"', _val, '" ');
  }
}
