// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./Address.sol";
import "./BaseAccessControl.sol";
import "./DragonInfo.sol";
import "./EggToken.sol";

contract EggMarket is BaseAccessControl {
    
    using Address for address payable;
    
    address private _tokenAddress;
    bool private _publicSaleStarted = false;

    mapping(DragonInfo.Types => uint) private _currentPresaleCounts;
    mapping(DragonInfo.Types => uint) private _presaleRemainingCounts;
    mapping(DragonInfo.Types => uint) private _maxBuyCounts;
    mapping(DragonInfo.Types => uint) private _presaleMaxBuyCounts;
    mapping(DragonInfo.Types => uint) private _totalAllowedPresaleCounts;
    mapping(DragonInfo.Types => uint) private _presalePrices;
    mapping(DragonInfo.Types => uint) private _publicPrices;
    mapping(DragonInfo.Types => mapping(address => uint)) private _presales;

    event TokenPresold(address indexed buyer, address indexed to, uint count, DragonInfo.Types dragonType);
    event TokenBought(address indexed buyer, address indexed to, uint tokenId, DragonInfo.Types dragonType);
    event TokenClaimed(address indexed claimer, address indexed to, uint tokenId);
    event PresaleAllowed(address operator, uint totalAllowedPresaleCount, uint presalePrice, DragonInfo.Types dragonType);
    event PublicSaleStarted(address operator, uint legendaryPrice, uint epicPrice, uint randomPrice);
    event EthersWithdrawn(address operator, address indexed to, uint amount);

    constructor(address accessControl, address eggToken) 
    BaseAccessControl(accessControl) {
        _tokenAddress = eggToken;
        
        _presaleMaxBuyCounts[DragonInfo.Types.Unknown] = 5;
        _presaleMaxBuyCounts[DragonInfo.Types.Epic20] = 1;
        _presaleMaxBuyCounts[DragonInfo.Types.Legendary] = 1;

        _maxBuyCounts[DragonInfo.Types.Unknown] = 5;
        _maxBuyCounts[DragonInfo.Types.Epic20] = 1;
        _maxBuyCounts[DragonInfo.Types.Legendary] = 1;
    }

    function tokenAddress() public view returns (address) {
        return _tokenAddress;
    }

    function setTokenAddress(address newAddress) external onlyRole(CEO_ROLE) {
        address previousAddress = _tokenAddress;
        _tokenAddress = newAddress;
        emit AddressChanged("token", previousAddress, newAddress);
    }

    function presalePrice(DragonInfo.Types drgType) public view returns(uint) {
        return _presalePrices[drgType];
    }

    function setPresalePrice(DragonInfo.Types drgType, uint newValue) external onlyRole(CFO_ROLE) {
        uint previousValue = _presalePrices[drgType];
        _presalePrices[drgType] = newValue;
        emit ValueChanged(string(abi.encodePacked("presalePrices.", drgType)), previousValue, newValue);
    }

    function presaleMaxBuyCount(DragonInfo.Types drgType) public view returns(uint) {
        return _presaleMaxBuyCounts[drgType];
    }

    function setPresaleMaxBuyCount(DragonInfo.Types drgType, uint newValue) external onlyRole(CFO_ROLE) {
        uint previousValue = _presaleMaxBuyCounts[drgType];
        _presaleMaxBuyCounts[drgType] = newValue;
        emit ValueChanged(string(abi.encodePacked("presaleMaxBuyCounts.", drgType)), previousValue, newValue);
    }

    function totalAllowedPresaleCount(DragonInfo.Types drgType) public view returns(uint) {
        return _totalAllowedPresaleCounts[drgType];
    }

    function currentPresaleCount(DragonInfo.Types drgType) public view returns(uint) {
        return _currentPresaleCounts[drgType];
    }

    function presaleRemainingCount(DragonInfo.Types drgType) public view returns(uint) {
        return _presaleRemainingCounts[drgType];
    }

    function allowPresale(DragonInfo.Types drgType, uint totalAllowedPresaleCnt, uint psPrice) external onlyRole(CFO_ROLE) {
        require(!publicSaleStarted(), "EggMarket: unable to allow presale");
        uint totalEggSupply = EggToken(tokenAddress()).totalEggSupply(drgType);
        require(presaleRemainingCount(drgType) + totalAllowedPresaleCnt <= totalEggSupply, 
            "EggMarket: unable to allow presale with the given count");
        _totalAllowedPresaleCounts[drgType] = totalAllowedPresaleCnt;
        _presalePrices[drgType] = psPrice;
        _currentPresaleCounts[drgType] = 0;
        emit PresaleAllowed(_msgSender(), totalAllowedPresaleCnt, psPrice, drgType);
    }

    function publicPrice(DragonInfo.Types drgType) public view returns(uint) {
        return _publicPrices[drgType];
    }

    function setPublicPrice(DragonInfo.Types drgType, uint newValue) external onlyRole(CFO_ROLE) {
        uint previousValue = _publicPrices[drgType];
        _publicPrices[drgType] = newValue;
        emit ValueChanged(string(abi.encodePacked("publicPrices.", drgType)), previousValue, newValue);
    }

    function maxBuyCount(DragonInfo.Types drgType) public view returns(uint) {
        return _maxBuyCounts[drgType];
    }

    function setMaxBuyCount(DragonInfo.Types drgType, uint newValue) external onlyRole(CFO_ROLE) {
        uint previousValue = _maxBuyCounts[drgType];
        _maxBuyCounts[drgType] = newValue;
        emit ValueChanged(string(abi.encodePacked("maxBuyCount.", drgType)), previousValue, newValue);
    }

    function publicSaleStarted() public view returns(bool) {
        return _publicSaleStarted;
    }

    function togglePublicSaleStarted(
        uint legendaryPrice, 
        uint epicPrice, 
        uint randomPrice) external onlyRole(CFO_ROLE) {
        _publicSaleStarted = true;
        
        _publicPrices[DragonInfo.Types.Legendary] = legendaryPrice;
        _publicPrices[DragonInfo.Types.Epic20] = epicPrice;
        _publicPrices[DragonInfo.Types.Unknown] = randomPrice;

        emit PublicSaleStarted(_msgSender(), legendaryPrice, epicPrice, randomPrice);
    }

    function buy(DragonInfo.Types drgType, address to, uint count) external payable {
        require(!Address.isContract(to), "EggMarket: address cannot be contract");
        if (publicSaleStarted()) {
            _buy(drgType, to, count);
        }
        else {
            _presaleBuy(drgType, to, count);
        }
    }

    function claim(DragonInfo.Types drgType, address to, uint count) external {
        require(publicSaleStarted(), "EggMarket: unable to claim");
        require(!Address.isContract(to), "EggMarket: address cannot be contract");
        require(_presales[drgType][_msgSender()] >= count, "EggMarket: bad count");
        EggToken eggt = EggToken(tokenAddress());
        for (uint i = 0; i < count; i++) {
            uint tokenId = eggt.mint(to, drgType);
            emit TokenClaimed(_msgSender(), to, tokenId);
        }
        _presales[drgType][_msgSender()] -= count;
        _presaleRemainingCounts[drgType] -= count;
    }

    function withdrawEthers(uint amount, address payable to) external virtual onlyRole(CFO_ROLE) {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }

    function _buy(DragonInfo.Types drgType, address to, uint count) internal {
        require(count <= maxBuyCount(drgType), "EggMarket: bad count");
        EggToken et = EggToken(tokenAddress());
        uint totalEggSupply = et.totalEggSupply(drgType);
        uint currentEggCount = et.currentEggCount(drgType);
        require(presaleRemainingCount(drgType) + currentEggCount + count <= totalEggSupply, 
            "EggMarket: unable to buy such amount of eggs");
        require(msg.value >= count * publicPrice(drgType), 
            "EggMarket: incorrect amount sent to the contract");
        EggToken eggt = EggToken(tokenAddress());
        for (uint i = 0; i < count; i++) {
            uint tokenId = eggt.mint(to, drgType);
            emit TokenBought(_msgSender(), to, tokenId, drgType);
        }
    }

    function _presaleBuy(DragonInfo.Types drgType, address to, uint count) internal {
        require(currentPresaleCount(drgType) + count <= totalAllowedPresaleCount(drgType), "EggMarket: exceed total allowed presale count");
        require(_presales[drgType][to] + count <= presaleMaxBuyCount(drgType), "EggMarket: exceed max presale count per user");
        require(msg.value >= count * presalePrice(drgType), "EggMarket: incorrect amount sent to the contract");
        _presales[drgType][to] += count;
        _currentPresaleCounts[drgType] += count;
        _presaleRemainingCounts[drgType] += count;
        emit TokenPresold(_msgSender(), to, count, drgType);
    }
}
