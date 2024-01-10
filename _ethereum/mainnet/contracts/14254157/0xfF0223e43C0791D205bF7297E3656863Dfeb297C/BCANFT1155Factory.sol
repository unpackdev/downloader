// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Context.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./Ownable.sol";


contract BCANFT1155Factory is ERC1155, Ownable {
    
    constructor(string memory uri_) ERC1155(uri_) {
    }

    
    function mintTo(address to, uint256 id, uint256 amount, bytes memory data) public virtual onlyOwner {
        _mint(to, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts,
    bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }
    


}
