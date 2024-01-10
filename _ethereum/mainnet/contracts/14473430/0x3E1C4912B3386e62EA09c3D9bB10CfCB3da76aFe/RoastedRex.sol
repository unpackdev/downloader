// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

import "ERC721A.sol";
import "Ownable.sol";
import "Counters.sol";

contract RoastedRex is ERC721A, Ownable {
    uint256 public maxSupply;
    bool public saleIsActive = false;
    string baseUri;
    uint256 public mintPrice;
    uint256 public maxMints;
    uint256 private manualMintPrice;

    using Counters for Counters.Counter;
    Counters.Counter _tokenIds;

    event nftMinted(
        uint256 indexed tokenId,
        uint256 mintPrice,
        uint256 paidPrice
    );

    constructor(uint256 supply) public ERC721A("RoastedRex", "RREX") {
        maxSupply = supply;
        mintPrice = 0;
        maxMints = 3;
    }

    
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseUri = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    // for marketing etc.
    function giftRex(address to, uint256 numberOfMints) external onlyOwner {
        _internalMint(to, numberOfMints);


    }

    function setMintPrice(uint256 price) external onlyOwner {
        manualMintPrice = price;
        mintPrice = price;
    }

    function mintRex(uint256 numberOfMints) public payable {
        require(saleIsActive, "Sale must be active to mint Rex!");
        require(numberOfMints <= maxMints, "Max mints exceeded!");
        require(
            (_tokenIds.current() + numberOfMints) <= maxSupply,
            "Purchase would exceed max supply of Rex tokens!"
        );
        require(
            (mintPrice * numberOfMints) <= msg.value,
            "Ether value sent is not correct!"
        );

        _internalMint(msg.sender, numberOfMints);

        // set new mint price
        mintPrice = manualMintPrice > 0 ? manualMintPrice : getMintPrice();
        if (mintPrice == 0) {
            maxMints = 3;
        } else {
            maxMints = 10;
        }
    }

    function _internalMint(address to, uint256 nrOfMints) private {
        _safeMint(to, nrOfMints);

        for (uint256 i = 0; i < nrOfMints; i++) {
            _tokenIds.increment();
            emit nftMinted(_tokenIds.current(), mintPrice, msg.value); 
        }
        
    }

    function getMintPrice() internal view returns (uint256) {
        // first 3% of NFTS are free (supply of 10.000 -> 300)
        if ((_tokenIds.current() * 100) < maxSupply * 3) {
            return 0;
        }

        // first 10% of NFTS are 0.01
        if ((_tokenIds.current() * 100) < maxSupply * 10) {
            return 0.01 * (10**18);
        }

        // 10%-30% cost 0.02 ETHs
        if ((_tokenIds.current() * 100) < maxSupply * 30) {
            return 0.02 * (10**18);
        }

        // 30-70% cost 0.04 ETHs
        if ((_tokenIds.current() * 100) < maxSupply * 70) {
            return 0.04 * (10**18);
        }

        // 70%-100% cost 0.05 ETHs
        return 0.05 * (10**18);
    }
}