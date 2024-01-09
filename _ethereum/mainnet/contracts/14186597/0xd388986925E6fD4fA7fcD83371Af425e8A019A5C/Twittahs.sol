// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract MintPass {
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
}

contract Twittahs is ERC721A, Ownable {

    address constant WALLET = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    uint256 public constant maxSupply = 10000;
    uint256 public maxPerWallet = 10;
    uint256 public maxPerTransaction = 25;
    uint256 public basePrice = 0.05 * 10 ** 18;
    uint256 public pubSalePrice = 0.07 * 10 ** 18;
    uint256 public preSalePhase = 1;
    bool public preSaleIsActive = true;
    bool public saleIsActive = false;
    address proxyRegistryAddress;
    string _baseTokenURI;
    bytes32 private merkleRoot;
    MintPass mintpass;

    constructor(address _proxyRegistryAddress, bytes32 _root, address _address) ERC721A("Trendy Twittahs", "TWITTAHS", 100) {
        proxyRegistryAddress = _proxyRegistryAddress;
        merkleRoot = _root;
        mintpass = MintPass(_address);
    }

    struct Minter {
        uint256 hasMinted;

    }
    mapping(address => Minter) minters;

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setMintPass(address _address) public onlyOwner {
        mintpass = MintPass(_address);
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function isWhitelisted(address _address, bytes32[] memory _proof) virtual public view returns (bool) {
        if (preSalePhase == 1 && mintpass.balanceOf(_address) < 1) return false;
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        if (!verify(leaf, _proof)) return false;
        return true;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setPreSalePhase(uint8 _phase) public onlyOwner {
        require(_phase == 1 || _phase == 2, "Invalid presale phase.");
        preSalePhase = _phase;
    }

    function setPreSalePrice(uint256 _price) public onlyOwner {
        basePrice = _price;
    }

    function setPublicSalePrice(uint256 _price) public onlyOwner {
        pubSalePrice = _price;
    }

    function setMaxPerWallet(uint256 _maxToMint) public onlyOwner {
        maxPerWallet = _maxToMint;
    }

    function setMaxPerTransaction(uint256 _maxToMint) public onlyOwner {
        maxPerTransaction = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function reserve(address _address, uint256 _quantity) public onlyOwner {
        _safeMint(_address, _quantity);
    }

    function preSalePrice() public view returns (uint256) {
        if (preSaleIsActive && preSalePhase == 2) {
            return basePrice + 0.01 * 10 ** 18;
        } else {
            return basePrice;
        }
    }

    function verify(bytes32 leaf, bytes32[] memory proof) public view returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
          bytes32 proofElement = proof[i];
          if (computedHash <= proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
          } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
          }
        }
        return computedHash == merkleRoot;
    }

    function mint(uint _quantity, bytes32[] memory proof) public payable {
        uint256 currentSupply = totalSupply();
        require(saleIsActive, "Sale is not active.");
        require(msg.value > 0, "Must send ETH to mint.");
        require(currentSupply <= maxSupply, "Sold out.");
        require(currentSupply + _quantity <= maxSupply, "Requested quantity would exceed total supply.");
        if(preSaleIsActive) {
            require(preSalePrice() * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= maxPerWallet, "Exceeds wallet presale limit.");
            require(minters[msg.sender].hasMinted + _quantity <= maxPerWallet, "Exceeds per wallet presale limit.");
            require(isWhitelisted(msg.sender, proof), "You are not whitelisted.");
            minters[msg.sender].hasMinted = minters[msg.sender].hasMinted + _quantity;
            _safeMint(msg.sender, _quantity);
        } else {
            require(pubSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= maxPerTransaction, "Exceeds per transaction limit for public sale.");
            _safeMint(msg.sender, _quantity);
        }
    }

    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 balance = totalBalance * 20/100;
        payable(WALLET).transfer(balance);
        uint256 remainder = totalBalance - balance;
        payable(msg.sender).transfer(remainder);
    }
}

