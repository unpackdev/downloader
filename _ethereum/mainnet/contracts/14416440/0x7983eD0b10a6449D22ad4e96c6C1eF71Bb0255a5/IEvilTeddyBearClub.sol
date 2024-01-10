//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface IEvilTeddyBearClub is IERC721Enumerable {
    function mint(address) external;
}