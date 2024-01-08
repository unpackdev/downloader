//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./IERC721Enumerable.sol";

interface IOrcs is IERC721Enumerable {
    function mint(address) external;
}
