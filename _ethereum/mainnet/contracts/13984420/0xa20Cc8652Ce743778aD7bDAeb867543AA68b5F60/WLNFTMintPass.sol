// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./SafeMath.sol";

abstract contract NFT {
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
}

abstract contract SOSToken {
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
}

/**
 * @title WhitelistNFT MintPass
 * WhitelistNFT MintPass - a contract for WhitelistNFT MintPass
 */
contract WLNFTMintPass is ERC721Tradable {
    using SafeMath for uint256;
    uint256 public constant maxSupply = 10000;
    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xC87C8BF777701ccFfB1230051E33f0524E5975b5;
    address constant WALLET3 = 0xe5c07AcF973Ccda3a141efbb2e829049591F938e;
    address constant WALLET4 = 0xA7Ad336868fEB70C83F08f1c28c19e1120AB6351;
    bool public preSaleIsActive = true;
    bool public saleIsActive = false;
    uint256 public maxPerWallet = 1;
    uint256 public maxPerTransaction = 5;
    uint256 public basePrice = 100000000000000000;
    uint256 public baseSupply = 1000;
    uint256 public sosBalance = 100000000;
    string _baseTokenURI;
    address[] public contracts;
    SOSToken sos;

    constructor(
        address _proxyRegistryAddress,
        string memory _name,
        string memory _symbol,
        address _sosAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        sos = SOSToken(_sosAddress);
    }

    struct AddressWhitelist {
        bool exists;
    }
    mapping(address => AddressWhitelist) public addressWhitelist;

    struct ContractWhitelist {
        bool exists;
        NFT nft;
        uint256 usedSpots;
        uint256 availSpots;
    }
    mapping(address => ContractWhitelist) public contractWhitelist;

    struct Minter {
        uint256 hasMinted;
    }
    mapping(address => Minter) public minters;

    function addAddressToWhitelist(address _address) onlyOwner public returns(bool success) {
        require(!isWhitelistedByAddress(_address), "Already whitelisted");
        addressWhitelist[_address].exists = true;
        success = true;
    }

    function addAddressesToWhitelist(address[] memory _addresses) onlyOwner public returns(bool success) {
        for(uint i = 0; i < _addresses.length; i++) {
            addAddressToWhitelist(_addresses[i]);
        }
        success = true;
    }

    function isWhitelistedByAddress(address _address)
        public 
        view
        returns (bool) {
        return addressWhitelist[_address].exists;
    }

    function isWhitelistedBySOS(address _address)
        public
        view
        returns (bool)
    {
        return sos.balanceOf(_address).div(10**18) >= sosBalance;
    }

    function isWhitelistedByContract(address _address)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < contracts.length; i += 1) {
            if (
                contractWhitelist[contracts[i]].nft.balanceOf(_address) > 0 &&
                contractWhitelist[contracts[i]].usedSpots < contractWhitelist[contracts[i]].availSpots
            ) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function isWhitelistedContract(address _address)
        internal
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < contracts.length; i += 1) {
            if (_address == contracts[i] && contractWhitelist[_address].exists) return (true, i);
        }
        return (false, 0);
    }

    function addContractToWhitelist(address _address, uint256 _availSpots)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isWhitelisted, ) = isWhitelistedContract(_address);
        require(!_isWhitelisted,  "Contract already whitelisted.");
        contractWhitelist[_address].exists = true;
        contractWhitelist[_address].nft = NFT(_address);
        contractWhitelist[_address].availSpots = _availSpots;
        contracts.push(_address);
        return true;
    }

    function updateContractWhitelist(address _address, uint256 _availSpots)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isWhitelisted, ) = isWhitelistedContract(_address);
        require(_isWhitelisted,  "Contract is not whitelisted.");
        contractWhitelist[_address].availSpots = _availSpots;
        return true;
    }

    function removeContractFromWhitelist(address _address)
        public
        onlyOwner
        returns (bool)
    {
        (bool _isWhitelisted, uint256 i) = isWhitelistedContract(_address);
        require(_isWhitelisted, "Contract is not whitelisted.");
        contracts[i] = contracts[contracts.length - 1];
        contracts.pop();
        delete contractWhitelist[_address];
        return true;
    }

    function baseTokenURI() override virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setSOSBalance(uint256 _balance) public onlyOwner {
        sosBalance = _balance;
    }

    function setMaxPerWallet(uint256 _maxToMint) external onlyOwner {
        maxPerWallet = _maxToMint;
    }

    function setMaxPerTransaction(uint256 _maxToMint) external onlyOwner {
        maxPerTransaction = _maxToMint;
    }

    function setBasePrice(uint256 _price) public onlyOwner {
        basePrice = _price;
    }

    function setBaseSupply(uint256 _supply) public onlyOwner {
        baseSupply = _supply;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function reserve(address _address, uint256 _quantity) public onlyOwner {
        uint i;
        for (i = 0; i < _quantity; i++) {
            mintTo(_address);
        }
    }

    // for compatibility with WenMint's hosted minting form
    function preSalePrice() public view returns (uint256) {
        return getPrice();
    }

    // for compatibility with WenMint's hosted minting form
    function pubSalePrice() public view returns (uint256) {
        return getPrice();
    }

    function getPrice() public view returns (uint256) {
        uint256 currentSupply = totalSupply();
        require(currentSupply <= maxSupply, "Sold out.");
        if (currentSupply > baseSupply.mul(6)) {
            return basePrice.mul(4);
        } else if (currentSupply > baseSupply.mul(3)) {
            return basePrice.mul(3);
        } else if (currentSupply > baseSupply) {
            return basePrice.mul(2);
        } else {
            return basePrice;
        }
    }

    function mint(uint _quantity) public payable {

        require(saleIsActive, "Sale is not active.");
        require(totalSupply().add(_quantity) <= maxSupply, "Requested quantity would exceed total supply.");
        require(_quantity > 0, "Quantity cannot be 0.");
        require(getPrice().mul(_quantity) <= msg.value, "ETH sent is incorrect.");
        if(preSaleIsActive) {
            require(_quantity <= maxPerWallet, "Exceeds per wallet limit.");
            require(minters[msg.sender].hasMinted < maxPerWallet, "Exceeds per wallet limit.");
            bool _isWhitelistedByAddress = isWhitelistedByAddress(msg.sender);
            bool _isWhitelistedBySOS = isWhitelistedBySOS(msg.sender);
            (bool _isWhitelistedByContract, uint256 i) = isWhitelistedByContract(msg.sender);
            bool _isWhitelisted = _isWhitelistedByAddress || _isWhitelistedBySOS || _isWhitelistedByContract;
            require(_isWhitelisted, "You are not whitelisted.");
            if (_isWhitelistedByContract && minters[msg.sender].hasMinted == 0) {
                contractWhitelist[contracts[i]].usedSpots = contractWhitelist[contracts[i]].usedSpots.add(1);
            }
        } else {
            require(_quantity <= maxPerTransaction, "Exceeds per transaction limit.");
        }
        minters[msg.sender].hasMinted = minters[msg.sender].hasMinted.add(_quantity);
        for(uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 split1 = balance.mul(45).div(100);
        uint256 split2 = balance.mul(225).div(1000);
        payable(WALLET1).transfer(split1);
        payable(WALLET2).transfer(split2);
        payable(WALLET3).transfer(split2);
        payable(WALLET4).transfer(
            balance.sub(split1.add(split2.mul(2)))
        );
    }
}