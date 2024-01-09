// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";

contract MINTPSEmerald is ERC1155, Ownable {
    constructor() ERC1155("https://ipfs.io/ipfs/QmcHZG935XCNHsTkqMM9WnYeMw5jBmyy6fsZ7zv2m2yQHM/{id}") {}
    
    function sendPrivatePasses(address[] calldata _addresses) external onlyOwner {
        for(uint i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], 1, 1, "");
        }
    }
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override onlyOwner {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}