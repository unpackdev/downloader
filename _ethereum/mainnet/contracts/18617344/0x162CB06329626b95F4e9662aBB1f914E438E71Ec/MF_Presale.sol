// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./CurrencyTransferLib.sol";
import "./PermissionsEnumerable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";

struct Stage {
    uint256 startAt;
    uint256 price;
}

struct Token {
    uint8 decimals;
    address priceFeedAddress; // if this is null => stable coin. if this is 0xeeee...eeee => native token
    uint8 priceFeedDecimals;
    uint256 paid;
    IERC20 instance;
}

contract MemeFighterPresaleContract is PermissionsEnumerable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    address constant public etherTokenAdress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 constant MAX_UINT256 = type(uint256).max;
    uint16 public constant BPS_DENOMINATOR = 100_00;

    constructor() {
        address deployer = msg.sender;
        address feeReceiverWallet_ = 0x1D566C44cdE8f3d7dfC7848756b669380d25e6C1;
        _setupRole(DEFAULT_ADMIN_ROLE, deployer);
        _setupRole(DEFAULT_ADMIN_ROLE, feeReceiverWallet_);
        updateMofoTokenContract(address(0));
        updateFeeReceiverWallet(feeReceiverWallet_);
        updateReferrerRewardBPS(0); // 0% referrer commission
        updateGlobalUsdDepositLimit(1_000_000 ether); // 1m$
        updateGlobalMofoDepositLimit(2_250_000_000 ether); // 2.5B - 0.25B seed sale
        updateUserUsdDepositLimit(50_000 ether); // 50k$
        updateUserMofoDepositLimit(MAX_UINT256); // unlimited
        updatePriceQuoteExpirationTime(1 * 3600); // 1 hour

        if(block.chainid == 1) { // ETH
            addOrUpdatePaymentToken(0xdAC17F958D2ee523a2206206994597C13D831ec7, address(0));
            addOrUpdatePaymentToken(etherTokenAdress, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH/USD price feed
            addStage(1700536500, 0.0045 ether);
        }

        if(block.chainid == 56) { // BSC
            addOrUpdatePaymentToken(0x55d398326f99059fF775485246999027B3197955, address(0));
            addOrUpdatePaymentToken(etherTokenAdress, 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // BNB/USD price feed
            addStage(1700536500, 0.0045 ether);
        }
    }

    // public get - internal set
    EnumerableSet.AddressSet depositorSet;
    uint256 public globalMofoDepositedAmount = 0;
    uint256 public globalUsdDepositedAmount = 0; // pre-allocated on BSC
    mapping(address => uint256) public userMofoDeposited;
    mapping(address => uint256) public userUsdDeposited;
    mapping(address => Token) paymentTokenMap;

    // public get - admin set
    Stage[] stageList;
    IERC20 mofoTokenContract;
    address public feeReceiverWallet;
    uint16 public referrerRewardBPS = 0;
    uint16 public priceQuoteExpirationTime = 0;
    uint256 public globalUsdDepositLimit = 0;
    uint256 public globalMofoDepositLimit = 0;
    uint256 public userUsdDepositLimit = 0;
    uint256 public userMofoDepositLimit = 0;

    event StageAdded(uint256, uint256, uint256);
    event StageUpdated(uint256, uint256, uint256);
    event MofoTokenContractUpdated(address);
    event FeeReceiverWalletUpdated(address);
    event ReferrerRewardBPSUpdated(uint256);
    event PriceQuoteExpirationTimeUpdated(uint16);
    event GlobalUsdDepositLimitUpdated(uint256);
    event GlobalMofoDepositLimitUpdated(uint256);
    event UserUsdDepositLimitUpdated(uint256);
    event UserMofoDepositLimitUpdated(uint256);

    event MofoDeposited(
        address indexed account,
        uint256 indexed stageId,
        address indexed paidTokenAddress,
        uint256 paidTokenAmount,
        uint256 paidTokenPriceFeedRoundId,
        address referrer,
        uint256 mofoAmount
    );
    event ReferrerRewarded(address, address, uint256);
    event MofoWithdrawn(
        address indexed account,
        uint256 mofoAmount
    );

    /*//////////////////////////////////////////////////////////////
    INTERNAL region
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ADMIN_ROLE required");
        _;
    }

    modifier stageNotExpired(uint256 stageId) {
        uint256 stageEndAt = (stageId + 1 == stageList.length) ? MAX_UINT256 : (stageList[stageId + 1].startAt + priceQuoteExpirationTime);
        require(block.timestamp >= stageList[stageId].startAt && block.timestamp < stageEndAt, "Quote has expired");
        _;
    }

    // calculate and credit mofo to user with the usd amount supplied
    function _deposit(address account, uint256 usdAmount, uint256 stageId) internal returns (uint256) {
        require(stageList[stageId].price > 0, "Reserving is currently unavailable");
        require(usdAmount > 0, "Usd deposit amount must greater than 0");
        uint256 mofoAmount = usdAmount * 1 ether / stageList[stageId].price;
        userMofoDeposited[account] += mofoAmount;
        globalMofoDepositedAmount += mofoAmount;
        userUsdDeposited[account] += usdAmount;
        globalUsdDepositedAmount += usdAmount;
        require(globalMofoDepositedAmount <= globalMofoDepositLimit && globalUsdDepositedAmount <= globalUsdDepositLimit, "Global deposit limit has reached");
        require(userMofoDeposited[account] <= userMofoDepositLimit && userUsdDeposited[account] <= userUsdDepositLimit, "User deposit limit has reached");
        if(!depositorSet.contains(account)) {
            depositorSet.add(account);
        }
        return mofoAmount;
    }

    function _toEther(uint256 input, uint8 decimals) internal pure returns (uint256) {
        return input * 10 ** (18 - decimals);
    }

    function _toEther(int256 input, uint8 decimals) internal pure returns (uint256) {
        require(input > 0);
        return _toEther(uint256(input), decimals);
    }

    // startAt must in the ASC order
    function _assertStageList() internal view {
        uint256 nStage = stageList.length;
        uint256 lastStartAt = 0;
        for(uint256 i=0; i<nStage; i++) {
            require(stageList[i].startAt > lastStartAt, "Stage assertion failed");
            lastStartAt = stageList[i].startAt;
        }
    }

    /*//////////////////////////////////////////////////////////////
    ADMIN READ region
    //////////////////////////////////////////////////////////////*/

    // return list of depositor addresses (may cause out-of-gas)
    function getDepositorList() public view onlyAdmin returns (address[] memory) {
        return depositorSet.values();
    }

    /*//////////////////////////////////////////////////////////////
    ADMIN WRITE region
    //////////////////////////////////////////////////////////////*/

    function transferCurrency(address _currency, address _to, uint256 _amount) external onlyAdmin {
        CurrencyTransferLib.transferCurrency(_currency, address(this), _to, _amount);
    }

    function transferCurrencyWithWrapper(address _currency, address _to, uint256 _amount, address _nativeTokenWrapper) external onlyAdmin {
        CurrencyTransferLib.transferCurrencyWithWrapper(_currency, address(this), _to, _amount, _nativeTokenWrapper);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    // set price_ = 0 to end/pause the sale
    function addStage(uint256 startAt_, uint256 price_) public onlyAdmin {
        require(block.timestamp < startAt_, "startAt_ must be in the future");
        uint256 id_ = stageList.length;
        stageList.push(
            Stage({
                startAt: startAt_,
                price: price_
            })
        );
        _assertStageList();
        emit StageAdded(id_, startAt_, price_);
    }

    // update price_ = 0 to end/pause the sale
    function updateStage(uint256 stageId_, uint256 startAt_, uint256 price_) public onlyAdmin {
        require(block.timestamp < stageList[stageId_].startAt, "stageId_ not found or not updatable");
        require(block.timestamp < startAt_, "startAt_ must be in the future");
        stageList[stageId_].startAt = startAt_;
        stageList[stageId_].price = price_;
        _assertStageList();
        emit StageUpdated(stageId_, startAt_, price_);
    }

    function updateMofoTokenContract(address mofoTokenContract_) public onlyAdmin {
        mofoTokenContract = IERC20(mofoTokenContract_);
        emit MofoTokenContractUpdated(mofoTokenContract_);
    }

    function updateFeeReceiverWallet(address feeReceiverWallet_) public onlyAdmin {
        feeReceiverWallet = feeReceiverWallet_;
        emit FeeReceiverWalletUpdated(feeReceiverWallet_);
    }

    function updateReferrerRewardBPS(uint16 referrerRewardBPS_) public onlyAdmin {
        referrerRewardBPS = referrerRewardBPS_;
        emit ReferrerRewardBPSUpdated(referrerRewardBPS_);
    }

    function updatePriceQuoteExpirationTime(uint16 priceQuoteExpirationTime_) public onlyAdmin {
        priceQuoteExpirationTime = priceQuoteExpirationTime_;
        emit PriceQuoteExpirationTimeUpdated(priceQuoteExpirationTime_);
    }

    function updateGlobalUsdDepositLimit(uint256 globalUsdDepositLimit_) public onlyAdmin {
        globalUsdDepositLimit = globalUsdDepositLimit_;
        emit GlobalUsdDepositLimitUpdated(globalUsdDepositLimit_);
    }

    function updateGlobalMofoDepositLimit(uint256 globalMofoDepositLimit_) public onlyAdmin {
        globalMofoDepositLimit = globalMofoDepositLimit_;
        emit GlobalMofoDepositLimitUpdated(globalMofoDepositLimit_);
    }

    function updateUserUsdDepositLimit(uint256 userUsdDepositLimit_) public onlyAdmin {
        userUsdDepositLimit = userUsdDepositLimit_;
        emit UserUsdDepositLimitUpdated(userUsdDepositLimit_);
    }

    function updateUserMofoDepositLimit(uint256 userMofoDepositLimit_) public onlyAdmin {
        userMofoDepositLimit = userMofoDepositLimit_;
        emit UserMofoDepositLimitUpdated(userMofoDepositLimit_);
    }

    function addOrUpdatePaymentToken(address contractAddress_, address priceFeedAddress_) public onlyAdmin {
        paymentTokenMap[contractAddress_] = Token({
            decimals: contractAddress_ == etherTokenAdress ? 18 : IERC20Metadata(contractAddress_).decimals(),
            priceFeedAddress: priceFeedAddress_,
            priceFeedDecimals: priceFeedAddress_ == address(0) ? 0 : AggregatorV3Interface(priceFeedAddress_).decimals(),
            paid: paymentTokenMap[contractAddress_].paid,
            instance: IERC20(contractAddress_)
        });
    }

    /*//////////////////////////////////////////////////////////////
    PUBLIC READ region
    //////////////////////////////////////////////////////////////*/

    function getDepositorCount() public view returns (uint256) {
        return depositorSet.length();
    }

    function getPaymentToken(address token_) public view returns (Token memory) {
        return paymentTokenMap[token_];
    }

    function getStageList() public view returns (Stage[] memory) {
        return stageList;
    }

    /*//////////////////////////////////////////////////////////////
    PUBLIC WRITE region
    //////////////////////////////////////////////////////////////*/

    function withdraw() public whenNotPaused {
        require(address(mofoTokenContract) != address(0), "MEME Fighter token not yet revealed");
        Stage memory lastStage = stageList[stageList.length - 1];
        require(lastStage.price == 0 && block.timestamp >= lastStage.startAt, "Withdrawal not yet possible");
        uint256 depositedAmount = userMofoDeposited[msg.sender];
        require(depositedAmount > 0, "No token to withdraw");
        userMofoDeposited[msg.sender] = 0;
        (bool success) = mofoTokenContract.transfer(msg.sender, depositedAmount);
        require(success, "MEME Fighter token transfer failed");
        emit MofoWithdrawn(msg.sender, depositedAmount);
    }

    function deposit(uint256 stageId_, address paidTokenAddress_, uint256 paidTokenAmount_, uint80 priceFeedRoundId_, address referrer_) public payable stageNotExpired(stageId_) whenNotPaused {
        uint256 epoch = block.timestamp;
        Token storage paidToken = paymentTokenMap[paidTokenAddress_];
        require(paidToken.decimals > 0, "Unsupported payment token");
        if(paidTokenAddress_ == etherTokenAdress) {
            paidTokenAmount_ = msg.value;
            (bool success, ) = feeReceiverWallet.call{value: paidTokenAmount_}("");
            require(success, "Ether transfer failed");
        } else {
            // require(paidToken.instance.balanceOf(msg.sender) >= paidTokenAmount_, "Insufficient token balance");
            // require(paidToken.instance.allowance(msg.sender, address(this)) >= paidTokenAmount_, "Insufficient token spending allowance");
            // (bool success) = paidToken.instance.transferFrom(msg.sender, feeReceiverWallet, paidTokenAmount_);
            (bool success,) = address(paidToken.instance).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    msg.sender,
                    feeReceiverWallet,
                    paidTokenAmount_
                )
            );
            require(success, "Fund transfer failed due to insufficient balance or spending allowance");
        }
        uint256 paidTokenUsdPrice;
        if(paidToken.priceFeedAddress == address(0)) { // stable coin
            paidTokenUsdPrice = 1 ether;
        } else {
            ( , int256 answer, , uint256 updatedAt, ) = AggregatorV3Interface(paidToken.priceFeedAddress).getRoundData(priceFeedRoundId_);
            require(epoch < updatedAt + priceQuoteExpirationTime, "Quote has expired");
            paidTokenUsdPrice = _toEther(answer, paidToken.priceFeedDecimals);
        }
        paidToken.paid += paidTokenAmount_;
        uint256 paidUsdAmount = _toEther(paidTokenAmount_, paidToken.decimals) * paidTokenUsdPrice / 1 ether;
        uint256 mofoAmount = _deposit(msg.sender, paidUsdAmount, stageId_);
        emit MofoDeposited(msg.sender, stageId_, paidTokenAddress_, paidTokenAmount_, priceFeedRoundId_, referrer_, mofoAmount);
        if(referrerRewardBPS > 0 && referrer_ != address(0) && referrer_ != msg.sender) {
            uint256 referrerUsdReward = paidUsdAmount * referrerRewardBPS / 1_00_00;
            _deposit(referrer_, referrerUsdReward, stageId_);
            emit ReferrerRewarded(msg.sender, referrer_, referrerUsdReward);
        }
    }

}
