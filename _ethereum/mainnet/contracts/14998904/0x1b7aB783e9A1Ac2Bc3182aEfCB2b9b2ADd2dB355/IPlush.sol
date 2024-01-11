//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

interface IPlush is IERC721Enumerable {

    function mintTo(address _to, uint256 _quantity) external;

}