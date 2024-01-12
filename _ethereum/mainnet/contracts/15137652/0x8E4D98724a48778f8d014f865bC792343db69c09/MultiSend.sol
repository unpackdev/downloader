// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC721.sol";

contract MultiSend{
    function isApproved(address tokenContract) public view returns(bool){
        IERC721 Token = IERC721(tokenContract);
        return Token.isApprovedForAll(msg.sender,address(this));
    }

    function transferMultiple(address tokenContract, address[] calldata _tos, uint[] calldata _tokenIds) public {
        require(_tos.length == _tokenIds.length,"arg length mismatch");

        IERC721 Token = IERC721(tokenContract);

        for(uint i = 0; i < _tos.length; i++){
            Token.transferFrom(msg.sender,_tos[i],_tokenIds[i]);
        }
    }
    function safeTransferMultiple(address tokenContract, address[] calldata _tos, uint[] calldata _tokenIds) public {
        require(_tos.length == _tokenIds.length,"arg length mismatch");

        IERC721 Token = IERC721(tokenContract);

        for(uint i = 0; i < _tos.length; i++){
            Token.safeTransferFrom(msg.sender,_tos[i],_tokenIds[i]);
        }
    }
}