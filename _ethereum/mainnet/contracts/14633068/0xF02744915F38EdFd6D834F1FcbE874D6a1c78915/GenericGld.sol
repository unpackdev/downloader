// SPDX-License-Identifier: UNLICENSED
/// @title GenericGld
/// @notice Generic Gld
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

import "./IERC721.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";

contract GenericGld is ERC20, ReentrancyGuard {
    address public nftContract;
    uint public gldPerNft;
    mapping (uint => bool) public claimedTokens;

    constructor (address _nftContract, address glderOwner, address contractMinter, string memory name, string memory symbol, uint _gldPerNft) ERC20(name, symbol) {
        nftContract = _nftContract;
        gldPerNft = _gldPerNft * 1 ether;
        uint gldCreationReward = 10 * gldPerNft;
        _mint(glderOwner, gldCreationReward);
        _mint(contractMinter, gldCreationReward);
    }

    function claimForTokenId(uint tokenId) external nonReentrant {
        IERC721 nfts = IERC721(nftContract);
        require(nfts.ownerOf(tokenId) == msg.sender && !claimedTokens[tokenId], "Not valid");
        claimedTokens[tokenId] = true;
        _mint(msg.sender, gldPerNft);
    }

    function claimForTokenIds(uint[] memory tokenIds) external nonReentrant {
        IERC721 nfts = IERC721(nftContract);
        for (uint i = 0; i < tokenIds.length; i++) {
            require(nfts.ownerOf(tokenIds[i]) == msg.sender && !claimedTokens[tokenIds[i]], "Not valid");
            claimedTokens[tokenIds[i]] = true;
        }
        _mint(msg.sender, gldPerNft * tokenIds.length);
    }
}
