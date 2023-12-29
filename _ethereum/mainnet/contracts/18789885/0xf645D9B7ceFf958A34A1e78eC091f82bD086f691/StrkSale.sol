// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AggregatorV3Interface.sol";

import "./WhiteList.sol";

interface IERC20DetailedBytes is IERC20 {
	function name() external view returns (bytes32);

	function symbol() external view returns (bytes32);

	function decimals() external view returns (uint8);
}

/**
 * @title StrkSale
 */
contract StrkSale is ReentrancyGuard, Whitelist {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Number of pools
    uint8 public constant NUMBER_POOLS = 10;

    // Precision
    uint256 public constant PRECISION = 1E18;

    // Offering token decimal
    uint256 public constant OFFERING_DECIMALS = 18;

    // It checks if token is accepted for payment
    mapping(address => bool) public isPaymentToken;
    address[] public allPaymentTokens;

    // It maps the payment token address to price feed address
    mapping(address => address) public priceFeed;
    address public ethPriceFeed;

    // It maps the payment token address to decimal
    mapping(address => uint8) public paymentTokenDecimal;

    // It checks if token is stable coin
    mapping(address => bool) public isStableToken;
    address[] public allStableTokens;

    // The offering token
    IERC20 public offeringToken;

    // Total tokens distributed across the pools
    uint256 public totalTokensOffered;

    // Array of PoolCharacteristics of size NUMBER_POOLS
    PoolCharacteristics[NUMBER_POOLS] private _poolInformation;

    // It maps the address to pool id to UserInfo
    mapping(address => mapping(uint8 => UserInfo)) private _userInfo;

    // Struct that contains each pool characteristics
    struct PoolCharacteristics {
        uint256 startTime; // The block timestamp when pool starts
        uint256 endTime; // The block timestamp when pool ends
        uint256 offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
        uint256 soldAmountPoolScaled; // total amount of tokens sold in the pool, scaled by PRECISION
        uint256 minBuyAmount; // min amount of tokens user can buy for every purchase (if 0, it is ignored)
        uint256 limitPerUserInUSD; // USD limit per user to deposit (if 0, it is ignored)
        uint256 usdAmountPool; // total amount deposited in pool (in USD, decimal is 18)
        uint256 shortVestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 longVestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 shortVestingDuration; // Short vesting duration
        uint256 longVestingDuration; // Long vesting duration
        uint256 shortPrice; // token price for short purchase (in USD, decimal is 18)
        uint256 longPrice; // token price for long purchase (in USD, decimal is 18)
        uint256 vestingCliff; // Vesting cliff
        uint256 vestingSlicePeriodSeconds; // Vesting slice period seconds
    }

    // Struct that contains each user information for both pools
    struct UserInfo {
        uint256 usdAmount; // How many USD the user has provided for pool
        bool claimedPool; // Whether the user has claimed (default: false) for pool
        uint256 shortAmountScaled; // Amount of tokens user bought at short vesting price, scaled by PRECISION
        uint256 longAmountScaled; // Amount of tokens user bought at long vesting price, scaled by PRECISION
    }

    enum VestingPlan { Short, Long }

    // vesting startTime, everyone will be started at same timestamp. pid => startTime
    mapping(uint256 => uint256) public vestingStartTime;

    // A flag for vesting is being revoked
    bool public vestingRevoked;

    // Struct that contains vesting schedule
    struct VestingSchedule {
        bool isVestingInitialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // pool id
        uint8 pid;
        // vesting plan
        VestingPlan vestingPlan;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens has been released
        uint256 released;
    }

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    mapping(uint8 => bool) public isWhitelistSale;

    bool public harvestAllowed;

    // Admin withdraw events
    event AdminWithdraw(uint256 amountOfferingToken, uint256 ethAmount, address[] tokens, uint256[] amounts);

    // Admin recovers token
    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

    // Deposit event
    event Deposit(address indexed user, address token, uint256 amount, uint256 usdAmount, uint256 boughtAmount, uint256 plan, uint8 indexed pid);

    // Harvest event
    event Harvest(address indexed user, uint256 offeringAmount, uint8 indexed pid, uint256 plan);

    // Create VestingSchedule event
    event CreateVestingSchedule(address indexed user, uint256 offeringAmount, uint8 indexed pid, uint256 plan, bytes32 vestingScheduleId);

    // Event when parameters are set for one of the pools
    event PoolParametersSet(uint256 offeringAmountPool, uint8 pid);

    // Event when times are set for one of the pools
    event PoolTimeSet(uint8 pid, uint256 startTime, uint256 endTime);

    // Event when offering amount is set for one of the pools
    event PoolOfferingAmountSet(uint8 pid, uint256 offeringAmount);

    // Event when released new amount
    event Released(bytes32 vestingSchedulesId, address indexed beneficiary, uint256 amount);

    // Event when revoked
    event Revoked();

    // Event when payment token added
    event PaymentTokenAdded(address token, address feed, uint8 decimal);

    // Event when payment token revoked
    event PaymentTokenRevoked(address token);

    // Event when stable token added
    event StableTokenAdded(address token, uint8 decimal);

    // Event when stable token revoked
    event StableTokenRevoked(address token);

    // Event when whitelist sale status flipped
    event WhitelistSaleFlipped(uint8 pid, bool current);

    // Event when harvest enabled status flipped
    event HarvestAllowedFlipped(bool current);

    // Event when offering token is set
    event OfferingTokenSet(address tokenAddress);

    // Modifier to prevent contracts to participate
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    // Modifier to check payment method
    modifier checkPayment(address token) {
        if (token != address(0)) {
            require(
                (
                    isStableToken[token] ||
                    (isPaymentToken[token] && priceFeed[token] != address(0))
                ) &&
                paymentTokenDecimal[token] > 0,
                "invalid token"
            );
        } else {
            require(ethPriceFeed != address(0), "price feed not set");
        }
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    /**
     * @notice Constructor
     */
    constructor(address _ethPriceFeed) public {
        (, int256 price, , , ) = AggregatorV3Interface(_ethPriceFeed).latestRoundData();
        require(price > 0, "invalid price feed");

        ethPriceFeed = _ethPriceFeed;
    }

    /**
     * @notice It allows users to deposit LP tokens to pool
     * @param _pid: pool id
     * @param _token: payment token
     * @param _amount: the number of payment token being deposited
     * @param _minUsdAmount: minimum USD amount that must be converted from deposit token not to revert
     * @param _plan: vesting plan
     * @param _deadline: unix timestamp after which the transaction will revert
     */
    function depositPool(uint8 _pid, address _token, uint256 _amount, uint256 _minUsdAmount, VestingPlan _plan, uint256 _deadline) external payable nonReentrant notContract ensure(_deadline) {
        // Checks whether the pool id is valid
        require(_pid < NUMBER_POOLS, "Deposit: Non valid pool id");

        // Checks that pool was set
        require(_poolInformation[_pid].offeringAmountPool > 0, "Deposit: Pool not set");

        // Checks whether the block timestamp is not too early
        require(block.timestamp > _poolInformation[_pid].startTime, "Deposit: Too early");

        // Checks whether the block timestamp is not too late
        require(block.timestamp < _poolInformation[_pid].endTime, "Deposit: Too late");

        if(_token == address(0)) {
            _amount = msg.value;
        }
        // Checks that the amount deposited is not inferior to 0
        require(_amount > 0, "Deposit: Amount must be > 0");

        require(
            !isWhitelistSale[_pid] || _isQualifiedWhitelist(msg.sender),
            "Deposit: Must be whitelisted"
        );

        if (_token != address(0)) {
            // Transfers funds to this contract
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        (uint256 usdAmount, uint256 offeringAmountScaled) = computeAmounts(_token, _amount, _pid, _plan);
        require(usdAmount >= _minUsdAmount, 'Deposit: Insufficient USD amount');
        require(offeringAmountScaled >= _poolInformation[_pid].minBuyAmount.mul(PRECISION), 'Deposit: too small');
        // Update the user status
        _userInfo[msg.sender][_pid].usdAmount = _userInfo[msg.sender][_pid].usdAmount.add(usdAmount);
        if (_plan == VestingPlan.Short) {
            _userInfo[msg.sender][_pid].shortAmountScaled = _userInfo[msg.sender][_pid].shortAmountScaled.add(offeringAmountScaled);
        } else if (_plan == VestingPlan.Long) {
            _userInfo[msg.sender][_pid].longAmountScaled = _userInfo[msg.sender][_pid].longAmountScaled.add(offeringAmountScaled);
        }

        // Check if the pool has a limit per user
        if (_poolInformation[_pid].limitPerUserInUSD > 0) {
            // Checks whether the limit has been reached
            require(
                _userInfo[msg.sender][_pid].usdAmount <= _poolInformation[_pid].limitPerUserInUSD,
                "Deposit: New amount above user limit"
            );
        }

        // Updates total amount info for pool
        _poolInformation[_pid].usdAmountPool = _poolInformation[_pid].usdAmountPool.add(usdAmount);
        _poolInformation[_pid].soldAmountPoolScaled = _poolInformation[_pid].soldAmountPoolScaled.add(offeringAmountScaled);
        require(
            _poolInformation[_pid].soldAmountPoolScaled <= _poolInformation[_pid].offeringAmountPool.mul(PRECISION),
            "Deposit: Exceed pool offering amount"
        );

        emit Deposit(msg.sender, _token, _amount, usdAmount, offeringAmountScaled, uint256(_plan), _pid);
    }

    /**
     * @notice It allows users to harvest from pool
     * @param _pid: pool id
     */
    function harvestPool(uint8 _pid) external nonReentrant notContract {
        require(harvestAllowed, "Harvest: Not allowed");
        // Checks whether it is too early to harvest
        require(block.timestamp > _poolInformation[_pid].endTime, "Harvest: Too early");

        // Checks whether pool id is valid
        require(_pid < NUMBER_POOLS, "Harvest: Non valid pool id");

        // Checks whether the user has participated
        require(_userInfo[msg.sender][_pid].usdAmount > 0, "Harvest: Did not participate");

        // Checks whether the user has already harvested
        require(!_userInfo[msg.sender][_pid].claimedPool, "Harvest: Already done");

        // Updates the harvest status
        _userInfo[msg.sender][_pid].claimedPool = true;

        // Updates the vesting startTime
        if (vestingStartTime[_pid] == 0) {
            vestingStartTime[_pid] = block.timestamp;
        }

        // Transfer these tokens back to the user if quantity > 0
        if (_userInfo[msg.sender][_pid].shortAmountScaled > 0) {
            if (100 - _poolInformation[_pid].shortVestingPercentage > 0) {
                uint256 amount = _userInfo[msg.sender][_pid].shortAmountScaled.mul(100 - _poolInformation[_pid].shortVestingPercentage).div(100).div(PRECISION);

                // Transfer the tokens at TGE
                offeringToken.safeTransfer(msg.sender, amount);

                emit Harvest(msg.sender, amount, _pid, uint256(VestingPlan.Short));
            }
            // If this pool is Vesting modal, create a VestingSchedule for each user
            if (_poolInformation[_pid].shortVestingPercentage > 0) {
                uint256 amount = _userInfo[msg.sender][_pid].shortAmountScaled.mul(_poolInformation[_pid].shortVestingPercentage).div(100).div(PRECISION);

                // Create VestingSchedule object
                bytes32 vestingScheduleId = _createVestingSchedule(msg.sender, _pid, VestingPlan.Short, amount);

                emit CreateVestingSchedule(msg.sender, amount, _pid, uint256(VestingPlan.Short), vestingScheduleId);
            }
        }

        if (_userInfo[msg.sender][_pid].longAmountScaled > 0) {
            if (100 - _poolInformation[_pid].longVestingPercentage > 0) {
                uint256 amount = _userInfo[msg.sender][_pid].longAmountScaled.mul(100 - _poolInformation[_pid].longVestingPercentage).div(100).div(PRECISION);

                // Transfer the tokens at TGE
                offeringToken.safeTransfer(msg.sender, amount);

                emit Harvest(msg.sender, amount, _pid, uint256(VestingPlan.Long));
            }
            // If this pool is Vesting modal, create a VestingSchedule for each user
            if (_poolInformation[_pid].longVestingPercentage > 0) {
                uint256 amount = _userInfo[msg.sender][_pid].longAmountScaled.mul(_poolInformation[_pid].longVestingPercentage).div(100).div(PRECISION);

                // Create VestingSchedule object
                bytes32 vestingScheduleId =  _createVestingSchedule(msg.sender, _pid, VestingPlan.Long, amount);

                emit CreateVestingSchedule(msg.sender, amount, _pid, uint256(VestingPlan.Long), vestingScheduleId);
            }
        }
    }

    /**
     * @notice It allows the admin to withdraw funds
     * @param _tokens: payment token addresses
     * @param _offerAmount: the number of offering amount to withdraw
     * @dev This function is only callable by admin.
     */
    function finalWithdraw(address[] calldata _tokens, uint256 _offerAmount) external onlyOwner {
        if (_offerAmount > 0) {
            offeringToken.safeTransfer(msg.sender, _offerAmount);
        }

        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);

        uint256[] memory _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = IERC20(_tokens[i]).balanceOf(address(this));
            if (_amounts[i] > 0) {
                IERC20(_tokens[i]).safeTransfer(msg.sender, _amounts[i]);
            }
        }

        emit AdminWithdraw(_offerAmount, ethBalance, _tokens, _amounts);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(!isPaymentToken[_tokenAddress] && !isStableToken[_tokenAddress], "Recover: Cannot be payment token");
        require(_tokenAddress != address(offeringToken), "Recover: Cannot be offering token");

        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice It allows the admin to set offering token before sale start
     * @param _tokenAddress: the address of offering token
     * @dev This function is only callable by admin.
     */
    function setOfferingToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "OfferingToken: Zero address");
        require(address(offeringToken) == address(0), "OfferingToken: already set");

        offeringToken = IERC20(_tokenAddress);

        emit OfferingTokenSet(_tokenAddress);
    }

    struct PoolSetParams {
        uint8 _pid; // pool id
        uint256 _startTime; // The block timestamp when pool starts
        uint256 _endTime; // The block timestamp when pool ends
        uint256 _offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
        uint256 _minBuyAmount; // min amount of tokens user can buy for every purchase (if 0, it is ignored)
        uint256 _limitPerUserInUSD; // limit of tokens per user (if 0, it is ignored)
        uint256 _shortVestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 _longVestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 _shortVestingDuration; // Short vesting duration
        uint256 _longVestingDuration; // Long vesting duration
        uint256 _shortPrice; // token price for short purchase (in USD, decimal is 18)
        uint256 _longPrice; // token price for long purchase (in USD, decimal is 18)
        uint256 _vestingCliff; // Vesting cliff
        uint256 _vestingSlicePeriodSeconds; // Vesting slice period seconds
    }

    /**
     * @notice It sets parameters for pool
     * @param _poolSetParams: pool set param
     * @dev This function is only callable by admin.
     */
    function setPool(
        PoolSetParams memory _poolSetParams
    ) external onlyOwner {
        require(_poolSetParams._pid < NUMBER_POOLS, "Operations: Pool does not exist");
        require(
            _poolSetParams._shortVestingPercentage >= 0 && _poolSetParams._shortVestingPercentage <= 100,
            "Operations: vesting percentage should exceeds 0 and interior 100"
        );
        require(
            _poolSetParams._longVestingPercentage >= 0 && _poolSetParams._longVestingPercentage <= 100,
            "Operations: vesting percentage should exceeds 0 and interior 100"
        );
        require(_poolSetParams._shortVestingDuration > 0, "duration must exceeds 0");
        require(_poolSetParams._longVestingDuration > 0, "duration must exceeds 0");
        require(_poolSetParams._vestingSlicePeriodSeconds >= 1, "slicePeriodSeconds must be exceeds 1");
        require(_poolSetParams._vestingSlicePeriodSeconds <= _poolSetParams._shortVestingDuration && _poolSetParams._vestingSlicePeriodSeconds <= _poolSetParams._longVestingDuration, "slicePeriodSeconds must be interior duration");
        require(_poolSetParams._endTime > _poolSetParams._startTime, "endTime must bigger than startTime");

        uint8 _pid = _poolSetParams._pid;
        _poolInformation[_pid].startTime = _poolSetParams._startTime;
        _poolInformation[_pid].endTime = _poolSetParams._endTime;
        _poolInformation[_pid].offeringAmountPool = _poolSetParams._offeringAmountPool;
        _poolInformation[_pid].minBuyAmount = _poolSetParams._minBuyAmount;
        _poolInformation[_pid].limitPerUserInUSD = _poolSetParams._limitPerUserInUSD;
        _poolInformation[_pid].shortVestingPercentage = _poolSetParams._shortVestingPercentage;
        _poolInformation[_pid].longVestingPercentage = _poolSetParams._longVestingPercentage;
        _poolInformation[_pid].shortVestingDuration = _poolSetParams._shortVestingDuration;
        _poolInformation[_pid].longVestingDuration = _poolSetParams._longVestingDuration;
        _poolInformation[_pid].shortPrice = _poolSetParams._shortPrice;
        _poolInformation[_pid].longPrice = _poolSetParams._longPrice;
        _poolInformation[_pid].vestingCliff = _poolSetParams._vestingCliff;
        _poolInformation[_pid].vestingSlicePeriodSeconds = _poolSetParams._vestingSlicePeriodSeconds;

        uint256 tokensDistributedAcrossPools;

        for (uint8 i = 0; i < NUMBER_POOLS; i++) {
            tokensDistributedAcrossPools = tokensDistributedAcrossPools.add(_poolInformation[i].offeringAmountPool);
        }

        // Update totalTokensOffered
        totalTokensOffered = tokensDistributedAcrossPools;

        emit PoolParametersSet(_poolSetParams._offeringAmountPool, _pid);
    }

    /**
     * @notice It sets times for pool
     * @param _pid: pool id
     * @dev This function is only callable by admin.
     */
    function setPoolTime(
        uint8 _pid, uint256 _startTime, uint256 _endTime
    ) external onlyOwner {
        require(_pid < NUMBER_POOLS, "Operations: Pool does not exist");
        require(_endTime > _startTime, "endTime must bigger than startTime");

        _poolInformation[_pid].startTime = _startTime;
        _poolInformation[_pid].endTime = _endTime;

        emit PoolTimeSet(_pid, _startTime, _endTime);
    }

    /**
     * @notice It sets offering amount for pool
     * @param _pid: pool id
     * @dev This function is only callable by admin.
     */
    function setPoolOfferingAmount(
        uint8 _pid, uint256 _offeringAmountPool
    ) external onlyOwner {
        require(_pid < NUMBER_POOLS, "Operations: Pool does not exist");

        _poolInformation[_pid].offeringAmountPool = _offeringAmountPool;

        emit PoolOfferingAmountSet(_pid, _offeringAmountPool);
    }

    /**
     * @notice It returns the pool information
     * @param _pid: pool id
     */
    function viewPoolInformation(uint256 _pid)
        external
        view
        returns (PoolCharacteristics memory)
    {
        return _poolInformation[_pid];
    }

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     * @param _pids[]: array of pids
     * @return
     */
    function viewUserAllocationPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allocationPools = new uint256[](_pids.length);
        for (uint8 i = 0; i < _pids.length; i++) {
            allocationPools[i] = _getUserAllocationPool(_user, _pids[i]);
        }
        return allocationPools;
    }

    /**
     * @notice External view function to see user information
     * @param _user: user address
     * @param _pids[]: array of pids
     */
    function viewUserInfo(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory, bool[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);
        bool[] memory statusPools = new bool[](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            amountPools[i] = _userInfo[_user][_pids[i]].usdAmount;
            statusPools[i] = _userInfo[_user][_pids[i]].claimedPool;
        }
        return (amountPools, statusPools);
    }

    struct BoughtTokens {
        uint256 short;
        uint256 long;
    }

    /**
     * @notice External view function to see user offering amounts for pools
     * @param _user: user address
     * @param _pids: array of pids
     */
    function viewUserOfferingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (BoughtTokens[] memory)
    {
        BoughtTokens[] memory amountPools = new BoughtTokens[](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            if (_poolInformation[_pids[i]].soldAmountPoolScaled > 0) {
                amountPools[i].short = _userInfo[_user][_pids[i]].shortAmountScaled;
                amountPools[i].long = _userInfo[_user][_pids[i]].longAmountScaled;
            }
        }
        return amountPools;
    }

    /**
     * @notice Returns the number of vesting schedules associated to a beneficiary
     * @return The number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary) external view returns (uint256) {
        return holdersVestingCount[_beneficiary];
    }

    /**
     * @notice Returns the vesting schedule id at the given index
     * @return The vesting schedule id
     */
    function getVestingScheduleIdAtIndex(uint256 _index) external view returns (bytes32) {
        require(_index < getVestingSchedulesCount(), "index out of bounds");
        return vestingSchedulesIds[_index];
    }

    /**
     * @notice Returns the vesting schedule information of a given holder and index
     * @return The vesting schedule object
     */
    function getVestingScheduleByAddressAndIndex(address _holder, uint256 _index)
        external
        view
        returns (VestingSchedule memory)
    {
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(_holder, _index));
    }

    /**
     * @notice Returns the total amount of vesting schedules
     * @return The vesting schedule total amount
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /**
     * @notice Release vested amount of offering tokens
     * @param _vestingScheduleId the vesting schedule identifier
     */
    function release(bytes32 _vestingScheduleId) external nonReentrant {
        require(vestingSchedules[_vestingScheduleId].isVestingInitialized == true, "vesting schedule is not exist");

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(isBeneficiary || isOwner, "only the beneficiary and owner can release vested tokens");
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount > 0, "no vested tokens to release");
        vestingSchedule.released = vestingSchedule.released.add(vestedAmount);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(vestedAmount);
        offeringToken.safeTransfer(vestingSchedule.beneficiary, vestedAmount);

        emit Released(_vestingScheduleId, vestingSchedule.beneficiary, vestedAmount);
    }

    /**
     * @notice Revokes all the vesting schedules
     */
    function revoke() external onlyOwner {
        require(!vestingRevoked, "vesting is revoked");

        vestingRevoked = true;

        emit Revoked();
    }

    /**
     * @notice Add payment token
     */
    function addPaymentToken(address _token, address _feed, uint8 _decimal) external onlyOwner {
        require(!isPaymentToken[_token], "already added");
        require(_feed != address(0), "invalid feed address");
        require(_decimal == IERC20DetailedBytes(_token).decimals(), "incorrect decimal");

        (, int256 price, , , ) = AggregatorV3Interface(_feed).latestRoundData();
        require(price > 0, "invalid price feed");

        isPaymentToken[_token] = true;
        allPaymentTokens.push(_token);
        priceFeed[_token] = _feed;
        paymentTokenDecimal[_token] = _decimal;

        emit PaymentTokenAdded(_token, _feed, _decimal);
    }

    /**
     * @notice Revoke payment token
     */
    function revokePaymentToken(address _token) external onlyOwner {
        require(isPaymentToken[_token], "not added");

        isPaymentToken[_token] = false;

        uint256 index = allPaymentTokens.length;
        for (uint256 i = 0; i < allPaymentTokens.length; i++) {
            if (allPaymentTokens[i] == _token) {
                index = i;
                break;
            }
        }
        require(index != allPaymentTokens.length, "token doesn't exist");

        allPaymentTokens[index] = allPaymentTokens[allPaymentTokens.length - 1];
        allPaymentTokens.pop();
        delete paymentTokenDecimal[_token];
        delete priceFeed[_token];

        emit PaymentTokenRevoked(_token);
    }

    /**
     * @notice Add stable token
     */
    function addStableToken(address _token, uint8 _decimal) external onlyOwner {
        require(!isStableToken[_token], "already added");
        require(_decimal == IERC20DetailedBytes(_token).decimals(), "incorrect decimal");

        isStableToken[_token] = true;
        allStableTokens.push(_token);
        paymentTokenDecimal[_token] = _decimal;

        emit StableTokenAdded(_token, _decimal);
    }

    /**
     * @notice Revoke stable token
     */
    function revokeStableToken(address _token) external onlyOwner {
        require(isStableToken[_token], "not added");

        isStableToken[_token] = false;

        uint256 index = allStableTokens.length;
        for (uint256 i = 0; i < allStableTokens.length; i++) {
            if (allStableTokens[i] == _token) {
                index = i;
                break;
            }
        }
        require(index != allStableTokens.length, "token doesn't exist");

        allStableTokens[index] = allStableTokens[allStableTokens.length - 1];
        allStableTokens.pop();
        delete paymentTokenDecimal[_token];

        emit StableTokenRevoked(_token);
    }

    /**
     * @notice Flip whitelist sale status
     */
    function flipWhitelistSaleStatus(uint8 _pid) external onlyOwner {
        isWhitelistSale[_pid] = !isWhitelistSale[_pid];

        emit WhitelistSaleFlipped(_pid, isWhitelistSale[_pid]);
    }

    /**
     * @notice Flip harvestAllowed status
     */
    function flipHarvestAllowedStatus() external onlyOwner {
        harvestAllowed = !harvestAllowed;

        emit HarvestAllowedFlipped(harvestAllowed);
    }

    /**
     * @notice Returns the number of vesting schedules managed by the contract
     * @return The number of vesting count
     */
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    /**
     * @notice Returns the vested amount of tokens for the given vesting schedule identifier
     * @return The number of vested count
     */
    function computeReleasableAmount(bytes32 _vestingScheduleId) public view returns (uint256) {
        require(vestingSchedules[_vestingScheduleId].isVestingInitialized == true, "vesting schedule is not exist");

        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @notice Returns the vesting schedule information of a given identifier
     * @return The vesting schedule object
     */
    function getVestingSchedule(bytes32 _vestingScheduleId) public view returns (VestingSchedule memory) {
        return vestingSchedules[_vestingScheduleId];
    }

    /**
     * @notice Returns the amount of offering token that can be withdrawn by the owner
     * @return The amount of offering token
     */
    function getWithdrawableOfferingTokenAmount() public view returns (uint256) {
        return offeringToken.balanceOf(address(this)).sub(vestingSchedulesTotalAmount);
    }

    /**
     * @notice Computes the next vesting schedule identifier for a given holder address
     * @return The id string
     */
    function computeNextVestingScheduleIdForHolder(address _holder) public view returns (bytes32) {
        return computeVestingScheduleIdForAddressAndIndex(_holder, holdersVestingCount[_holder]);
    }

    /**
     * @notice Computes the next vesting schedule identifier for an address and an index
     * @return The id string
     */
    function computeVestingScheduleIdForAddressAndIndex(address _holder, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_holder, _index));
    }

    /**
     * @notice Computes the next vesting schedule identifier for an address and an pid
     * @return The id string
     */
    function computeVestingScheduleIdForAddressAndPid(address _holder, uint256 _pid, VestingPlan _plan) external view returns (bytes32) {
        require(_pid < NUMBER_POOLS, "ComputeVestingScheduleId: Non valid pool id");

        for (uint8 i = 0; i < NUMBER_POOLS * 2; i++) {
            bytes32 vestingScheduleId = computeVestingScheduleIdForAddressAndIndex(_holder, i);
            VestingSchedule memory vestingSchedule = vestingSchedules[vestingScheduleId];
            if (vestingSchedule.isVestingInitialized == true && vestingSchedule.pid == _pid && vestingSchedule.vestingPlan == _plan) {
                return vestingScheduleId;
            }
        }

        return computeNextVestingScheduleIdForHolder(_holder);
    }

    /**
     * @notice Get current Time
     */
    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Computes the releasable amount of tokens for a vesting schedule
     * @return The amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory _vestingSchedule) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if (currentTime < vestingStartTime[_vestingSchedule.pid] + _poolInformation[_vestingSchedule.pid].vestingCliff) {
            return 0;
        } else if (
            (_vestingSchedule.vestingPlan == VestingPlan.Short && currentTime >= vestingStartTime[_vestingSchedule.pid].add(_poolInformation[_vestingSchedule.pid].shortVestingDuration)) ||
            (_vestingSchedule.vestingPlan == VestingPlan.Long && currentTime >= vestingStartTime[_vestingSchedule.pid].add(_poolInformation[_vestingSchedule.pid].longVestingDuration)) ||
            vestingRevoked
        ) {
            return _vestingSchedule.amountTotal.sub(_vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingStartTime[_vestingSchedule.pid]);
            uint256 secondsPerSlice = _poolInformation[_vestingSchedule.pid].vestingSlicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = _vestingSchedule.amountTotal.mul(vestedSeconds).div(
                _vestingSchedule.vestingPlan == VestingPlan.Short ? _poolInformation[_vestingSchedule.pid].shortVestingDuration : _poolInformation[_vestingSchedule.pid].longVestingDuration
            );
            vestedAmount = vestedAmount.sub(_vestingSchedule.released);
            return vestedAmount;
        }
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _pid the pool id
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function _createVestingSchedule(
        address _beneficiary,
        uint8 _pid,
        VestingPlan _plan,
        uint256 _amount
    ) internal returns (bytes32) {
        require(
            getWithdrawableOfferingTokenAmount() >= _amount,
            "can not create vesting schedule with sufficient tokens"
        );

        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(_beneficiary);
        require(vestingSchedules[vestingScheduleId].beneficiary == address(0), "vestingScheduleId is been created");
        vestingSchedules[vestingScheduleId] = VestingSchedule(true, _beneficiary, _pid, _plan, _amount, 0);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
        vestingSchedulesIds.push(vestingScheduleId);
        holdersVestingCount[_beneficiary]++;
        return vestingScheduleId;
    }

    /**
     * @notice It returns the user allocation for pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _user: user address
     * @param _pid: pool id
     * @return It returns the user's share of pool
     */
    function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
        if (_poolInformation[_pid].usdAmountPool > 0) {
            return _userInfo[_user][_pid].usdAmount.mul(1e12).div(_poolInformation[_pid].usdAmountPool);
        } else {
            return 0;
        }
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function isQualifiedWhitelist(address _user) external view returns (bool) {
        return isWhitelisted(_user);
    }

    function _isQualifiedWhitelist(address _user) internal view returns (bool) {
        return isWhitelisted(_user);
    }

    /**
     * @notice Computes the USD amount and offering token amount from token amount
     * @return usdAmount USD amount, decimal is 18
     * @return offeringAmountScaled offering amount, scaled by PRECISION
     */
    function computeAmounts(address token, uint256 amount, uint8 pid, VestingPlan plan) public view checkPayment(token) returns (uint256 usdAmount, uint256 offeringAmountScaled) {
        uint256 tokenDecimal = token == address(0) ? 18 : uint256(paymentTokenDecimal[token]);

        if (isStableToken[token]) {
            usdAmount = amount.mul(PRECISION).div(10 ** tokenDecimal);
        } else {
            address feed = token == address(0) ? ethPriceFeed : priceFeed[token];
            (, int256 price, , , ) = AggregatorV3Interface(feed).latestRoundData();
            require(price > 0, "ChainlinkPriceFeed: invalid price");
            uint256 priceDecimal = uint256(AggregatorV3Interface(feed).decimals());

            usdAmount = amount.mul(uint256(price)).mul(PRECISION).div(10 ** (priceDecimal + tokenDecimal));
        }

        require(_poolInformation[pid].offeringAmountPool > 0, "ComputeAmounts: Pool not set");
        uint256 offeringTokenPrice = plan == VestingPlan.Short ? _poolInformation[pid].shortPrice : _poolInformation[pid].longPrice;
        offeringAmountScaled = usdAmount.mul(10 ** OFFERING_DECIMALS).mul(PRECISION).div(offeringTokenPrice);
    }
}
