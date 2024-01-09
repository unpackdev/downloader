// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FLYBYAccessControls.sol";
import "./BoringMath.sol";
import "./SafeTransfer.sol";
import "./IFlybyMarket.sol";
import "./IERC20.sol";
import "./ISpaceBoxFactory.sol";

contract FLYBYMarket is SafeTransfer {

    using BoringMath for uint256;
    using BoringMath128 for uint256;
    using BoringMath64 for uint256;

    FLYBYAccessControls public accessControls;
    bytes32 public constant MARKET_MINTER_ROLE = keccak256("MARKET_MINTER_ROLE");

    bool private initialised;
    struct Auction {
        bool exists;
        uint64 templateId;
        uint128 index;
    }

    address[] public auctions;

    uint256 public auctionTemplateId;

    ISpaceBoxFactory public spaceBox;
    
    mapping(uint256 => address) private auctionTemplates;
    mapping(address => uint256) private auctionTemplateToId;
    mapping(uint256 => uint256) public currentTemplateId;
    mapping(address => Auction) public auctionInfo;

    struct MarketFees {
        uint128 minimumFee;
        uint32 integratorFeePct;
    }

    MarketFees public marketFees;
    bool public locked;
    address payable public flybyDiv;
    event FlybyInitMarket(address sender);
    event AuctionTemplateAdded(address newAuction, uint256 templateId);
    event AuctionTemplateRemoved(address auction, uint256 templateId);
    event MarketCreated(address indexed owner, address indexed addr, address marketTemplate);
    
    function initFLYBYMarket(address _accessControls, address _spaceBox, address[] memory _templates) external {
        require(!initialised);
        require(_accessControls != address(0), "initFLYBYMarket: accessControls cannot be set to zero");
        require(_spaceBox != address(0), "initFLYBYMarket: spaceBox cannot be set to zero");

        accessControls = FLYBYAccessControls(_accessControls);
        spaceBox = ISpaceBoxFactory(_spaceBox);

        auctionTemplateId = 0;
        for(uint i = 0; i < _templates.length; i++) {
            _addAuctionTemplate(_templates[i]);
        }
        locked = true;
        initialised = true;
        emit FlybyInitMarket(msg.sender);
    }

    function setMinimumFee(uint256 _amount) external {
        require(  
            accessControls.hasAdminRole(msg.sender),
            "FLYBYMarket: Sender must be operator"
        );
        marketFees.minimumFee = BoringMath.to128(_amount);
    }

    function setLocked(bool _locked) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "FLYBYMarket: Sender must be admin"
        );
        locked = _locked;
    }

    function setIntegratorFeePct(uint256 _amount) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "FLYBYMarket: Sender must be operator"
        );
        require(_amount <= 1000, "FLYBYMarket: Percentage is out of 1000");
        marketFees.integratorFeePct = BoringMath.to32(_amount);
    }

    function setDividends(address payable _divaddr) external {
        require(accessControls.hasAdminRole(msg.sender), "FLYBYMarket.setDev: Sender must be operator");
        require(_divaddr != address(0));
        flybyDiv = _divaddr;
    }

    function setCurrentTemplateId(uint256 _templateType, uint256 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender),
            "FLYBYMarket: Sender must be admin"
        );
        require(auctionTemplates[_templateId] != address(0), "FLYBYMarket: incorrect _templateId");
        require(IFlybyMarket(auctionTemplates[_templateId]).marketTemplate() == _templateType, "FLYBYMarket: incorrect _templateType");
        currentTemplateId[_templateType] = _templateId;
    }

    function hasMarketMinterRole(address _address) public view returns (bool) {
        return accessControls.hasRole(MARKET_MINTER_ROLE, _address);
    }

    function deployMarket(
        uint256 _templateId,
        address payable _integratorFeeAccount
    )
        public payable returns (address newMarket)
    {
        if (locked) {
            require(accessControls.hasAdminRole(msg.sender) 
                    || accessControls.hasMinterRole(msg.sender)
                    || hasMarketMinterRole(msg.sender),
                "FLYBYMarket: Sender must be minter if locked"
            );
        }

        MarketFees memory _marketFees = marketFees;
        address auctionTemplate = auctionTemplates[_templateId];
        require(msg.value >= uint256(_marketFees.minimumFee), "FLYBYMarket: Failed to transfer minimumFee");
        require(auctionTemplate != address(0), "FLYBYMarket: Auction template doesn't exist");
        uint256 integratorFee = 0;
        uint256 flybyFee = msg.value;
        if (_integratorFeeAccount != address(0) && _integratorFeeAccount != flybyDiv) {
            integratorFee = flybyFee * uint256(_marketFees.integratorFeePct) / 1000;
            flybyFee = flybyFee - integratorFee;
        }

        newMarket = spaceBox.deploy(auctionTemplate, "", false);
        auctionInfo[newMarket] = Auction(true, BoringMath.to64(_templateId), BoringMath.to128(auctions.length));
        auctions.push(newMarket);
        emit MarketCreated(msg.sender, newMarket, auctionTemplate);
        if (flybyFee > 0) {
            flybyDiv.transfer(flybyFee);
        }
        if (integratorFee > 0) {
            _integratorFeeAccount.transfer(integratorFee);
        }
    }

    function createMarket(
        uint256 _templateId,
        address _token,
        uint256 _tokenSupply,
        bytes calldata _data
    )
        external payable returns (address newMarket)
    {
        newMarket = deployMarket(_templateId, payable(msg.sender));
        if (_tokenSupply > 0) {
            _safeTransferFrom(_token, msg.sender, _tokenSupply);
            require(IERC20(_token).approve(newMarket, _tokenSupply), "1");
        }
        IFlybyMarket(newMarket).initMarket(_data);

        if (_tokenSupply > 0) {
            uint256 remainingBalance = IERC20(_token).balanceOf(address(this));
            if (remainingBalance > 0) {
                _safeTransfer(_token, msg.sender, remainingBalance);
            }
        }
        return newMarket;
    }

    function addAuctionTemplate(address _template) external {
        require(
            accessControls.hasAdminRole(msg.sender) ||
            accessControls.hasOperatorRole(msg.sender),
            "FLYBYMarket: Sender must be operator"
        );
        _addAuctionTemplate(_template);    
    }

    function removeAuctionTemplate(uint256 _templateId) external {
        require(
            accessControls.hasAdminRole(msg.sender) ||
            accessControls.hasOperatorRole(msg.sender),
            "FLYBYMarket: Sender must be operator"
        );
        address template = auctionTemplates[_templateId];
        uint256 templateType = IFlybyMarket(template).marketTemplate();
        if (currentTemplateId[templateType] == _templateId) {
            delete currentTemplateId[templateType];
        }   
        auctionTemplates[_templateId] = address(0);
        delete auctionTemplateToId[template];
        emit AuctionTemplateRemoved(template, _templateId);
    }

    function _addAuctionTemplate(address _template) internal {
        require(_template != address(0), "FLYBYMarket: Incorrect template");
        require(auctionTemplateToId[_template] == 0, "FLYBYMarket: Template already added");
        uint256 templateType = IFlybyMarket(_template).marketTemplate();
        require(templateType > 0, "FLYBYMarket: Incorrect template code ");
        auctionTemplateId++;

        auctionTemplates[auctionTemplateId] = _template;
        auctionTemplateToId[_template] = auctionTemplateId;
        currentTemplateId[templateType] = auctionTemplateId;
        emit AuctionTemplateAdded(_template, auctionTemplateId);
    }

    function getAuctionTemplate(uint256 _templateId) external view returns (address) {
        return auctionTemplates[_templateId];
    }
    function getTemplateId(address _auctionTemplate) external view returns (uint256) {
        return auctionTemplateToId[_auctionTemplate];
    }
    function numberOfAuctions() external view returns (uint) {
            return auctions.length;
        }
    function minimumFee() external view returns(uint128) {
        return marketFees.minimumFee;
    }

    function getMarkets() external view returns(address[] memory) {
        return auctions;
    }

    function getMarketTemplateId(address _auction) external view returns(uint64) {
        return auctionInfo[_auction].templateId;
    }
}