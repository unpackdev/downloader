// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Ownable.sol";

contract RandomContract is Ownable{
    address private allowedContract;

    constructor(){}

    function setAllowedContract(address _contractAddress) public onlyOwner{
        require(isContract(_contractAddress),"Not a contract address");
        allowedContract = _contractAddress;
    }

    function random() public view returns (uint256) {
        require(msg.sender==allowedContract,"You are not allowed");

          return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number,
                    msg.sender
                )
            )
        );
    }

    function isContract(address addr) internal view returns (bool){
        uint size;
        assembly { size := extcodesize(addr)}
        return size > 0;        
    }
}