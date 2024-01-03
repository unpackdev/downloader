// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./ERC1155.sol";

abstract contract LodgeToken is ERC1155 {
    constructor(string memory _newuri) internal ERC1155(_newuri) {}

    function setURI(string memory _newuri) external virtual;
    // function mint(address _account, uint256 _id, uint256 _amount, uint25) external virtual;
}