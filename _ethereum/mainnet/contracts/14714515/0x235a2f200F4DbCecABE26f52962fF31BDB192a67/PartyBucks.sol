// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";

contract PartyBucks is ERC721, Ownable {
    using Strings for uint256;

    address private mainWallet = 0x592C46bdD61D6BBcE35df147f4bD48B2A2b940f8;
    uint256 public constant NFT_STOCK = 20;
    uint256 public NFT_PRICE = 0.3 ether;

    string private _tokenBaseURI;
    string public _mysteryURI;

    bool public revealed = false;
    bool public giftLive = false;
    bool public saleLive = false;

    uint256 public totalSupply;

    constructor(string memory mysteryURI) ERC721("Party Bucks", "PARTYBUCKS") {
        _mysteryURI = mysteryURI;
    }

    function mintGift(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(giftLive, "GIFTING CLOSED");
        require(tokenQuantity > 0, "INVALID TOKEN QUANTITY");
        require(totalSupply < NFT_STOCK, "OUT OF STOCK");
        require(totalSupply + tokenQuantity <= NFT_STOCK, "EXCEEDS STOCK");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function mint(
    ) external payable {
        require(totalSupply < NFT_STOCK, "OUT OF STOCK");
        require(NFT_PRICE <= msg.value, "INSUFFICIENT ETH");
        require(balanceOf(msg.sender) == 0, "ONLY ONE PARTY BUCK PER ADDRESS");
        require(saleLive, "SALE IS NOT LIVE");
        
        _safeMint(msg.sender, totalSupply + 1);

        totalSupply += 1;
    }

    function withdraw() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        payable(mainWallet).transfer((currentBalance * 1000) / 1000);
    }

    function toggleSaleStatus() public onlyOwner {
        saleLive = !saleLive;
    }

    function toggleGiftStatus() public onlyOwner {
        giftLive = !giftLive;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function setMysteryURI(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setNFTPrice(uint256 newPrice) external onlyOwner {
        NFT_PRICE = newPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");

        if (revealed == false) {
            return _mysteryURI;
        }

        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }
}