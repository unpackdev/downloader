// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";

contract DobieStaker is ERC721Holder, Ownable {
    IERC721 public nft;
    mapping(uint256 => address) public tokenOwnerOf;
    mapping(uint256 => uint256) public tokenStakedAt;
    mapping(address => uint256[]) public tokensStakedbyAddress;

    constructor(address _nft) {
        nft = IERC721(_nft);
    }

    function stake(uint256 tokenId) external {
        nft.safeTransferFrom(msg.sender, address(this), tokenId);
        tokenOwnerOf[tokenId] = msg.sender;
        tokenStakedAt[tokenId] = block.timestamp;
        tokensStakedbyAddress[msg.sender].push(tokenId);
    }


    function calculateUserLevel(address _userAddress) private view returns (uint256) { 
        if (tokensStakedbyAddress[_userAddress].length == 0) {
            return 0;
        }

        uint256 timeElapsedInterval1 = block.timestamp - tokenStakedAt[tokensStakedbyAddress[_userAddress][0]];  
        
        if (tokensStakedbyAddress[_userAddress].length < 5) { //5
            return uint256(timeElapsedInterval1/604800) + 1;
        } else if (tokensStakedbyAddress[_userAddress].length < 10) {
            uint256 timeElapsedInterval2 = block.timestamp - tokenStakedAt[tokensStakedbyAddress[_userAddress][4]];
            return uint256((timeElapsedInterval1 + timeElapsedInterval2)/604800) + 1;
        } else if (tokensStakedbyAddress[_userAddress].length < 20) {
            uint256 timeElapsedInterval2 = block.timestamp - tokenStakedAt[tokensStakedbyAddress[_userAddress][4]]; 
            uint256 timeElapsedInterval3 = block.timestamp - tokenStakedAt[tokensStakedbyAddress[_userAddress][9]];
            return uint256((timeElapsedInterval1 + timeElapsedInterval2 + timeElapsedInterval3)/604800) + 1;
        } else if (tokensStakedbyAddress[_userAddress].length >= 20) {
            uint256 timeElapsedInterval2 = block.timestamp - tokenStakedAt[tokensStakedbyAddress[_userAddress][4]]; 
            uint256 timeElapsedInterval3 = block.timestamp - tokenStakedAt[tokensStakedbyAddress[_userAddress][9]]; 
            uint256 timeElapsedInterval4 = block.timestamp - tokenStakedAt[tokensStakedbyAddress[_userAddress][19]];
            return uint256((timeElapsedInterval1 + timeElapsedInterval2 + timeElapsedInterval3 + timeElapsedInterval4)/604800) + 1;
        }
    }

    function displayLevel() public view returns (uint256) {
        // user's address corresponds to 
        return calculateUserLevel(msg.sender);
    } 

    function adminDisplayLevel(address _userAddress) public onlyOwner view returns (uint256) {
        return calculateUserLevel(_userAddress);
    }
    
    function unstakeAll() external {
        require(tokensStakedbyAddress[msg.sender].length > 0, "You can't unstake");
        for(uint256 i = 0; i < tokensStakedbyAddress[msg.sender].length; i++) {
            nft.transferFrom(address(this), msg.sender, tokensStakedbyAddress[msg.sender][i]);
            delete tokenOwnerOf[tokensStakedbyAddress[msg.sender][i]];
            delete tokenStakedAt[tokensStakedbyAddress[msg.sender][i]];
        }
        delete tokensStakedbyAddress[msg.sender];
    }
}