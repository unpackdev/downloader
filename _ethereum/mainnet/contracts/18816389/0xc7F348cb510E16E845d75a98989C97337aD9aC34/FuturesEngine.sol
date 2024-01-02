// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./SafeERC20.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./IReferralReport.sol";
import "./ITreasury.sol";
import "./INpYieldEngine.sol";
import "./IReferralRegistry.sol";
import "./IUserHook.sol";

import "./SafeMath.sol";
import "./NpPausable.sol";
import "./FutureStructs.sol";

contract FuturesEngine is UUPSUpgradeable, NpPausable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IReferralReport {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //Financial Model
    uint256 public constant referenceApr = 182.5e6; //0.5% daily
    uint256 public constant maxBalance = 1000000e6; //1M
    uint256 public constant minimumDeposit = 200e6; //200+ deposits; will compound available rewards
    uint256 public constant maxAvailable = 50000e6; //50K max claim daily, 10 days missed claims
    uint256 public constant maxPayouts = 2500000e6; //2.5M
    uint256 public constant ratioPrecision = 10000;

    //Immutable long term network contracts
    ITreasury public collateralBufferPool;
    ITreasury public collateralTreasury;
    ITreasury public collateralExtraPool;
    IERC20 public collateralToken;

    //Updatable components
    INpYieldEngine public yieldEngine;
    IReferralRegistry public registry;

    mapping(address => FuturesUser) private users; //Asset -> User

    uint256 public treasuryRatio;
    uint256 public extraRatio;
    uint256 public referrerRatio;

    address[] public userHooks;
    bool public enforceMinimum;
    bool public enforceReferrer;

    //events
    event Deposit(address indexed user, uint256 amount);
    event CompoundDeposit(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event Transfer(address indexed user, address indexed new_user, uint256 current_balance);
    event RewardDistribution(address indexed referrer, uint256 reward);
    event DepositReward(address indexed user, uint256 amount);
    event UpdateYieldEngine(address prev_engine, address engine);
    event UpdateVault(address prev_vault, address vault);

    //@dev Creates a FuturesEngine that contains upgradeable business logic for Futures Vault
    constructor() {
        _disableInitializers();
    }

    function initialize(address _collateral, address _treasury, address _buffer, address _extra,address _reg, address _engine) external initializer {
        //setup the core tokens
        collateralToken = IERC20(_collateral);

        //treasury setup
        collateralTreasury = ITreasury(_treasury);
        collateralBufferPool = ITreasury(_buffer);
        collateralExtraPool = ITreasury(_extra);

        registry = IReferralRegistry(_reg);

        enforceMinimum = true;
        enforceReferrer = true;

        treasuryRatio = 8600;
        extraRatio = 400;
        referrerRatio = 100;

        yieldEngine = INpYieldEngine(_engine);

        __Ownable_init(_msgSender());
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function clearHook() external onlyOwner {
        delete userHooks;
    }

    function addHook(address hook) external onlyOwner {
        require(hook != address(0), "hook cannot be zero");
        userHooks.push(hook);
    }

    function hookLength() external view returns (uint256) {
        return userHooks.length;
    }

    function callHooks(address _user, FuturesUser memory _user_data) internal {
        unchecked {
            for (uint256 i; i < userHooks.length; ++i) {
                IUserHook(userHooks[i]).updateUser(_user, _user_data);
            }
        }
    }

    //Administrative//

    function setTreasuryRatio(uint256 _ratio) external onlyOwner {
        treasuryRatio = _ratio;
    }

    function setExtraRatio(uint256 _ratio) external onlyOwner {
        extraRatio = _ratio;
    }

    function setReferrerRatio(uint256 _ratio) external onlyOwner {
        referrerRatio = _ratio;
    }

    function setPause(bool _p) external onlyOwner {
        _setPause(_p);
    }

    function updateEnforceMinimum(bool _enforceMinimum) external onlyOwner {
        enforceMinimum = _enforceMinimum;
    }

    function updateEnforceReferrer(bool _enforce) external onlyOwner {
        enforceReferrer = _enforce;
    }

    //@dev Update the farm engine which is used for quotes, yield calculations / distribution
    function updateYieldEngine(address _engine) external onlyOwner {
        require(_engine != address(0), "engine must be non-zero");

        emit UpdateYieldEngine(address(yieldEngine), _engine);

        yieldEngine = INpYieldEngine(_engine);
    }

    ///  Views  ///

    //@dev Get User info
    function getUser(address _user) external view returns (FuturesUser memory) {
        return users[_user];
    }

    ////  User Functions ////

    function depositWithReferrer(uint _amount, address _referrer) external {
        if (_referrer != address(0) && registry.referrerOf(msg.sender) == address(0)) {
            registry.setReferrerProtocol(msg.sender, _referrer);
        }
        _deposit(msg.sender, _amount);
    }

    //@dev Deposit BUSD in exchange for TRUNK at the current TWAP price
    //Is not available if the system is paused
    function _deposit(address _user, uint _amount) internal whenNotPaused nonReentrant {
        address referrer = registry.referrerOf(_user);
        require(!enforceReferrer || referrer != address(0), "no referrer");
        //Only the key holder can invest their funds
        require(_amount >= minimumDeposit || enforceMinimum == false, "amount less than minimum deposit");

        uint _share = _amount / ratioPrecision;

        //90% goes directly to the treasury

        uint _treasuryAmount = _share * treasuryRatio;
        uint _extraAmount = _share * extraRatio;
        uint _bufferAmount = _amount - _treasuryAmount - _extraAmount;

        //Transfer USD to the USD Treasury
        collateralToken.safeTransferFrom(_user, address(collateralTreasury), _treasuryAmount);

        //Transfer USD to Extra Pool
        collateralToken.safeTransferFrom(_user, address(collateralExtraPool), _extraAmount);

        //Transfer to Bufferpool
        collateralToken.safeTransferFrom(_user, address(collateralBufferPool), _bufferAmount);

        //Give additional amount to referrer
        uint _referrerAmount = _share * referrerRatio;
        _distReferralReward(referrer, _referrerAmount);

        FuturesUser memory userData = users[_user];
        _depositInternal(_user, _amount, userData);

        //events
        emit Deposit(_user, _amount);
    }

    function _depositInternal(address _user, uint _amount, FuturesUser memory userData) internal {
        require(userData.current_balance + _amount <= maxBalance, "max balance exceeded");
        require(userData.payouts <= maxPayouts, "max payouts exceeded");

        //if user has an existing balance see if we have to claim yield before proceeding
        //optimistically claim yield before reset
        //if there is a balance we potentially have yield
        if (userData.current_balance > 0) {
            compoundYield(_user, userData);
        }

        //update user
        userData.deposits += _amount;
        userData.last_time = block.timestamp;
        userData.current_balance += _amount;

        users[_user] = userData;
        callHooks(_user, userData);
    }

    function depositReward() external {
        address _user = msg.sender;
        FuturesUser memory userData = users[_user];
        uint256 amount = userData.rewards;
        require(amount >= minimumDeposit || enforceMinimum == false, "amount less than minimum deposit");

        _depositInternal(_user, amount, userData);
        userData.rewards = 0;
        users[_user] = userData;

        emit DepositReward(_user, amount);
    }

    //@dev Claims earned interest for the caller
    function claim() external nonReentrant returns (bool success) {
        //Only the owner of funds can claim funds
        address _user = msg.sender;

        FuturesUser memory userData = users[_user];

        //checks
        require(userData.current_balance > 0, "balance is required to earn yield");

        success = distributeYield(_user, userData);
    }

    function _distReferralReward(address _referrer, uint _amount) internal {
        users[_referrer].rewards += _amount;
        emit RewardDistribution(_referrer, _amount);
    }

    function distributeReferrerReward(address _referrer, uint _amount) public {
        require(msg.sender == address(yieldEngine), "caller must be registered yield engine");
        _distReferralReward(_referrer, _amount);
    }

    function available(address _user) public view returns (uint256 _limiterRate, uint256 _adjustedAmount) {
        return _available(users[_user]);
    }

    //@dev Returns tax bracket and adjusted amount based on the bracket
    function _available(FuturesUser memory userData) internal view returns (uint256 _limiterRate, uint256 _adjustedAmount) {
        if (userData.current_balance > 0) {
            _adjustedAmount = (userData.current_balance * referenceApr * block.timestamp.safeSub(userData.last_time)) / (365 * 100e6) / 24 hours;

            //payout is asymptotic and uses the current balance //convert to daily apr
            _adjustedAmount = maxAvailable.min(_adjustedAmount); //minimize red candles
        }

        //apply compound rate limiter
        uint256 _comp_surplus = userData.compound_deposits.safeSub(userData.deposits);

        if (_comp_surplus < 50000e6) {
            _limiterRate = 0;
        } else if (50000e6 <= _comp_surplus && _comp_surplus < 250000e6) {
            _limiterRate = 10;
        } else if (250000e6 <= _comp_surplus && _comp_surplus < 500000e6) {
            _limiterRate = 15;
        } else if (500000e6 <= _comp_surplus && _comp_surplus < 750000e6) {
            _limiterRate = 25;
        } else if (750000e6 <= _comp_surplus && _comp_surplus < 1000000e6) {
            _limiterRate = 35;
        } else if (_comp_surplus >= 1000000e6) {
            _limiterRate = 50;
        }

        _adjustedAmount = (_adjustedAmount * (100 - _limiterRate)) / 100;

        // payout greater than the balance just pay the balance
        if (_adjustedAmount > userData.current_balance) {
            _adjustedAmount = userData.current_balance;
        }
    }

    //   Internal Functions  //

    //@dev Checks if yield is available and distributes before performing additional operations
    //distributes only when yield is positive
    //inputs are validated by external facing functions
    function distributeYield(address _user, FuturesUser memory userData) private returns (bool success) {
        //get available
        (, uint256 _amount) = _available(userData);

        // payout remaining allowable divs if exceeds
        if (userData.payouts + _amount > maxPayouts) {
            _amount = maxPayouts.safeSub(userData.payouts);
            _amount = _amount.min(userData.current_balance); //withdraw up to the current balance
        }

        //attempt to payout yield and update stats;
        if (_amount > 0) {
            //transfer amount to user; mutable
            _amount = yieldEngine.yield(_user, _amount);

            if (_amount > 0) {
                //second check with delivered yield
                //user stats
                userData.payouts += _amount;
                userData.current_balance = userData.current_balance.safeSub(_amount);
                userData.last_time = block.timestamp;

                //commit updates
                users[_user] = userData;
                callHooks(_user, userData);

                //log events
                emit Claim(_user, _amount);

                return true;
            }
        }

        //default
        return false;
    }

    //@dev Checks if yield is available and compound before performing additional operations
    //compound only when yield is positive
    function compoundYield(address _user, FuturesUser memory userData) private {
        //get available
        (, uint256 _amount) = _available(userData);

        // payout remaining allowable divs if exceeds
        if (userData.payouts + _amount > maxPayouts) {
            _amount = maxPayouts.safeSub(userData.payouts);
        }

        //attempt to compound yield and update stats;
        if (_amount > 0) {
            //user stats
            // userData.deposits += 0; //compounding is not a deposit; here for clarity
            userData.compound_deposits += _amount;
            userData.payouts += _amount;
            userData.current_balance += _amount;

            //log events
            emit CompoundDeposit(_user, _amount);
        }
    }

    //@dev Transfer account to another wallet address
    function transfer(address _newUser) external nonReentrant {
        address _user = msg.sender;

        FuturesUser memory userData = users[_user];
        FuturesUser memory newData = users[_newUser];

        //Only the owner can transfer
        require(newData.last_time == 0 && _newUser != address(0), "new address must not exist");

        //Transfer
        newData.deposits = userData.deposits;
        newData.current_balance = userData.current_balance;
        newData.payouts = userData.payouts;
        newData.compound_deposits = userData.compound_deposits;
        newData.rewards = userData.rewards;
        newData.last_time = userData.last_time;

        //Zero out old account
        userData.deposits = 0;
        userData.current_balance = 0;
        userData.compound_deposits = 0;
        userData.payouts = 0;
        userData.rewards = 0;
        userData.last_time = 0;

        //commit
        users[_user] = userData;
        users[_newUser] = newData;

        callHooks(_user, userData);
        callHooks(_newUser, newData);

        //log
        emit Transfer(_user, _newUser, newData.current_balance);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
