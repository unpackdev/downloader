// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

/*
  ______           _ _ _____                           
 /_  __/___  _____(_|_) ___/_________ _____  ___  _____
  / / / __ \/ ___/ / /\__ \/ ___/ __ `/ __ \/ _ \/ ___/
 / / / /_/ / /  / / /___/ / /__/ /_/ / /_/ /  __(__  ) 
/_/  \____/_/  /_/_//____/\___/\__,_/ .___/\___/____/  
                                   /_/                 
I see you nerd! ⌐⊙_⊙
*/

contract ToriiScapes is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public maxTokenSupply;

    uint256 public constant MAX_MINTS_PER_TXN = 15;

    uint256 public mintPrice = 0.06 ether;

    uint256 public maxPresaleMintsPerWallet = 2;

    bool public preSaleIsActive = false;

    bool public saleIsActive = false;

    string public baseURI;

    string public provenance;

    mapping (address => uint256) private _presaleMints;

    address[5] private _shareholders;

    uint[5] private _shares;

    event PaymentReleased(address to, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 maxToriiScapesSupply) ERC721(name, symbol) {
        maxTokenSupply = maxToriiScapesSupply;

        _shareholders[0] = 0x183F1AfB52D1e91908C6D38226Ecc56E0c7b67f0; // Julius
        _shareholders[1] = 0xDc8Eb8d2D1babD956136b57B0B9F49b433c019e3; // Treasure-Seeker
        _shareholders[2] = 0x8c223D865Bc7Ff45757936325A992ec15d803FFD; // Hunter
        _shareholders[3] = 0x6124D1F882CDb9fE9E9B6F5dA7e6f2DBA3d4bC49; // Bob
        _shareholders[4] = 0x31Ed4b569Ab5F004A30761D166f608b6D24C34F5; // Christian

        _shares[0] = 3000;
        _shares[1] = 2500;
        _shares[2] = 2000;
        _shares[3] = 2000;
        _shares[4] = 500;
    }

    function setMaxTokenSupply(uint256 maxToriiScapesSupply) public onlyOwner {
        maxTokenSupply = maxToriiScapesSupply;
    }

    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxPresaleMintsPerWallet(uint256 newLimit) public onlyOwner {
        maxPresaleMintsPerWallet = newLimit;
    }

    function withdrawForGiveaway(uint256 amount, address payable to) public onlyOwner {
        Address.sendValue(to, amount);
        emit PaymentReleased(to, amount);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        uint256 totalShares = 10000;
        for (uint256 i = 0; i < 5; i++) {
            uint256 payment = amount * _shares[i] / totalShares;

            Address.sendValue(payable(_shareholders[i]), payment);
            emit PaymentReleased(_shareholders[i], payment);
        }
    }

    /*
    * Mint reserved NFTs for giveaways, devs, etc.
    */
    function reserveMint(uint256 reservedAmount, address mintAddress) public onlyOwner {        
        for (uint256 i = 1; i <= reservedAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(mintAddress, _tokenIdCounter.current());
        }
    }

    /*
    * Pause sale if active, make active if paused.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * Pause pre-sale if active, make active if paused.
    */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /*
    * Mint ToriiScapes NFTs, woot!
    */
    function publicMint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not live yet");
        require(numberOfTokens <= MAX_MINTS_PER_TXN, "You can mint a max of 15 NFTs at a time");
        require(_tokenIdCounter.current() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available NFTs");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    /*
    * Mint ToriiScapes NFTs during pre-sale
    */
    function presaleMint(uint256 numberOfTokens) public payable {
        require(preSaleIsActive, "Pre-sale is not live yet");
        require(_presaleMints[msg.sender] + numberOfTokens <= maxPresaleMintsPerWallet, "Max mints per wallet limit exceeded");
        require(_tokenIdCounter.current() + numberOfTokens <= maxTokenSupply, "Purchase would exceed max available NFTs");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _presaleMints[msg.sender] += numberOfTokens;

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    /*     
    * Set provenance once it's calculated.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        provenance = provenanceHash;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
