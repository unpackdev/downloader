// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol" ; 

contract BridgeShibesV2 is Ownable {
    bool public online = true ; 

    IERC721 public shibes ; 

    constructor (address _shibes) {
        shibes = IERC721(_shibes) ; 
    }

    mapping(uint => bool) public bridged ; 

    event Bridge(address indexed owner, uint indexed tokenID, uint timestamp) ; 

    function bridge(uint[] memory tokenIDs) public returns (bool) {
        require(online, "bridge offline") ;

        for (uint i; i < tokenIDs.length; i ++) {
            require(bridged[tokenIDs[i]] == false, "tokenID already bridged") ;  
            require(shibes.ownerOf(tokenIDs[i]) == msg.sender, "sender not owner") ;
            bridged[tokenIDs[i]] = true ; 
            emit Bridge(msg.sender, tokenIDs[i], block.timestamp) ;

        }
 

        return true ; 
    }

    function changeBridgeState(bool state) external onlyOwner returns (bool) {
        require (online != state, "Bridge already in state") ; 

        online = state ; 

        return true ; 
    }

    function changeShibesContract(address _shibes) external onlyOwner returns (bool) {
        require(shibes != IERC721(_shibes), "shibes already _shibes") ; 
        shibes = IERC721(_shibes) ; 

        return true ; 
    }
}