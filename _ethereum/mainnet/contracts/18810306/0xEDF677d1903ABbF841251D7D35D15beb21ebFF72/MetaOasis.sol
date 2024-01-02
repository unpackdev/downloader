// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";


contract MetaOasis is AccessControl, Ownable {
    bytes32 public constant SETUP_ROLE = keccak256("SETUP_ROLE");

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;


    uint256 timeSaleWhiteStart;
    uint256 timeSaleWhiteEnd;
    uint256 timeSaleStart;
    uint256 timeSaleEnd;
    uint256 maxSalePrice;
    uint256 minSalePrice;
    

    uint256 salePrice;
    uint256 saleMax;
    uint256 saleCount = 0;


    mapping (address => uint256) private whitelist;
    bool isModeWhiteSale = true;


    event EventPurchased(address to, uint256 value);


    constructor(
        uint256 _timeSaleWhiteStart,
        uint256 _timeSaleWhiteEnd,
        uint256 _timeSaleStart,
        uint256 _timeSaleEnd,
        uint256 _maxSalePrice,
        uint256 _minSalePrice,
        uint256 _salePrice,
        uint256 _saleMax,
        address _owners
    ) public {
        timeSaleWhiteStart = _timeSaleWhiteStart;
        timeSaleWhiteEnd = _timeSaleWhiteEnd;
        timeSaleStart = _timeSaleStart;
        timeSaleEnd = _timeSaleEnd;

        maxSalePrice = _maxSalePrice;
        minSalePrice = _minSalePrice;
        salePrice = _salePrice;
        saleMax = _saleMax;


        _grantRole(DEFAULT_ADMIN_ROLE, _owners);
        _grantRole(SETUP_ROLE, _owners);
    }


    function buyTokens() external payable {
        if (isModeWhiteSale == true) {
            require(timeSaleWhiteStart <= block.timestamp && block.timestamp <= timeSaleWhiteEnd, 'Not on White Sale');
        }
        if (isModeWhiteSale == false) {
            require(timeSaleStart <= block.timestamp && block.timestamp <= timeSaleEnd, 'Not for sale yet');
        }
        
        
        require(isModeWhiteSale == false || (isModeWhiteSale == true && whitelist[msg.sender] > 0), 'You are not Whitelist !');

        require(minSalePrice <= msg.value && msg.value <= maxSalePrice, 'Invalid sales amount.');
        require(msg.sender != address(0), 'wrong address');


        saleCount = saleCount + uint256(SafeMath.div(msg.value, salePrice));
        require(saleCount <= saleMax, 'Sold out');


        if (isModeWhiteSale == true) {
            require(whitelist[msg.sender] > 0, 'No longer available to purchase');
            whitelist[msg.sender] = whitelist[msg.sender] - msg.value;
        }
        
        

        emit EventPurchased(msg.sender, msg.value);
    }


    // ***** white list *****
    function addWhitelist (address user) public onlyRole(SETUP_ROLE) {
        whitelist[user] = maxSalePrice;
    }
    function addWhitelists (address[] memory users) public onlyRole(SETUP_ROLE) {
        for (uint256 i = 0 ; i < users.length; i++) {
            whitelist[users[i]] = maxSalePrice;
        }
    }
    function containsWhitelist (address user) public view returns (uint256) {
        return whitelist[user];
    }
    function removeWhitelist (address user) public onlyRole(SETUP_ROLE) {
        whitelist[user] = 0;
    }
    function setWhitelistForce (address user, uint256 value) public onlyRole(SETUP_ROLE) {
        whitelist[user] = value;
    }
    function getWhiteListCount (address user) public view returns (uint256) {
        return whitelist[user];
    }
    function getIsModeWhiteList () public view returns (bool) {
        return isModeWhiteSale;
    }




    // ***** onlyRole(SETUP_ROLE) *****
    function getMaxSalePrice() public view returns (uint256) {
        return maxSalePrice;
    }
    function setMaxSalePrice (uint256 _maxSalePrice) public onlyRole(SETUP_ROLE) {
        maxSalePrice = _maxSalePrice;
    }
    function getMinSalePrice() public view returns (uint256) {
        return minSalePrice;
    }
    function setMinSalePrice (uint256 _minSalePrice) public onlyRole(SETUP_ROLE) {
        minSalePrice = _minSalePrice;
    }


    function getSaleCount() public view returns (uint256) {
        return saleCount;
    }
    function getSalePrice() public view returns (uint256) {
        return salePrice;
    }
    function setSalePrice (uint256 _salePrice) public onlyRole(SETUP_ROLE) {
        salePrice = _salePrice;
    }
    function getSaleMax() public view returns (uint256) {
        return saleMax;
    }
    function setSaleMax (uint256 _saleMax) public onlyRole(SETUP_ROLE) {
        saleMax = _saleMax;
    }


    function getTimeSaleWhiteStart () public view returns (uint256) {
        return timeSaleWhiteStart;
    }
    function setTimeSaleWhiteStart (uint256 _timeSaleWhiteStart) public onlyRole(SETUP_ROLE) {
        timeSaleWhiteStart = _timeSaleWhiteStart;
    }

    function getSaleEndTime () public view returns (uint256) {
        return timeSaleWhiteEnd;
    }
    function setSaleEndTime (uint256 _timeSaleWhiteEnd) public onlyRole(SETUP_ROLE) {
        timeSaleWhiteEnd = _timeSaleWhiteEnd;
    }

    function getTimeSaleStart () public view returns (uint256) {
        return timeSaleStart;
    }
    function setTimeSaleStart (uint256 _timeSaleStart) public onlyRole(SETUP_ROLE) {
        timeSaleStart = _timeSaleStart;
    }
    
    function getTimeSaleEnd () public view returns (uint256) {
        return timeSaleEnd;
    }
    function setTimeSaleEnd (uint256 _timeSaleEnd) public onlyRole(SETUP_ROLE) {
        timeSaleEnd = _timeSaleEnd;
    }


    function setIsModeWhiteSale (bool _isModeWhiteSale) public onlyRole(SETUP_ROLE) {
        isModeWhiteSale = _isModeWhiteSale;
    }

    function withdraw (address payable _account) public onlyRole(SETUP_ROLE) {
        require (
            address(_account) != address(0) &&
            address(_account) != address(this), 'wrong address');

        _account.transfer(address(this).balance);
    }
}