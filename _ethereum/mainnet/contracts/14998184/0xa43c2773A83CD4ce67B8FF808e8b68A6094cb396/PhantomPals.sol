// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";

contract PhantomPals is ERC721, Ownable {
    using Strings for uint256;

    address private mainWallet = 0x2f5DA370ba0837f111a3981712738d865b5Faf9E;
    uint256 public constant NFT_STOCK = 1500;
    uint256 public constant NFTS_PER_TRANS = 5;
    uint256 public constant NFTS_PER_WALLET = 25;

    string private _tokenBaseURI;
    string public _mysteryURI;

    bool public revealed = false;
    bool public giftLive = true;
    bool public firstSaleLive = false;
    bool public secondSaleLive = false;

    mapping(address => uint256) public addressMinted;

    uint256 public totalSupply;

    constructor(string memory tokenBaseURI, string memory mysteryURI) ERC721("Phantom Pals", "PHANTOMPALS") {
        _tokenBaseURI = tokenBaseURI;
        _mysteryURI = mysteryURI;
    }

    function mintGift(uint256 tokenQuantity, address wallet)
        external
        onlyOwner
    {
        require(giftLive, "GIFTING CLOSED");
        require(tokenQuantity > 0, "INVALID TOKEN QUANTITY");
        require(totalSupply <= NFT_STOCK, "OUT OF STOCK");
        require(totalSupply + tokenQuantity <= NFT_STOCK, "EXCEEDS STOCK");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(wallet, totalSupply + i + 1);
        }

        totalSupply += tokenQuantity;
    }

    function mint(
        uint256 tokenQuantity
    ) external payable {
        require(totalSupply <= NFT_STOCK, "OUT OF STOCK");
        require(tokenQuantity > 0, "INVALID TOKEN QUANTITY");
        require(tokenQuantity <= NFTS_PER_TRANS, "EXCEEDS MINT AMT PER TRANSACTION");
        require(addressMinted[msg.sender] + tokenQuantity <= NFTS_PER_WALLET, "EXCEEDS YOUR 25 PALS MAX");
        if (firstSaleLive) require(totalSupply + tokenQuantity <= NFT_STOCK/2, "EXCEEDS FIRST SALE STOCK");
        else if (secondSaleLive) require(totalSupply + tokenQuantity <= NFT_STOCK, "EXCEEDS SECOND SALE STOCK");
        else require(firstSaleLive || secondSaleLive, "SALE NOT LIVE");
        
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply + i + 1);
        }

        addressMinted[msg.sender] += tokenQuantity;
        totalSupply += tokenQuantity;
    }

    function withdraw() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        payable(mainWallet).transfer((currentBalance * 1000) / 1000);
    }

    function toggleFirstSaleStatus() public onlyOwner {
        firstSaleLive = !firstSaleLive;
    }

    function toggleSecondSaleStatus() public onlyOwner {
        secondSaleLive = !secondSaleLive;
    }

    function toggleGiftStatus() public onlyOwner {
        giftLive = !giftLive;
    }

    function toggleMysteryURI() public onlyOwner {
        revealed = !revealed;
    }

    function setMysteryURI(string calldata URI) public onlyOwner {
        _mysteryURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
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