// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./BaseAccessControl.sol";
import "./AvatarToken.sol";

contract AvatarMarket is BaseAccessControl, ReentrancyGuard, Pausable {
    
    string public constant BAD_ADDRESS_ERROR = "AvatarMarket: bad address";
    string public constant BAD_COUNT_ERROR = "AvatarMarket: bad count";
    string public constant TOTAL_SUPPLY_LIMIT_ERROR = "AvatarMarket: total supply exceeded";
    string public constant BAD_AMOUNT_ERROR = "AvatarMarket: bad amount";
    string public constant ALLOW_PRESALE_ERROR = "AvatarMarket: unable to allow presale"; 
    string public constant PRESALE_COUNT_TOTAL_LIMIT_ERROR = "AvatarMarket: total allowed presale exceeded";
    string public constant PRESALE_COUNT_USER_LIMIT_ERROR = "AvatarMarket: presale count per user exceeded";
    string public constant CLAIM_ERROR = "AvatarMarket: unable to claim";

    using Address for address payable;
    
    address private _tokenAddress;
    bool private _publicSaleStarted = false;

    uint private _currentPresaleCount;
    uint private _presaleRemainingCount;
    uint private _maxBuyCount;
    uint private _presaleMaxBuyCount;
    uint private _totalAllowedPresaleCount;
    uint private _presalePrice;
    uint private _publicPrice;
    mapping(address => uint) private _presales;

    event AvatarPresold(address indexed buyer, address indexed to, uint count);
    event AvatarBought(address indexed buyer, address indexed to, uint tokenId);
    event AvatarClaimed(address indexed claimer, address indexed to, uint tokenId);
    event PresaleAllowed(address operator, uint totalAllowedPresaleCount, uint presalePrice);
    event PublicSaleStarted(address operator, uint publicPrice);
    event EthersWithdrawn(address operator, address indexed to, uint amount);

    constructor(address avatarToken, address accessControl) 
    BaseAccessControl(accessControl) {
        _tokenAddress = avatarToken;
        _presaleMaxBuyCount = 5;
        _maxBuyCount = 5;
    }

    function tokenAddress() public view returns (address) {
        return _tokenAddress;
    }

    function setTokenAddress(address newAddress) external onlyRole(COO_ROLE) {
        address previousAddress = _tokenAddress;
        _tokenAddress = newAddress;
        emit AddressChanged("token", previousAddress, newAddress);
    }

    function presalePrice() public view returns (uint) {
        return _presalePrice;
    }

    function setPresalePrice(uint newValue) external onlyRole(CFO_ROLE) {
        uint previousValue = _presalePrice;
        _presalePrice = newValue;
        emit ValueChanged("presalePrice", previousValue, newValue);
    }

    function presaleMaxBuyCount() public view returns (uint) {
        return _presaleMaxBuyCount;
    }

    function setPresaleMaxBuyCount(uint newValue) external onlyRole(CFO_ROLE) {
        uint previousValue = _presaleMaxBuyCount;
        _presaleMaxBuyCount = newValue;
        emit ValueChanged("presaleMaxBuyCount", previousValue, newValue);
    }

    function totalAllowedPresaleCount() public view returns (uint) {
        return _totalAllowedPresaleCount;
    }

    function currentPresaleCount() public view returns (uint) {
        return _currentPresaleCount;
    }

    function presaleRemainingCount() public view returns (uint) {
        return _presaleRemainingCount;
    }

    function allowPresale(uint presaleCount, uint price) external onlyRole(CFO_ROLE) {
        require(!publicSaleStarted(), ALLOW_PRESALE_ERROR);
        uint totalTokenSupply = AvatarToken(tokenAddress()).totalTokenSupply();
        require(presaleRemainingCount() + presaleCount <= totalTokenSupply, TOTAL_SUPPLY_LIMIT_ERROR);
        
        _totalAllowedPresaleCount = presaleCount;
        _presalePrice = price;
        _currentPresaleCount = 0;
        
        emit PresaleAllowed(_msgSender(), presaleCount, price);
    }

    function publicPrice() public view returns (uint) {
        return _publicPrice;
    }

    function setPublicPrice(uint newValue) external onlyRole(CFO_ROLE) {
        uint previousValue = _publicPrice;
        _publicPrice = newValue;
        
        emit ValueChanged("publicPrice", previousValue, newValue);
    }

    function maxBuyCount() public view returns(uint) {
        return _maxBuyCount;
    }

    function setMaxBuyCount(uint newValue) external onlyRole(CFO_ROLE) {
        uint previousValue = _maxBuyCount;
        _maxBuyCount = newValue;
        
        emit ValueChanged("maxBuyCount", previousValue, newValue);
    }

    function publicSaleStarted() public view returns(bool) {
        return _publicSaleStarted;
    }

    function togglePublicSaleStarted(uint price) external onlyRole(CFO_ROLE) {
        _publicSaleStarted = true;
        _publicPrice = price;

        emit PublicSaleStarted(_msgSender(), price);
    }

    function buy(address to, uint count) external payable nonReentrant whenNotPaused {
        require(!Address.isContract(to), BAD_ADDRESS_ERROR);
        if (publicSaleStarted()) {
            _buy(to, count);
        }
        else {
            _presaleBuy(to, count);
        }
    }

    function claim(address to, uint count) external nonReentrant whenNotPaused {
        require(publicSaleStarted(), CLAIM_ERROR);
        require(!Address.isContract(to), BAD_ADDRESS_ERROR);
        require(_presales[_msgSender()] >= count, BAD_COUNT_ERROR);
        
        AvatarToken at = AvatarToken(tokenAddress());
        for (uint i = 0; i < count; i++) {
            uint tokenId = at.mint(to);
            emit AvatarClaimed(_msgSender(), to, tokenId);
        }
        _presales[_msgSender()] -= count;
        _presaleRemainingCount -= count;
    }

    function _buy(address to, uint count) internal {
        require(count <= maxBuyCount(), BAD_COUNT_ERROR);
        AvatarToken at = AvatarToken(tokenAddress());
        uint totalTokenSupply = at.totalTokenSupply();
        uint currentTokenCount = at.currentTokenCount();
        require(presaleRemainingCount() + currentTokenCount + count <= totalTokenSupply, TOTAL_SUPPLY_LIMIT_ERROR);
        require(msg.value >= count * publicPrice(), BAD_AMOUNT_ERROR);
        
        for (uint i = 0; i < count; i++) {
            uint tokenId = at.mint(to);
            emit AvatarBought(_msgSender(), to, tokenId);
        }
    }

    function _presaleBuy(address to, uint count) internal {
        require(currentPresaleCount() + count <= totalAllowedPresaleCount(), PRESALE_COUNT_TOTAL_LIMIT_ERROR);
        require(_presales[to] + count <= presaleMaxBuyCount(), PRESALE_COUNT_USER_LIMIT_ERROR);
        require(msg.value >= count * presalePrice(), BAD_AMOUNT_ERROR);
        
        _presales[to] += count;
        _currentPresaleCount += count;
        _presaleRemainingCount += count;
        
        emit AvatarPresold(_msgSender(), to, count);
    }

    function pause() external onlyRole(COO_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(COO_ROLE) {
        _unpause();
    }

    function withdrawEthers(uint amount, address payable to) external onlyRole(CFO_ROLE) {
        require(!to.isContract(), BAD_ADDRESS_ERROR);

        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }
}