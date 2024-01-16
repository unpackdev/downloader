// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./IERC721.sol";

interface IERC721Core is IERC721 {

    function totalSupply() external returns (uint);

}

