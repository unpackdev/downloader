// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";

interface INFT {
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract MyToken is ERC20, ERC721Holder, Ownable {
    address public nft;
    mapping(uint256 => address) public tokenOwnerOf;
    mapping(uint256 => uint256) public tokenStakedAt;
    uint256 public EMISSION_RATE = (1 * 10 ** decimals()) / 1 days;

    // Constructor
    constructor() ERC20("COSMIC Token", "COSMIC"){
        _mint(msg.sender, 100000 * 10 ** decimals());
    }

    // Fuction to Set NFT Contract
    function updateNftContract(address _nft) public onlyOwner {
        nft = _nft;
    }

    // Stake Function
    function stake(uint256 tokenId) external {
        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);
        tokenOwnerOf[tokenId] = msg.sender;
        tokenStakedAt[tokenId] = block.timestamp;
    }

    // Calculate Staked Tokens for a Specific NFT
    function calculateTokens(uint256 tokenId) public view returns (uint256) {
        require(tokenStakedAt[tokenId] > 0, "Token Not Staked");
        uint256 timeElapsed = block.timestamp - tokenStakedAt[tokenId];
        return timeElapsed * EMISSION_RATE;
    }

    // Unstake Function
    function unstake(uint256 tokenId) external {
        require(tokenOwnerOf[tokenId] == msg.sender, "You can't unstake");
        _mint(msg.sender, calculateTokens(tokenId)); // Minting the tokens for staking
        IERC721(nft).transferFrom(address(this), msg.sender, tokenId);
        delete tokenOwnerOf[tokenId];
        delete tokenStakedAt[tokenId];
    }

    // Show Staked NFTs
    function getTokensOwnedByUser(address user) public view returns(uint[] memory){
        uint256[] memory tokenStaked = INFT(nft).walletOfOwner(address(this));
        uint256[] memory tokenOwnedByUser = new uint256[](tokenStaked.length);
        uint256 currentIndex = 0;

        for (uint i; i < tokenStaked.length;){
            if(user == tokenOwnerOf[tokenStaked[i]]){
            tokenOwnedByUser[currentIndex] = tokenStaked[i];
            currentIndex++;
        }

        unchecked {++i;}
        }

        return tokenOwnedByUser;
    }
}