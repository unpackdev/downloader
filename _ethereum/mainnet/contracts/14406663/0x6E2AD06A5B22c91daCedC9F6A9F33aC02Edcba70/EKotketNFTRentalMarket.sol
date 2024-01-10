// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


import "./EGovernanceBase.sol";
import "./EKotketNFTInterface.sol";
import "./EKotketTokenInterface.sol";
import "./SafeMath.sol";

contract EKotketNFTRentalMarket is EGovernanceBase{
    using SafeMath for uint256;

    enum PROFIT_RECEIVING_METHOD { BY_DAY, END_OF_PERIOD }

    struct RentalItemInfo {
        address owner;    
        address renter;
        address depositAddr;    
        uint256 uKotketTokenBasePrice;
        uint256 interestRate;
        uint256 period;
        uint256 startAt;
        uint256 extensionFrom;
        uint256 endAt;
        uint256 lastCheckoutAt;
        PROFIT_RECEIVING_METHOD profitReceivingMethod;
        bool stopForRent;
    }

    mapping (uint256 => RentalItemInfo) public rentalItemInfoMap;

    mapping (address => mapping (uint256 => uint256)) public kotketBalanceMap;

    uint256 public serviceCommissionByDay = 50;
    uint256 public serviceCommissionByEndOfPeriod = 30;
    uint256 public periodWorkingday = 45;


    event ServiceCommissionChanged(uint256 serviceCommissionByDay, uint256 serviceCommissionByEndOfPeriod, address setter);
    event ItemForRent(uint256 indexed id, address indexed owner, uint256 uKotketTokenBasePrice, uint256 interestRate, uint256 period, PROFIT_RECEIVING_METHOD profitReceivingMethod);
    event ChangeItemPolicy(uint256 indexed id, uint256 uKotketTokenBasePrice, uint256 interestRate, uint256 period, PROFIT_RECEIVING_METHOD profitReceivingMethod);
    event WithdrawalItemForRent(uint256 indexed id, address indexed owner);
    event StopItemForRent(uint256 indexed id, address indexed owner, bool stop);
    event RemoveRenter(uint256 indexed id, address indexed owner, address indexed renter);
    event ItemRented(uint256 indexed id, address indexed renter, uint256 startAt, uint256 extensionFrom, uint256 endAt);

    event UpdateDepositAddress(uint256 indexed id, address indexed depositAddr);    
    event WithdrawalBenefit(uint256 indexed id, address indexed owner, uint uKotketToken, uint256 lastCheckoutAt);

    constructor(address _governanceAdress) EGovernanceBase(_governanceAdress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function updateServiceCommissionByDay(uint256 _serviceCommissionByDay) public onlyAdminPermission{
        require(_serviceCommissionByDay <= 1000, "Invalid Commission");
        serviceCommissionByDay = _serviceCommissionByDay;     
        emit ServiceCommissionChanged(serviceCommissionByDay, serviceCommissionByEndOfPeriod, _msgSender());   
    }

    function updateServiceCommissionByEndOfPeriod(uint256 _serviceCommissionByEndOfPeriod) public onlyAdminPermission{
        require(_serviceCommissionByEndOfPeriod <= 1000, "Invalid Commission");
        serviceCommissionByEndOfPeriod = _serviceCommissionByEndOfPeriod;     
        emit ServiceCommissionChanged(serviceCommissionByDay, serviceCommissionByEndOfPeriod, _msgSender());   
    }

    function changeRentalTime( uint256 _tokenId, uint256 _startAt, uint256 _lastCheckoutAt, uint256 _extensionFrom, uint256 _endAt) public onlyAdminPermission{
        require(rentalItemInfoMap[_tokenId].owner != address(0), "Invalid Token Id");
        require(rentalItemInfoMap[_tokenId].renter != address(0), "No Renter");

        rentalItemInfoMap[_tokenId].startAt = _startAt;
        rentalItemInfoMap[_tokenId].lastCheckoutAt = _lastCheckoutAt;
        rentalItemInfoMap[_tokenId].extensionFrom = _extensionFrom;
        rentalItemInfoMap[_tokenId].endAt = _endAt;
    }

    function sendItemForRent( 
        uint256 _tokenId,
        uint256 _uKotketTokenBasePrice, 
        uint256 _interestRate, 
        uint256 _period,
        uint8 _profitReceivingMethod) public {

        require(_interestRate <= 1000, "Invalid Interest Rate");

        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        require(_period > 0 , "Invalid period");
        require(kotketNFT.tokenExisted(_tokenId), "Invalid Token Id");
        require(kotketNFT.ownerOf(_tokenId) == _msgSender(), "Not Owner Of Token");
        require(kotketNFT.getApproved(_tokenId) == address(this), "Contract does not have approval from owner");
        require(_profitReceivingMethod <= uint8(PROFIT_RECEIVING_METHOD.END_OF_PERIOD), "Invalid profit Receiving Method");
        PROFIT_RECEIVING_METHOD receivingMethod = PROFIT_RECEIVING_METHOD(_profitReceivingMethod);

        kotketNFT.safeTransferFrom(_msgSender(), governance.kotketWallet(), _tokenId);

        rentalItemInfoMap[_tokenId].owner = _msgSender();
        rentalItemInfoMap[_tokenId].uKotketTokenBasePrice = _uKotketTokenBasePrice;
        rentalItemInfoMap[_tokenId].interestRate = _interestRate;
        rentalItemInfoMap[_tokenId].period = _period;
        rentalItemInfoMap[_tokenId].profitReceivingMethod = receivingMethod;
        rentalItemInfoMap[_tokenId].stopForRent = false;

        emit ItemForRent(_tokenId, _msgSender(), _uKotketTokenBasePrice, _interestRate, _period, receivingMethod);
    }

    function changeItemRentalPolicy( uint256 _tokenId, 
        uint256 _uKotketTokenBasePrice,  
        uint256 _interestRate,
        uint256 _period,
        uint8 _profitReceivingMethod) public {

        require(_interestRate <= 1000, "Invalid Interest Rate");

        require(rentalItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");
        require(rentalItemInfoMap[_tokenId].renter == address(0), "Still have renter");
        require(_profitReceivingMethod <= uint8(PROFIT_RECEIVING_METHOD.END_OF_PERIOD), "Invalid profit Receiving Method");
        PROFIT_RECEIVING_METHOD receivingMethod = PROFIT_RECEIVING_METHOD(_profitReceivingMethod);

        rentalItemInfoMap[_tokenId].uKotketTokenBasePrice = _uKotketTokenBasePrice;
        rentalItemInfoMap[_tokenId].interestRate = _interestRate;
        rentalItemInfoMap[_tokenId].period = _period;
        rentalItemInfoMap[_tokenId].profitReceivingMethod = receivingMethod;
        
        emit ChangeItemPolicy(_tokenId, _uKotketTokenBasePrice, _interestRate, _period, receivingMethod);
    }

    function withdrawalItem( uint256 _tokenId) public {
        require(rentalItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");
        require(rentalItemInfoMap[_tokenId].renter == address(0), "Still have renter");
       
        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        require(kotketNFT.isApprovedForAll(governance.kotketWallet(), address(this)), "Contract does not have approval from kotketWallet");
        kotketNFT.safeTransferFrom(governance.kotketWallet(), _msgSender(), _tokenId);
     
        delete rentalItemInfoMap[_tokenId]; 

        emit WithdrawalItemForRent(_tokenId, _msgSender());
    }

    function stopForRent( uint256 _tokenId, bool _stop) public{
        require(rentalItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");

        if (_stop && rentalItemInfoMap[_tokenId].renter != address(0)){
            uint256 timeStamp = block.timestamp;
            require(timeStamp < rentalItemInfoMap[_tokenId].extensionFrom || timeStamp > rentalItemInfoMap[_tokenId].endAt, "Not Time To Stop Renting");
        }

        rentalItemInfoMap[_tokenId].stopForRent = _stop;

        emit StopItemForRent(_tokenId, _msgSender(), _stop);
    }

    function removeRenter( uint256 _tokenId) public{
        require(rentalItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");

        uint256 timeStamp = block.timestamp;
        require(timeStamp > rentalItemInfoMap[_tokenId].endAt, "Not Time To Remove Renter");

        address renter = rentalItemInfoMap[_tokenId].renter;
        rentalItemInfoMap[_tokenId].renter = address(0);
        rentalItemInfoMap[_tokenId].depositAddr = address(0);
        rentalItemInfoMap[_tokenId].startAt = 0;
        rentalItemInfoMap[_tokenId].extensionFrom = 0;
        rentalItemInfoMap[_tokenId].endAt = 0;
        rentalItemInfoMap[_tokenId].lastCheckoutAt = 0;

        emit RemoveRenter(_tokenId, rentalItemInfoMap[_tokenId].owner, renter);
    }

    function depositItemToPlatform(uint256 _tokenId, address _depositAddr) public{
        uint256 timeStamp = block.timestamp;
        require(rentalItemInfoMap[_tokenId].owner != address(0), "Invalid Token Id");
        require(rentalItemInfoMap[_tokenId].renter == _msgSender(), "Not Renter Of Token");
        require(rentalItemInfoMap[_tokenId].endAt >= timeStamp, "Over renting time");
        rentalItemInfoMap[_tokenId].depositAddr = _depositAddr;
        emit UpdateDepositAddress(_tokenId, _depositAddr);
    }

    function withdrawalItemFromPlatform(uint256 _tokenId) public{
        require(rentalItemInfoMap[_tokenId].owner != address(0), "Invalid Token Id");
        require(rentalItemInfoMap[_tokenId].renter == _msgSender(), "Not Renter Of Token");
        rentalItemInfoMap[_tokenId].depositAddr = address(0);
        emit UpdateDepositAddress(_tokenId, address(0));
    }

    function rentItem( uint256 _tokenId, address _beneficiary) public{
        require(_beneficiary != address(0), "Invalid renter");
        require(rentalItemInfoMap[_tokenId].owner != address(0), "Invalid Token Id");
        require(rentalItemInfoMap[_tokenId].renter == address(0), "Already have renter");
        require(!rentalItemInfoMap[_tokenId].stopForRent, "Already stop for rent");

        _calculateFeeAndPrice(_tokenId);

        uint256 _startAt = block.timestamp;
        uint256 _endAt = rentalItemInfoMap[_tokenId].period.mul(periodWorkingday).mul(86400) + _startAt;
        uint256 _extensionFrom = _endAt - (15*86400);

        rentalItemInfoMap[_tokenId].renter = _beneficiary;
        rentalItemInfoMap[_tokenId].startAt = _startAt;
        rentalItemInfoMap[_tokenId].lastCheckoutAt = _startAt;
        rentalItemInfoMap[_tokenId].endAt = _endAt;
        rentalItemInfoMap[_tokenId].extensionFrom =  _extensionFrom;


        emit ItemRented(_tokenId, _beneficiary, _startAt, _extensionFrom, _endAt);
    }

    function itemRentalExtension( uint256 _tokenId, address _beneficiary) public{
        uint256 timeStamp = block.timestamp;
        require(rentalItemInfoMap[_tokenId].owner != address(0), "Invalid Token Id");
        require(rentalItemInfoMap[_tokenId].renter == _beneficiary, "Invalid Renter");
        require(!rentalItemInfoMap[_tokenId].stopForRent, "Already stop for rent");
        require(rentalItemInfoMap[_tokenId].extensionFrom <= timeStamp, "Not in extension time");
        require(rentalItemInfoMap[_tokenId].endAt >= timeStamp, "Over extension time");

        _calculateFeeAndPrice(_tokenId);

        uint256 _endAt = rentalItemInfoMap[_tokenId].endAt.add(rentalItemInfoMap[_tokenId].period.mul(periodWorkingday).mul(86400));
        uint256 _extensionFrom = _endAt - (15*86400);

        rentalItemInfoMap[_tokenId].endAt = _endAt;
        rentalItemInfoMap[_tokenId].extensionFrom =  _extensionFrom;

        emit ItemRented(_tokenId, _beneficiary, rentalItemInfoMap[_tokenId].startAt, _extensionFrom, _endAt);
    }

    function _calculateFeeAndPrice(uint256 _tokenId) internal{
        uint256 basePrice = rentalItemInfoMap[_tokenId].uKotketTokenBasePrice;
        uint256 interestRate = rentalItemInfoMap[_tokenId].interestRate;
        
        uint256 interest = basePrice.mul(interestRate).div(1000);
        uint256 price = basePrice.add(interest);
        uint256 priceInPeriod = price.mul(rentalItemInfoMap[_tokenId].period);
       
        EKotketTokenInterface kotketToken = EKotketTokenInterface(governance.kotketTokenAddress());
        require(kotketToken.balanceOf(_msgSender()) >= priceInPeriod, "Insufficient Kotket Token Balance!");

        uint256 tokenAllowance = kotketToken.allowance(_msgSender(), address(this));
        require(tokenAllowance >= priceInPeriod, "Not Allow Enough Kotket Token To Buy NFT");

        uint256 serviceCommission = serviceCommissionByDay;
        if (rentalItemInfoMap[_tokenId].profitReceivingMethod == PROFIT_RECEIVING_METHOD.END_OF_PERIOD){
            serviceCommission = serviceCommissionByEndOfPeriod;
        }

        uint256 commissionFee = priceInPeriod.mul(serviceCommission).div(1000);
        uint256 ownerAmountReceive = priceInPeriod - commissionFee;

        kotketToken.transferFrom(_msgSender(), address(this), priceInPeriod);
        kotketBalanceMap[rentalItemInfoMap[_tokenId].owner][_tokenId] += ownerAmountReceive;
    }

    function getWithdrawableBenefit(uint256 _tokenId) public view returns(uint256){
        require(rentalItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");
        uint256 reward = 0;
        uint256 timeStamp = block.timestamp;
        
        if (timeStamp > rentalItemInfoMap[_tokenId].endAt){
            reward = kotketBalanceMap[_msgSender()][_tokenId];
        }else{
            reward = _calculateReward(_tokenId, timeStamp );

            if (reward > kotketBalanceMap[_msgSender()][_tokenId]){
                reward = kotketBalanceMap[_msgSender()][_tokenId];
            }   
        }
        return reward;
    }

    function withdrawalBenefit( uint256 _tokenId ) public{
        require(rentalItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");

        
        uint256 timeStamp = block.timestamp;

        uint256 reward = getWithdrawableBenefit(_tokenId);
        require(reward > 0, "No kotket token to withdrawal");

        EKotketTokenInterface kotketToken = EKotketTokenInterface(governance.kotketTokenAddress());
        require(kotketToken.balanceOf(address(this)) >= reward, "Insufficient Contract Kotket Token Balance!");
        kotketToken.transfer(_msgSender(), reward);

        kotketBalanceMap[_msgSender()][_tokenId] -= reward;

        rentalItemInfoMap[_tokenId].lastCheckoutAt = timeStamp;

        emit WithdrawalBenefit(_tokenId, _msgSender(), reward, timeStamp);
    }

    function _calculateReward(uint256 _tokenId,  uint256 _timeStamp ) internal view returns(uint256){  
        PROFIT_RECEIVING_METHOD profitReceivingMethod = rentalItemInfoMap[_tokenId].profitReceivingMethod;
        uint256 period = rentalItemInfoMap[_tokenId].period;
        
        uint256 basePrice = rentalItemInfoMap[_tokenId].uKotketTokenBasePrice;
        
        uint256 interest = basePrice.mul(rentalItemInfoMap[_tokenId].interestRate).div(1000);
        uint256 price = basePrice.add(interest);
        uint256 priceInPeriod = price.mul(period);

        uint256 serviceCommission = serviceCommissionByDay;
        if (profitReceivingMethod == PROFIT_RECEIVING_METHOD.END_OF_PERIOD){
            serviceCommission = serviceCommissionByEndOfPeriod;
        }
        uint256 commissionFee = priceInPeriod.mul(serviceCommission).div(1000);
        uint256 benefitInPeriod = priceInPeriod - commissionFee;
        uint256 benefitPerday = benefitInPeriod.div(periodWorkingday).div(period);

        uint256 passTime = _timeStamp - rentalItemInfoMap[_tokenId].lastCheckoutAt;
        uint256 passDays = passTime.div(86400);
        uint256 passPeriods = passDays.div(periodWorkingday).div(period);

        uint256 reward = 0;
        if (profitReceivingMethod == PROFIT_RECEIVING_METHOD.END_OF_PERIOD){
            reward = passPeriods.mul(benefitInPeriod);
        }else{
            reward = passDays.mul(benefitPerday);
        }
        return reward;
    }

    function transferToken(address to, uint amount) public onlyAdminPermission{
        EKotketTokenInterface kotketToken = EKotketTokenInterface(governance.kotketTokenAddress());
        require(amount > 0, "Invalid amount");
        require(kotketToken.balanceOf(address(this)) >= amount, "Insufficient Balance!");
        kotketToken.transfer(to, amount);
    }
}