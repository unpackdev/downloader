// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC20.sol";
import "./SimpleGraveStone.sol";
import "./GraveStoneAbstract.sol";

contract Airdrop is Ownable {
    function excuteGraveStoneLock(address contractAddress, address[] memory tos, uint256 expTime)public onlyOwner returns (bool){
        require(tos.length > 0);
        GraveStoneAbstract graveStoneAbstract = GraveStoneAbstract(contractAddress);
        
        for (uint i = 0; i < tos.length; i++) {
            graveStoneAbstract.safeMintWithLock(tos[i], expTime);
        }
        return true;
    }

    function excuteGraveStone(address contractAddress, address[] memory tos)public onlyOwner returns (bool){
        require(tos.length > 0);
        GraveStoneAbstract graveStoneAbstract = GraveStoneAbstract(contractAddress);
        
        for (uint i = 0; i < tos.length; i++) {
            graveStoneAbstract.safeMint(tos[i]);
        }
        return true;
    }

    function excuteToken(address from, address contractAddress, address[] memory tos, uint256 amount) public returns (bool) {
        require(tos.length > 0);
        ERC20 erc20 = ERC20(contractAddress);
        for (uint i = 0; i < tos.length; i++) {
            erc20.transferFrom(from,tos[i],amount);
        }
        return true;
    }
}

    