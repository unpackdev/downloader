// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract bulkTransfer is Ownable, IERC721Receiver{ 


    function onERC721Received(address operator, address, uint256 tokenId, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
        
    }

    function batchTransfer(address targetContract, address from, address to, uint256[] memory _ids) public onlyOwner{
        for (uint256 i; i < _ids.length; i++){
            (bool success, ) = targetContract.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, _ids[i]));
            require(success, "F");
        }

    }

    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
    }
}