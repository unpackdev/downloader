// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./EGovernanceBase.sol";
import "./EKotketNFTBase.sol";
import "./EKotketNFTInterface.sol";
import "./EKotketTokenInterface.sol";
import "./EKotketNFTFactoryInterface.sol";
import "./SafeMath.sol";

contract EKotketNFTPlatformRenting is EGovernanceBase, EKotketNFTBase{
    using SafeMath for uint256;

    struct DepositItemInfo {
        address owner;    
        uint256 startAt;
        uint256 endAt;
        uint256 lastCheckoutAt;
    }

    mapping (KOTKET_GENES => uint256) public rentingcommissionMap;

    mapping (uint => DepositItemInfo) public depositItemInfoMap;

    uint256 public dayInPeriod = 30;

    event RentingCommissionChanged(uint8 indexed gene, uint256 commission, address setter);
    event DayInPeriodChanged(uint256 dayInPeriod, address setter);

    event DepositItem(uint256 indexed id, address indexed owner, uint256 startAt, uint256 endAt);
    event WithdrawalItem(uint256 indexed id, address indexed owner);
    event WithdrawalBenefit(uint256 indexed id, address indexed owner, uint256 lastCheckoutAt);

    constructor(address _governanceAdress) EGovernanceBase(_governanceAdress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        rentingcommissionMap[KOTKET_GENES.RED] = 30;
        rentingcommissionMap[KOTKET_GENES.BLUE] = 50;
        rentingcommissionMap[KOTKET_GENES.LUCI] = 70;
        rentingcommissionMap[KOTKET_GENES.TOM] = 90;
        rentingcommissionMap[KOTKET_GENES.KOTKET] = 110;
        rentingcommissionMap[KOTKET_GENES.KING] = 150;
    }

    function updateRentingCommission(uint8 _gene, uint256 _commission) public onlyAdminPermission{
        require(_gene <= uint8(KOTKET_GENES.KING), "Invalid Gene");
        require(_commission <= 1000, "Invalid Commission");

        KOTKET_GENES gene = KOTKET_GENES(_gene);
        rentingcommissionMap[gene] = _commission;
        emit RentingCommissionChanged(_gene, _commission, _msgSender());   
    }

    function updateDayInPeriod(uint256 _dayInPeriod) public onlyAdminPermission{
        require(_dayInPeriod > 0, "Invalid day in period");
        dayInPeriod = _dayInPeriod;
        emit DayInPeriodChanged(_dayInPeriod, _msgSender());   
    }

    function changeDepositTime( uint256 _tokenId, uint256 _startAt, uint256 _endAt, uint256 _lastCheckoutAt) public onlyAdminPermission{
        require(depositItemInfoMap[_tokenId].owner != address(0), "Invalid Token Id");    

        if (_startAt > 0){
            depositItemInfoMap[_tokenId].startAt = _startAt;
        }

        if (_endAt > 0){
            depositItemInfoMap[_tokenId].endAt = _endAt;
        }

        if (_lastCheckoutAt > 0){
            depositItemInfoMap[_tokenId].lastCheckoutAt = _lastCheckoutAt;
        }
    }

    function sendItemToPlatform( uint256 _tokenId, uint256 _period) public {
        require(_period > 0, "Invalid period");
        
        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        require(kotketNFT.tokenExisted(_tokenId), "Invalid Token Id");
        require(kotketNFT.ownerOf(_tokenId) == _msgSender(), "Not Owner Of Token");
        require(kotketNFT.getApproved(_tokenId) == address(this), "Contract does not have approval from owner");
       
        kotketNFT.safeTransferFrom(_msgSender(), governance.kotketWallet(), _tokenId);
       
        
        uint256 _startAt = block.timestamp;
        uint256 _endAt = (_period.mul(dayInPeriod)).mul(86400) + _startAt;

        depositItemInfoMap[_tokenId].owner = _msgSender();
        depositItemInfoMap[_tokenId].startAt = _startAt;
        depositItemInfoMap[_tokenId].endAt = _endAt;
        depositItemInfoMap[_tokenId].lastCheckoutAt = _startAt;

        emit DepositItem(_tokenId, _msgSender(), _startAt, _endAt);
    }

    function makeNewRentingPeriod( uint256 _tokenId, uint256 _period) public {
        require(_period > 0, "Invalid period");
        require(depositItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");
       
        uint256 _startAt = block.timestamp;
        require(_startAt > depositItemInfoMap[_tokenId].endAt, "Not Time To Make New Renting Period");        

        uint256 _endAt = (_period.mul(dayInPeriod)).mul(86400) + _startAt;
        depositItemInfoMap[_tokenId].startAt = _startAt;
        depositItemInfoMap[_tokenId].endAt = _endAt;
        depositItemInfoMap[_tokenId].lastCheckoutAt = _startAt;

        emit DepositItem(_tokenId, _msgSender(), _startAt, _endAt);
    }

    function withdrawalItem( uint256 _tokenId) public {
        require(depositItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");
       
        uint256 _current = block.timestamp;
        require(_current > depositItemInfoMap[_tokenId].endAt, "Not Time To Withdrawal Item");  


        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        require(kotketNFT.isApprovedForAll(governance.kotketWallet(), address(this)), "Contract does not have approval from kotketWallet");
        kotketNFT.safeTransferFrom(governance.kotketWallet(), _msgSender(), _tokenId);

        delete depositItemInfoMap[_tokenId]; 

        emit WithdrawalItem(_tokenId, _msgSender());
    }


    function checkBenefit(uint256 _tokenId ) public view returns(uint256){
        require(depositItemInfoMap[_tokenId].owner != address(0), "Invalid Token Id");

        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        uint8 _gene = kotketNFT.getGene(_tokenId);

        EKotketNFTFactoryInterface kotketNFTFactory = EKotketNFTFactoryInterface(governance.kotketNFTFactoryAddress());
        (uint uKotketTokenPrice, uint eWeiPrice) = kotketNFTFactory.checkKotketPrice(_gene);
        
        uint256 timeStamp = block.timestamp;
        if (timeStamp > depositItemInfoMap[_tokenId].endAt){
            timeStamp = depositItemInfoMap[_tokenId].endAt;
        }
        
        if (depositItemInfoMap[_tokenId].lastCheckoutAt > timeStamp){
            return 0;
        }

        uint256 passTime = timeStamp - depositItemInfoMap[_tokenId].lastCheckoutAt;
        uint256 passDays = passTime.div(86400);
        if (passDays == 0){
            return 0;
        }


        KOTKET_GENES gene = KOTKET_GENES(_gene);
        uint256 rentingcommission = rentingcommissionMap[gene];
        uint256 benefitInPeriod = uKotketTokenPrice.mul(rentingcommission).div(1000);
        uint256 benefitPerday = benefitInPeriod.div(dayInPeriod); 
        
        return benefitPerday.mul(passDays);
    }

    function withdrawalBenefit( uint256 _tokenId ) public{
        require(depositItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");

        uint256 benefit = checkBenefit(_tokenId);
        require(benefit > 0, "No benefit to withdrawal");

        EKotketTokenInterface kotketToken = EKotketTokenInterface(governance.kotketTokenAddress());
        require(kotketToken.balanceOf(governance.kotketWallet()) >= benefit, "Insufficient kotketWallet Balance!");
        require(kotketToken.allowance(governance.kotketWallet(), address(this)) >= benefit, "Contract does not have enough token allowance from kotketWallet");

        kotketToken.transferFrom(governance.kotketWallet(), _msgSender(), benefit);

        uint256 timeStamp = block.timestamp;
        depositItemInfoMap[_tokenId].lastCheckoutAt = timeStamp;
        
        emit WithdrawalBenefit(_tokenId, _msgSender(), timeStamp);
    }

}