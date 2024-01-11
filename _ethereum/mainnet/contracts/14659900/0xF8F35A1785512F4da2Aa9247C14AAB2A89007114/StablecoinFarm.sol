//SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeCast.sol";

import "./IConversionPool.sol";

contract StablecoinFarm is Ownable, ReentrancyGuard {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    uint24 constant HUNDRED_PERCENT = 1e6;
    uint24 constant MIN_SLIPPAGE = 9e5;
    uint24 constant MAX_REFERRER_USER_FEE = 3e5;
    uint256 constant MIN_GLOBAL_AMOUNT = 1e20;
    uint256 constant REFERRAL_ID_LENGTH = 8;
    
    IConversionPool public conversionPool;
    IERC20 immutable public outputToken;
    IERC20 immutable public inputToken;
    IERC20 immutable public wUST;
    uint256 immutable MULTIPLIER;

    uint128 public autoGlobalAmount;
    address public feeCollector;
    address public manager;
    uint24 public feePercentage;
    uint24 public swapSlippage = 998000;
    uint24 public depositSlippage = HUNDRED_PERCENT;
    uint24 public withdrawSlippage = HUNDRED_PERCENT;

    struct User {
        uint128 depositedAmount;
        uint128 shares;
        uint128 pendingWithdrawAmount;
        uint128 yieldRegistered;
        string referrerId;
    }
    mapping(address => User) public users;

    struct GlobalState {
        uint128 totalPendingAmount;
        uint128 totalShares;
        uint128 totalPendingWithdrawAmount;
        uint128 totalPendingWithdrawShares;
    }
    GlobalState public globalState;
    
    struct Referrer {
        address referrer;
        uint24 userFee;
        uint24 baseFee;
    }
    mapping(string => Referrer) public referrers;

    event Deposit(address indexed user, string indexed referrerId, uint256 amount, uint256 shares, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 fee, uint256 shares, uint256 timestamp, bool finished);
    event FinishWithdraw(address indexed user, uint256 amount);
    event GlobalDeposit(address sender, uint256 amountOut, uint256 timestamp);
    event GlobalWithdraw(address sender, uint256 shares, uint256 timestamp);
    event IncludeLeftover(address sender, uint256 leftover);
    event ChargeFee(address indexed user, string indexed referrerId, uint256 feeShares, uint256 baseFeeShares);
    event SetReferrer(string id, address referrer, uint24 userFee);
    event SlippageChange(uint256 newSlippage, uint256 slippageType);

    constructor(
        IConversionPool _conversionPool,
        IERC20 _inputToken, 
        IERC20 _outputToken, 
        IERC20 _wUST, 
        address _feeCollector,
        uint24 _feePercentage,
        uint128 _autoGlobalAmount,
        bool usingConversionPool
    ) {
        if (usingConversionPool) {
            require(_inputToken == _conversionPool.inputToken());
            require(_outputToken == _conversionPool.outputToken());
            require(_wUST == _conversionPool.proxyInputToken());
        }

        require(_feeCollector != address(0), "StablecoinFarm: zero address");
        require(_feePercentage <= HUNDRED_PERCENT, "StablecoinFarm: fee higher than 100%");
        MULTIPLIER = 10 ** (36 - IERC20Metadata(address(_inputToken)).decimals());

        conversionPool = _conversionPool;
        inputToken = _inputToken;
        outputToken = _outputToken;
        wUST = _wUST;

        feeCollector = _feeCollector;
        feePercentage = _feePercentage;
        autoGlobalAmount = _autoGlobalAmount;
        manager = msg.sender;
    }

    // =================== OWNER FUNCTIONS  =================== //

    function setFee(uint24 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= HUNDRED_PERCENT, "StablecoinFarm: fee higher than 100%");
        feePercentage = newFeePercentage;
    }

    function setAutoGlobalAmount(uint128 newValue) external onlyOwner {
        autoGlobalAmount = newValue;
    }

    function setFeeCollector(address newFeeCollector) external onlyOwner {
        feeCollector = newFeeCollector;
    }

    function setManager(address newManager) external onlyOwner {
        manager = newManager;
    }
    
    /**
        Only owner can modify fee on feePercentage part.
        @param id - referral id
        @param fee - moving this percentage of fees from feeCollector to the referrer address
    */
    function setReferrerFee(string calldata id, uint24 fee) external onlyOwner {
        require(referrers[id].referrer != address(0), "StablecoinFarm: invalid referral id");
        require(fee <= HUNDRED_PERCENT);
        referrers[id].baseFee = fee;
    }
    
    function setSlippage(uint24 newSlippage, uint8 slippageType) external {
        require(msg.sender == manager || msg.sender == owner(), "StablecoinFarm: unauthorized");
        require(newSlippage <= HUNDRED_PERCENT, "StablecoinFarm: slippage higher than 100%");
        require(newSlippage >= MIN_SLIPPAGE, "StablecoinFarm: invalid slippage");

        if (slippageType == 0) {
            swapSlippage = newSlippage;
        } else if (slippageType == 1) {
            depositSlippage = newSlippage;
        } else {
            withdrawSlippage = newSlippage;
        }

        emit SlippageChange(newSlippage, slippageType);
    }

    // =================== EXTERNAL FUNCTIONS  =================== //

    /**
        Single user deposit. User deposits token and the smart contract issues anchor shares to the user based on the share price.
        @param amount amount of token to deposit
     */
    function deposit(uint128 amount, string calldata referrerId) external nonReentrant returns (uint128 amountWithSlippage) {
        IExchangeRateFeeder _feeder = conversionPool.feeder();
        amountWithSlippage = (uint256(amount) * depositSlippage / HUNDRED_PERCENT).toUint128();
        uint128 shares = (MULTIPLIER * amountWithSlippage / _feeder.exchangeRateOf(address(inputToken), true)).toUint128();
        require(shares > 0, "StablecoinFarm: 0 shares"); 

        _setUserReferrer(amount, referrerId);
        User storage user = users[msg.sender];
        user.shares += shares;
        user.depositedAmount += amountWithSlippage;

        if (globalState.totalPendingWithdrawShares >= shares) {
            globalState.totalPendingWithdrawShares -= shares;
        } else {
            globalState.totalPendingAmount += amount;
            globalState.totalShares += shares;
        }

        inputToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, referrerId, amountWithSlippage, shares, block.timestamp);

        if (amount * MULTIPLIER / 1e18 >= autoGlobalAmount) {
            _globalDeposit(globalState.totalPendingAmount);
        }
    }

    /**
        Sends back min(requestedAmount, maxWithdrawable) amount of token if there's enough balance. 
        If not, add sender's shares to the globalWithdraw pool and assign pendingWithdrawAmount to the sender.
        @param requestedAmount withdraw maximally this amount
     */
    function withdraw(uint128 requestedAmount) external nonReentrant returns (uint128 withdrawAmount, uint128 fee, bool finished) {
        User storage user = users[msg.sender];

        (uint128 maxWithdrawableAmount, uint128 _fee) = _chargeFee(msg.sender);
        fee = _fee;
        withdrawAmount = requestedAmount > maxWithdrawableAmount ? maxWithdrawableAmount : requestedAmount;
        require(withdrawAmount > 0, "StablecoinFarm: nothing to withdraw");
        uint128 sharesNeeded = (user.shares - uint256(maxWithdrawableAmount - withdrawAmount) * user.shares / maxWithdrawableAmount).toUint128();
        
        if (withdrawAmount <= globalState.totalPendingAmount) {
            // remove from pending deposits, tokens can be sent immediately
            globalState.totalPendingAmount -= withdrawAmount;
            globalState.totalShares -= sharesNeeded;
            finished = true;
        } else {
            globalState.totalPendingWithdrawShares += sharesNeeded;

            uint256 freeBalance;
            if (inputToken.balanceOf(address(this)) > globalState.totalPendingAmount) {
                freeBalance = inputToken.balanceOf(address(this)) - globalState.totalPendingAmount;
            }

            if (freeBalance >= withdrawAmount) {
                // enough balance, tokens can be sent immediately
                finished = true;
            } else {
                globalState.totalPendingWithdrawAmount += withdrawAmount;
                user.pendingWithdrawAmount += withdrawAmount;
            }
        }

        uint128 deductAmount = withdrawAmount;
        if (user.yieldRegistered > deductAmount) {
            user.yieldRegistered -= deductAmount;
            deductAmount = 0;
        } else {
            deductAmount -= user.yieldRegistered;
            user.yieldRegistered = 0;
        }
        if (user.depositedAmount > deductAmount) {
            user.depositedAmount -= deductAmount;
        } else {
            user.depositedAmount = 0;
        }

        user.shares -= sharesNeeded;
        if (finished) {
            inputToken.safeTransfer(msg.sender, withdrawAmount);
        } else {
            if (withdrawAmount * MULTIPLIER / 1e18 >= autoGlobalAmount) {
                _globalWithdraw(globalState.totalPendingWithdrawShares);
            }
        }
        emit Withdraw(msg.sender, withdrawAmount, fee, sharesNeeded, block.timestamp, finished);
    }
    
    /**
        Deposit totalPendingAmount into ETH Anchor.
        @param amount maximally this amount of pendingAmount
     */
    function globalDeposit(uint128 amount) external nonReentrant {
        _globalDeposit(amount);
    }

    /**
        Withdraws totalPendingWithdrawShares from ETH Anchor.
        @param shares maximally withdraw this amount of shares
     */
    function globalWithdraw(uint128 shares) external nonReentrant {
        _globalWithdraw(shares);
    }

    /**
        If there's not enough inputToken balance when a user calls withdraw function, 
        a pendingWithdrawAmount is assigned to him. This function sends them the pendingWithdrawAmount.
        @param userAddresses users to finish their withdraw for
        @param wUSTWithdraw whether to withdraw in UST
     */
    function finishWithdraws(address[] calldata userAddresses, bool wUSTWithdraw) external nonReentrant {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            User storage user = users[userAddress];
            uint128 pendingWithdrawAmount = user.pendingWithdrawAmount;
            require(pendingWithdrawAmount > 0, "StablecoinFarm: no pending withdraw amount");

            user.pendingWithdrawAmount = 0;
            globalState.totalPendingWithdrawAmount -= pendingWithdrawAmount;

            if (!wUSTWithdraw) {
                inputToken.safeTransfer(userAddress, pendingWithdrawAmount);
            } else {
                wUST.safeTransfer(userAddress, pendingWithdrawAmount);
            }
            
            emit FinishWithdraw(userAddress, pendingWithdrawAmount);
        }

        if (!wUSTWithdraw || inputToken == wUST) {
            require(inputToken.balanceOf(address(this)) >= globalState.totalPendingAmount, "StablecoinFarm: not enough balance");
        }
    }

    /**
        Charge fees manually.
        @param userAddresses charge fee to these users
     */
    function chargeFees(address[] calldata userAddresses) external {
        for (uint256 i = 0; i < userAddresses.length; i++) {
            _chargeFee(userAddresses[i]);
        }
    }

    /**
        Useful when received more amount than expected after globalWithdraw.
     */
    function includeLeftover() external {
        uint128 leftover = (inputToken.balanceOf(address(this)) - globalState.totalPendingAmount - globalState.totalPendingWithdrawAmount).toUint128();
        globalState.totalPendingAmount += leftover;
        emit IncludeLeftover(msg.sender, leftover);
    }

    /**
        Anyone can create a referral object.
        @param id - referral id
        @param referrer - address receiving fees
        @param userFee - fee on user part where the base is the user maxWithdrawable with already deducted feePercentage
     */
    function setReferrer(string calldata id, address referrer, uint24 userFee) external {
        require(bytes(id).length == REFERRAL_ID_LENGTH, "StablecoinFarm: id invalid length");
        require(referrer != address(0), "StablecoinFarm: zero address");
        require(userFee <= MAX_REFERRER_USER_FEE, "StablecoinFarm: user fee too high");
        require(referrers[id].referrer == address(0) || referrers[id].referrer == msg.sender, "StablecoinFarm: unauthorized");

        referrers[id].referrer = referrer;
        referrers[id].userFee = userFee;
        emit SetReferrer(id, referrer, userFee);
    }

    // =================== INTERNAl FUNCTIONS  =================== //

    /**
        Move some shares of a user to the feeCollector. The fee is based only on yield, not on deposit plus yield.
        @param userAddress charge fee to this user
     */
    function _chargeFee(address userAddress) private returns (uint128 maxWithdrawableAmount, uint128 fee) {
        User storage user = users[userAddress];
        IExchangeRateFeeder _feeder = conversionPool.feeder();
        maxWithdrawableAmount = (uint256(user.shares) * _feeder.exchangeRateOf(address(inputToken), true) * withdrawSlippage / MULTIPLIER / HUNDRED_PERCENT).toUint128();
        if (userAddress == feeCollector) return (maxWithdrawableAmount, 0);

        uint128 yieldRegistered = user.depositedAmount + user.yieldRegistered;
        uint128 yield = maxWithdrawableAmount > yieldRegistered ? maxWithdrawableAmount - yieldRegistered : 0;
        if (yield > 0) {
            uint256 referrerUserFeePercentage = uint256(referrers[user.referrerId].userFee) * (HUNDRED_PERCENT - feePercentage) / HUNDRED_PERCENT;
            uint256 absoluteFeePercentage = feePercentage + referrerUserFeePercentage;
            fee = (uint256(yield) * absoluteFeePercentage / HUNDRED_PERCENT).toUint128();
            uint128 feeShares = (user.shares - uint256(maxWithdrawableAmount - fee) * user.shares / maxWithdrawableAmount).toUint128();
            
            user.yieldRegistered += yield - fee;
            user.shares -= feeShares;
            maxWithdrawableAmount -= fee;

            (uint128 baseFeeShares) = _splitFee(fee, feeShares, user.referrerId, referrerUserFeePercentage);
            emit ChargeFee(userAddress, user.referrerId, feeShares, baseFeeShares);
        }
    }

    function _splitFee(
        uint128 fee, 
        uint128 feeShares, 
        string memory referrerId, 
        uint256 referrerUserFeePercentage
    ) private returns (uint128) {
        uint256 referrerFeePercentage = uint256(referrers[referrerId].baseFee) * feePercentage / HUNDRED_PERCENT;
        referrerFeePercentage += referrerUserFeePercentage;
        uint256 referrerFeeRatio = referrerFeePercentage * HUNDRED_PERCENT / (feePercentage + referrerUserFeePercentage);
        
        address referrer = referrers[referrerId].referrer;
        uint128 referrerFee = (uint256(fee) * referrerFeeRatio / HUNDRED_PERCENT).toUint128();
        uint128 referrerFeeShares = (uint256(feeShares) * referrerFeeRatio / HUNDRED_PERCENT).toUint128();
        users[referrer].depositedAmount += referrerFee;
        users[referrer].shares += referrerFeeShares;

        uint128 baseFee = fee - referrerFee;
        uint128 baseFeeShares = feeShares - referrerFeeShares;
        users[feeCollector].depositedAmount += baseFee;
        users[feeCollector].shares += baseFeeShares;
        return baseFeeShares;
    }

    function _setUserReferrer(uint128 amount, string calldata referrerId) private {
        require(bytes(referrerId).length == 0 || referrers[referrerId].referrer != address(0), "StablecoinFarm: invalid referral id");
        User storage user = users[msg.sender];

        if (amount > user.depositedAmount) {
            // change referrer if user deposited more
            _chargeFee(msg.sender); // charge fee before changing the referrer
            user.referrerId = referrerId;
        }
    }

    function _globalDeposit(uint128 amount) private {
        if (amount > globalState.totalPendingAmount) amount = globalState.totalPendingAmount;
        require(amount * MULTIPLIER / 1e18 >= MIN_GLOBAL_AMOUNT, "StablecoinFarm: not enough amount to deposit");
        
        uint256 minReceived = MULTIPLIER * amount * swapSlippage / HUNDRED_PERCENT / 1e18; // in wUST
        _anchorDeposit(amount, minReceived);

        globalState.totalPendingAmount -= amount;
        emit GlobalDeposit(msg.sender, amount, block.timestamp);
    }

    function _globalWithdraw(uint128 shares) private {
        if (shares > globalState.totalPendingWithdrawShares) shares = globalState.totalPendingWithdrawShares;
        IExchangeRateFeeder _feeder = conversionPool.feeder();
        uint256 rate = _feeder.exchangeRateOf(address(inputToken), true);
        uint128 sharesValue = (uint256(shares) * rate / MULTIPLIER).toUint128();

        if (sharesValue > globalState.totalPendingAmount) {
            uint128 withdrawShares = shares;
            withdrawShares -= (MULTIPLIER * globalState.totalPendingAmount / rate).toUint128();
            globalState.totalPendingAmount = 0;

            require(withdrawShares >= MIN_GLOBAL_AMOUNT, "StablecoinFarm: not enough shares to withdraw");
            _anchorWithdraw(withdrawShares);
        } else {
            globalState.totalPendingAmount -= sharesValue;
        }

        globalState.totalShares -= shares;
        globalState.totalPendingWithdrawShares -= shares;
        emit GlobalWithdraw(msg.sender, shares, block.timestamp);
    }

    function _anchorDeposit(uint256 amount, uint256 minReceived) internal virtual {
        inputToken.safeIncreaseAllowance(address(conversionPool), amount);
        conversionPool.deposit(amount, minReceived);
    }

    function _anchorWithdraw(uint256 shares) internal virtual {
        outputToken.safeIncreaseAllowance(address(conversionPool), shares);
        conversionPool.redeem(shares);
    }

    // =================== VIEW FUNCTIONS  =================== //

    function getUserMaxWithdrawable(address userAddress) external view returns (uint128 maxWithdrawableAmount) {
        User storage user = users[userAddress];
        IExchangeRateFeeder _feeder = conversionPool.feeder();
        maxWithdrawableAmount = (uint256(user.shares) * _feeder.exchangeRateOf(address(inputToken), true) * withdrawSlippage / MULTIPLIER / HUNDRED_PERCENT).toUint128();
        if (userAddress == feeCollector) return maxWithdrawableAmount;

        uint128 yieldRegistered = user.depositedAmount + user.yieldRegistered;
        uint128 yield = maxWithdrawableAmount > yieldRegistered ? maxWithdrawableAmount - yieldRegistered : 0;
        if (yield > 0) {
            uint256 referrerUserFeePercentage = uint256(referrers[user.referrerId].userFee) * (HUNDRED_PERCENT - feePercentage) / HUNDRED_PERCENT;
            uint256 absoluteFeePercentage = feePercentage + referrerUserFeePercentage;
            uint128 fee = (uint256(yield) * absoluteFeePercentage / HUNDRED_PERCENT).toUint128();
            maxWithdrawableAmount -= fee;
        }
    }

    function token() external view returns (IERC20) {
        return inputToken;
    }

    function aUST() external view returns (IERC20) {
        return outputToken;
    }

    function feeder() external view returns (IExchangeRateFeeder) {
        return conversionPool.feeder();
    }
}