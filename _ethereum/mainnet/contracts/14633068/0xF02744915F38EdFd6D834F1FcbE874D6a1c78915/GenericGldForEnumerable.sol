// SPDX-License-Identifier: UNLICENSED
/// @title GenericGldForEnumerable
/// @notice Generic Gld For Enumerable
/// @author CyberPnk <cyberpnk@glder.cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     


pragma solidity ^0.8.13;

import "./ReentrancyGuard.sol";
import "./IERC721Enumerable.sol";
import "./GenericGld.sol";

contract GenericGldForEnumerable is ReentrancyGuard, GenericGld {
    constructor (address _nftContract, address glderOwner, address contractMinter, string memory name, string memory symbol, uint _gldPerNft) GenericGld(_nftContract, glderOwner, contractMinter, name, symbol, _gldPerNft) {
    }

    function claimAll() external nonReentrant {
        IERC721Enumerable nfts = IERC721Enumerable(nftContract);
        uint balance = nfts.balanceOf(msg.sender);
        require(balance > 0, "Not enough");
        uint total = 0;
        for (uint i=0;i<balance;i+=1) {
            uint tokenId = nfts.tokenOfOwnerByIndex(msg.sender, i);            
            if (!claimedTokens[tokenId]) {
                total += gldPerNft;
                claimedTokens[tokenId] = true;
            }
        }
        require(total > 0, "Already claimed");

        _mint(msg.sender, total);
    }
}
