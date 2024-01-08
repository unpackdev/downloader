// Hi. If you have any questions or comments in this smart contract please let me know at:
// Whatsapp +923014440289, Telegram @thinkmuneeb, discord: timon#1213, I'm Muneeb Zubair Khan
//
//
// Smart Contract Made by Muneeb Zubair Khan
// The UI is made by Abraham Peter, Whatsapp +923004702553, Telegram @Abrahampeterhash.
//
//
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract SmartRats is ERC721("SmartRats", "SMRT"), Ownable {
    string public baseURI;
    bool public isSaleActive;
    uint256 public circulatingSupply;
    uint256 public itemPrice = 0.03 ether;
    uint256 public constant totalSupply = 10_333;

    ////////////////////
    //  PUBLIC SALE   //
    ////////////////////

    // Purchase multiple NFTs at once
    function purchaseTokens(uint256 _toMint)
        external
        payable
        tokensAvailable(_toMint)
    {
        require(isSaleActive && circulatingSupply <= 10_000, "Sale is not active");
        require(_toMint > 0 && _toMint <= 10, "Mint min 1, max 10");
        require(msg.value >= _toMint * itemPrice, "Try to send more ETH");

        for (uint256 i = 0; i < _toMint; i++)
            _mint(msg.sender, ++circulatingSupply);
    }

    //////////////////////////
    // Only Owner Methods   //
    //////////////////////////

    function setSaleActive(bool _startSale) external onlyOwner {
        isSaleActive = _startSale;
    }

    // Owner can withdraw ETH from here
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Hide identity or show identity from here
    function setBaseURI(string memory _baseURI_) external onlyOwner {
        baseURI = _baseURI_;
    }

    // Send NFTs to a list of addresses
    function gift(address[] calldata _sendNftsTo)
        external
        onlyOwner
        tokensAvailable(_sendNftsTo.length)
    {
        for (uint256 i = 0; i < _sendNftsTo.length; i++)
            _mint(_sendNftsTo[i], ++circulatingSupply);
    }


    ////////////////////
    // Helper Methods //
    ////////////////////

    function tokensRemaining() public view returns (uint256) {
        return totalSupply - circulatingSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    modifier tokensAvailable(uint256 _toMint) {
        require(_toMint <= tokensRemaining(), "Try minting less tokens");
        _;
    }
}
