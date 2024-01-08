//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";

contract First10KShredder is ERC721, ERC721Holder {

    address Alfred = 0x85575dc8cbB7ea50D9Aa6ad899309529553bF105;
    address Jerry = 0x0F19423f9b0dcffe4495563CF2E9C1cB576663f0;
    address SuperRare = 0xb932a70A57673d89f4acfFBE830E8ed7f75Fb9e0;

    // https://gitcoin.co/grants/12/gitcoin-grants-official-matching-pool-fund
    address PublicGoodsAddress = 0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6;

    // "The First 10,000" is SuperRare token id 23500
    uint256 tokenId = 23500;

    // address(5000): the shred address
    address shredAddress = address(5000);
    string shreddedTokenMetadata = "https://gateway.pinata.cloud/ipfs/QmcGuCN27i5ryu8g6SQ3vM465DYs7Keu5S5HvR4yDsCCNK";

    uint256 minPublicGoodsContribution = 440 ether;

    uint256 starttimeForPublicGoods;
    uint256 starttimeForTheLulz;
    
    constructor() ERC721('"The First 10,000" Shredder', "10KSHRED") {
        starttimeForPublicGoods = block.timestamp + 2 weeks;
        starttimeForTheLulz = block.timestamp + 4 weeks; 
    }

    receive() external payable {}
    
    function saveit_CryptoArtIsLegitimate() public {
        require(msg.sender == Jerry);
        _saveit();
    }

    function _saveit() private {
        IERC721(SuperRare).transferFrom(address(this), Alfred, tokenId);
        _claimGasBounty();
    }

    function shredit_WasALowEffortNFTAnyways() public {
        require(msg.sender == Jerry);
        _shredAndMintTo(Alfred);
    }

    function shredit_ForPublicGoods() public payable {
        require(block.timestamp > starttimeForPublicGoods);
        require(msg.value > minPublicGoodsContribution);

        (bool sent, bytes memory data) = PublicGoodsAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _shredAndMintTo(msg.sender);
    }

    function shredit_ForTheLulz() public {
        require(block.timestamp > starttimeForTheLulz);
        _shredAndMintTo(Alfred);
    }

    function _shredAndMintTo(address recipient) 
        private returns (uint256) {

        // shred
        IERC721(SuperRare).transferFrom(address(this), shredAddress, tokenId);

        // mint
        _mint(recipient, 1);
        _setTokenURI(1, shreddedTokenMetadata);

        _claimGasBounty();
        return 1;
    }
    
    function _claimGasBounty() private {
        (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}                  