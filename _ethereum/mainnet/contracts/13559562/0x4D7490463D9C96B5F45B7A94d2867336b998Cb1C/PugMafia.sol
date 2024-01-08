// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title PugMafia
 * PugMafia - a contract for PugMafia NFTs
 */
contract PugMafia is ERC721Tradable {
    using SafeMath for uint256;
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    uint256 public _presaleMaxMints = 500;
    uint256 public constant RESERVE_MINT = 20;
    uint256 public mintPricePresale = 0.05 ether;
    uint256 public mintPricePublic = 0.08 ether;
    uint256 public maxToMint = 10;
    uint256 public maxSupply = 2500;
    string _baseTokenURI;
    string _contractURI;

    address public constant DEV_WALLET_1 = 0x15aD2Aab4c724b9135900884Ed953e84008e70Ad; // TopDog payout
    address public constant DEV_WALLET_2 = 0xfc15d1c9E857eD43C59e2861f52666d47ECC0e62; // Br0ke payout

    constructor(address _proxyRegistryAddress) ERC721Tradable("Pug Mafia", "PUGMAFIA", _proxyRegistryAddress) {}

    function baseTokenURI() override virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        _contractURI = _uri;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > maxSupply, "You cannot reduce supply.");
        maxSupply = _maxSupply;
    }

    function setMintPrices(uint256 _pricePresale, uint256 _pricePublic) external onlyOwner {
        mintPricePresale = _pricePresale;
        mintPricePublic = _pricePublic;
    }

    function setMaxPresaleMints(uint256 presaleMaxMints) external onlyOwner {
        _presaleMaxMints = presaleMaxMints;
    }

    function setMaxToMint(uint256 _maxToMint) external onlyOwner {
        maxToMint = _maxToMint;
    }

    function setSaleState(bool presaleState, bool publicState) external onlyOwner {
        saleIsActive = publicState;
        preSaleIsActive = presaleState;
    }

    function reserve(address to) public onlyOwner {
        uint i;
        for (i = 0; i < RESERVE_MINT; i++) {
            mintTo(to);
        }
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Sold out.");
        if(preSaleIsActive) {
            require(mintPricePresale.mul(numberOfTokens) <= msg.value, "ETH sent is incorrect.");
            require(totalSupply().add(numberOfTokens) <= _presaleMaxMints + RESERVE_MINT, "Exceeds pre-sale limit.");
        } else {
            require(mintPricePublic.mul(numberOfTokens) <= msg.value, "ETH sent is incorrect.");
            require(numberOfTokens <= maxToMint, "Exceeds per transaction limit.");
        }
        uint256 halfFee = msg.value / 2;
        payable(DEV_WALLET_1).transfer(halfFee);
        payable(DEV_WALLET_2).transfer(msg.value - halfFee); // incase there is some issue with rounding, should be half
        for(uint i = 0; i < numberOfTokens; i++) {
            mintTo(msg.sender);
        }
    }
}