//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";


contract SilkProxy is  Ownable {
    ERC1155Like public silk = ERC1155Like(0x59B03c31CCa3331a0a593a5c0179f39F8D9B0df9);


    function setSilk(address silkAddress) external onlyOwner {
        silk = ERC1155Like(silkAddress);
    }
    function airdrop(address[] calldata accounts) external {
        for(uint i; i <accounts.length; i++){
            silk.safeTransferFrom(msg.sender, accounts[i], 0,1,"");
        }
    }
}


interface ERC1155Like {

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint amount,
        bytes memory data
    ) external;

}