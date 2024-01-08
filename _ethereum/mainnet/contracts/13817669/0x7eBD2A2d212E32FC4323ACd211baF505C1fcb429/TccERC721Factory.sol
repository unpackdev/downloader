// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Clones.sol";
import "./Ownable.sol";
import "./TccERC721.sol";


contract TccERC721Factory is Ownable {


    address public impl;
    address[] public clonedContracts;

    constructor() {
        impl = address(new TccERC721());
    }

    function cloneTccERC721(string calldata _name, string calldata _symbol) external onlyOwner   {
        address payable clone = payable(Clones.clone(impl));
        TccERC721(clone).initialize(_name, _symbol, msg.sender);
        clonedContracts.push(clone);
    }
}
