// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IStrategyCalculations.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./AggregatorV3Interface.sol";
import "./IConvex.sol";
import "./IStrategyConvex.sol";
import "./IGaugeFactory.sol";
import "./ICurveSwap.sol";
import "./StratFeeManager.sol";
import "./IQuoter.sol";
import "./IERC20.sol";
import "./UniV3Actions.sol";
import "./IWETH.sol";

/// @title StrategyConvexTricryptoNativeL1
/// @notice The StrategyConvexBicryptoL2 contract is a crucial component of a project focused on optimizing
/// yield farming on Convex Finance. It facilitates the management of a strategy by interacting with
/// external contracts, such as a Convex booster, a calculations contract, and a Curve swap pool. The contract
/// allows users to deposit funds, claim rewards, and perform harvesting operations. It supports multiple tokens
/// for deposit and incorporates checks and validations to ensure secure operations. With features like token
/// swapping and reinvestment strategies, the contract helps users maximize their yields and earn rewards effectively.
contract StrategyConvexTricryptoNativeL1 is IStrategyConvex, StratFeeManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant POOL_SIZE = 3; // Curve's pool size

    /// @notice Address of the booster contract
    IConvexBoosterL1 public booster;
    /// @notice Address of the calculations contract
    IStrategyCalculations public calculations;
    bool public isPanicActive; // True if panic is active
    address public want; // Curve LP Token
    address public pool; // Curve swap pool
    address public depositToken; // Token used to reinvest in harvest
    address public weth; //  Wrapped Ether token
    address public rewardPool; // Convex base reward pool
    uint256 public pid; // Convex booster poolId
    uint256 public depositIndex; // Index of depositToken in pool
    uint256 public lastHarvest; // Last timestamp when the harvest occurred
    uint256 public totalWantDeposits; // Total of deposits in Curve LP
    uint256 public defaultSlippageCurve; // Curve slippage used in harvest
    uint256 public defaultSlippageUniswap; // Uniswap slippage used in harvest
    mapping(address => uint256) public userWantDeposit; // Total user deposited in Curve LP
    mapping(address => uint256) public minimumToHarvest; // Minimum amount to execute reinvestment in harvest
    mapping(address => mapping(address => bytes)) public paths; // From => To returns path for Uniswap
    mapping(address => AggregatorV3Interface) public oracle; // Price oracle for a token
    mapping(address => PoolToken) public allowedDepositTokens; // Indicates what token is allowed
    address[] private rewardTokens; // List of the reward tokens
    address[] public listAllowedDepositTokens; // List of the allowed tokens

    /// @param want The address of the curve lpToken
    /// @param pool The address of the curve swap pool
    /// @param booster The address of the Convex booster contract
    /// @param pid The pool ID of the Convex booster
    /// @param depositToken The token sent to the pool to receive want
    /// @param oracles The array of oracle token and oracle address pairs
    /// @param depositIndex Deposit index parameter
    /// @param defaultSlippages The default slippages for curve and Uniswap
    /// @param rewardInfo The reward token addresses and minimum amounts for rewards
    /// @param commonAddresses The addresses of common contracts
    struct InitParams {
        address want;
        address pool;
        address booster;
        uint256 pid;
        address depositToken;
        address weth;
        Oracle[] oracles;
        uint256 depositIndex;
        DefaultSlippages defaultSlippages;
        RewardInfo rewardInfo;
        CommonAddresses commonAddresses;
    }

    /// @dev Modifier to restrict access to vault only.
    modifier onlyVault() {
        require(msg.sender == vault, "InvalidCaller");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param _initParams Initialization parameters
    function initialize(InitParams calldata _initParams) public initializer {
        __StratFeeManager_init(_initParams.commonAddresses);

        require(_initParams.want != address(0), "ZeroWant");
        require(_initParams.pool != address(0), "ZeroPool");
        require(_initParams.booster != address(0), "ZeroBooster");
        require(_initParams.depositToken != address(0), "ZeroDeposit");
        require(_initParams.weth != address(0), "ZeroWeth");
        require(ONE_HUNDRED >= _initParams.defaultSlippages.curve, "InvalidDefaultSlippageCurve");
        require(
            ONE_HUNDRED >= _initParams.defaultSlippages.uniswap,
            "InvalidDefaultSlippageUniswap"
        );

        for (uint256 i; i < _initParams.oracles.length; i++) {
            require(_initParams.oracles[i].token != address(0), "ZeroOracleToken");
            require(_initParams.oracles[i].oracle != address(0), "ZeroOracleOracle");

            oracle[_initParams.oracles[i].token] = AggregatorV3Interface(
                _initParams.oracles[i].oracle
            );
        }

        defaultSlippageCurve = _initParams.defaultSlippages.curve;
        defaultSlippageUniswap = _initParams.defaultSlippages.uniswap;
        (want, pool, pid, depositToken, weth) = (
            _initParams.want,
            _initParams.pool,
            _initParams.pid,
            _initParams.depositToken,
            _initParams.weth
        );
        booster = IConvexBoosterL1(_initParams.booster);
        depositIndex = _initParams.depositIndex;
        (, , , rewardPool, , ) = booster.poolInfo(_initParams.pid);

        _addRewardToken(_initParams.rewardInfo.tokens, _initParams.rewardInfo.minAmount);

        // Adding valid tokens
        for (uint256 i; i < POOL_SIZE; i++) {
            address coin = ICurveSwap(_initParams.pool).coins(i);
            allowedDepositTokens[coin] = PoolToken(true, uint8(i));
            listAllowedDepositTokens.push(coin);
        }

        _modifyAllowances(type(uint).max);
    }

    /// @dev Allows this contract to receive native token
    receive() external payable {}

    /// @notice Deposits funds into the strategy
    /// @dev Only the vault contract can call this function
    /// @param _token The address of the token to deposit
    /// @param _amount Amount of tokens to deposit
    /// @param _user The address of the user making the deposit
    /// @param _minWant The minimum amount of want tokens to get from the curve deposit
    function deposit(
        address _token,
        uint256 _amount,
        address _user,
        uint256 _minWant
    ) external payable whenNotPaused onlyVault {
        require(allowedDepositTokens[_token].isAllowed, "TokenNotAllowed");
        uint256 wantBefore = balanceOfWant();
        _addLiquidityCurve(_token, _amount, _minWant);
        uint256 depositedWant = balanceOfWant() - wantBefore;
        userWantDeposit[_user] += depositedWant;
        totalWantDeposits += depositedWant;
        _addLiquidityConvex();
        emit Deposit(_user, _token, depositedWant);
    }

    /// @notice Withdraws funds from the strategy
    /// @dev Only the vault contract can call this function
    /// @param _user The address of the user making the withdrawal
    /// @param _amount The amount to withdraw
    /// @param _token The address of the token to withdraw
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve
    /// @param _useEth Indicates whether to withdraw ETH or not
    function withdraw(
        address _user,
        uint256 _amount,
        address _token,
        uint256 _minCurveOutput,
        bool _useEth
    ) external onlyVault {
        PoolToken memory poolToken = allowedDepositTokens[_token];
        require(poolToken.isAllowed, "TokenNotAllowed");
        uint256 wantBal = balanceOfWant();
        if (wantBal < _amount) {
            IConvexRewardPoolL1(rewardPool).withdrawAndUnwrap(_amount - wantBal, false);
            wantBal = balanceOfWant();
        }
        if (wantBal > _amount) wantBal = _amount;

        uint256 beforeTokenBal = _getTokenBalance(_token);
        ICurveSwap(pool).remove_liquidity_one_coin(wantBal, poolToken.index, _minCurveOutput);
        // Subtracts to the user deposit
        uint256 tokenBal = _getTokenBalance(_token) - beforeTokenBal;
        uint256 _userDeposit = userWantDeposit[_user];
        userWantDeposit[_user] = 0;
        totalWantDeposits -= _userDeposit;
        // Calculates percentage of fees
        uint256 _rewards = 0;
        if (_userDeposit < wantBal) {
            uint256 rewardsPercentage = ((wantBal - _userDeposit) * 1e18) / wantBal;
            _rewards = (tokenBal * rewardsPercentage) / 1e18;
        }

        uint256 _depositMinusRewards = tokenBal - _rewards;

        tokenBal -= chargeFees(FeeType.PERFORMANCE, _token, _rewards);
        tokenBal -= chargeFees(FeeType.MANAGEMENT, _token, _depositMinusRewards);

        // Sends tokens
        if (_useEth) {
            IWETH(_token).withdraw(tokenBal);

            (bool _sucess, ) = payable(_user).call{ value: tokenBal }("");

            if (!_sucess) revert("TransferFailed");
        } else {
            IERC20Upgradeable(_token).safeTransfer(_user, tokenBal);
        }

        emit Withdraw(_user, _token, tokenBal, balanceOf());
    }

    /// @notice Claims rewards for a user
    /// @dev Only the vault contract can call this function
    /// @param _user The address of the user claiming rewards
    /// @param _token The address of the token to receive rewards
    /// @param _amount The amount of tokens to claim as rewards
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve
    /// @param _useEth Indicates whether to withdraw ETH or not
    function claimRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _minCurveOutput,
        bool _useEth
    ) external onlyVault {
        PoolToken memory poolToken = allowedDepositTokens[_token];
        require(poolToken.isAllowed, "TokenNotAllowed");
        uint256 _userDeposit = userWantDeposit[_user];
        require(_userDeposit > 0, "InsufficientDeposit");
        require(_amount > _userDeposit, "ZeroRewards");
        uint256 rewardAmount = _amount - _userDeposit;
        uint256 wantBal = balanceOfWant();
        if (wantBal < rewardAmount) {
            IConvexRewardPoolL1(rewardPool).withdrawAndUnwrap(rewardAmount - wantBal, false);
            wantBal = balanceOfWant();
        }
        if (wantBal > rewardAmount) wantBal = rewardAmount;

        uint256 _beforeTokenBal = _getTokenBalance(_token);

        ICurveSwap(pool).remove_liquidity_one_coin(wantBal, poolToken.index, _minCurveOutput);

        uint256 _totalRewards = _getTokenBalance(_token) - _beforeTokenBal;

        _totalRewards -= chargeFees(FeeType.PERFORMANCE, _token, _totalRewards);

        if (_useEth) {
            IWETH(_token).withdraw(_totalRewards);

            (bool _sucess, ) = payable(_user).call{ value: _totalRewards }("");

            if (!_sucess) revert("TransferFailed");
        } else {
            IERC20Upgradeable(_token).safeTransfer(_user, _totalRewards);
        }

        emit ClaimedRewards(_user, _token, _totalRewards, balanceOf());
    }

    /// @notice Harvests rewards without convex deposit
    function harvestOnDeposit() external whenNotPaused onlyVault {
        _harvest(false);
    }

    /// @notice Harvests earnings (compounds rewards) and charges performance fee
    function harvest() external {
        _harvest(true);
    }

    /// @notice Harvests earnings (compounds rewards) and charges performance fee
    function _harvest(bool _depositConvex) private {
        (, , , bool atLeastOneToHarvest) = getPendingToHarvest();
        if (!atLeastOneToHarvest) return;
        IConvexRewardPoolL1(rewardPool).getReward();
        address _depositToken = depositToken;
        uint256 rewardTokensLength = rewardTokens.length;
        uint256 _amount = 0;
        for (uint256 i = 0; i < rewardTokensLength; i++) {
            _amount += _exchangeAllToken(
                rewardTokens[i],
                _depositToken,
                calculations.getAutomaticSwapMin(rewardTokens[i], _depositToken)
            );
        }
        uint256 depositBal = _getTokenBalance(_depositToken);
        _addLiquidityCurve(_depositToken, _amount, calculations.getAutomaticCurveMinLp(depositBal));
        if (_depositConvex && !paused()) _addLiquidityConvex();
        lastHarvest = block.timestamp;
        emit Harvested(msg.sender, depositBal, balanceOf());
    }

    /// @dev Handles the case where tokens get stuck in the Strategy. Allows the admin to send the tokens to the
    ///      SuperAdmin
    /// @param _token The address of the stuck token
    function inCaseTokensGetStuck(address _token) external onlyAdmin {
        require(_token != want, "WrongToken");

        uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));

        IERC20Upgradeable(_token).safeTransfer(adminStructure.superAdmin(), _amount);

        emit WithdrawStuckTokens(msg.sender, _token, _amount);
    }

    /// @notice Edits the "isAllowed" status of the deposit tokens
    /// @dev Only the admin and super admin can call this function
    /// @param _token The address of the token to edit
    /// @param _status The new status of the token (allowed=true or not allowed=false)
    function editAllowedDepositTokens(address _token, bool _status) external onlyAdmin {
        PoolToken memory poolToken = allowedDepositTokens[_token];
        require(poolToken.isAllowed != _status, "TokenWontChange");
        require(ICurveSwap(pool).coins(poolToken.index) == _token, "TokenNotValid");
        allowedDepositTokens[_token].isAllowed = _status;
        // Excluded because it is needed to harvest (compound)
        if (depositToken != _token) {
            uint256 approvalAmount = _status ? type(uint).max : 0;
            IERC20Upgradeable(_token).safeApprove(pool, approvalAmount);
        }
        uint256 allowedLength = listAllowedDepositTokens.length;
        bool atLeastOne;
        for (uint256 i; i < allowedLength; i++) {
            if (allowedDepositTokens[listAllowedDepositTokens[i]].isAllowed) {
                atLeastOne = true;
                continue;
            }
        }
        require(atLeastOne, "CantDisableAllTokens");
        emit EditedAllowedTokens(_token, _status);
    }

    /// @notice Edits the minimum token harvest amounts
    /// @dev Only the admin and super admin can call this function
    /// @param _tokens An array of token addresses to edit
    /// @param _minAmounts An array of minimum harvest amounts corresponding to the tokens
    function editMinimumTokenHarvest(
        address[] calldata _tokens,
        uint256[] calldata _minAmounts
    ) external onlyAdmin {
        require(_tokens.length == _minAmounts.length, "LengthsMismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minimumToHarvest[_tokens[i]] = _minAmounts[i];
            emit MinimumToHarvestChanged(_tokens[i], _minAmounts[i]);
        }
    }

    /// @notice Sets the path for token swaps
    /// @dev Only the admin and super admin can call this function
    /// @param _from An array of source token addresses
    /// @param _to An array of target token addresses
    /// @param _path An array of encoded swap paths for each token pair
    function setPath(
        address[] calldata _from,
        address[] calldata _to,
        bytes[] calldata _path
    ) external onlyAdmin {
        uint256 inputsLength = _from.length;
        require(inputsLength == _to.length && inputsLength == _path.length, "LengthsMismatch");
        for (uint256 i = 0; i < inputsLength; i++) {
            paths[_from[i]][_to[i]] = _path[i];
            emit SetPath(_from[i], _to[i], _path[i]);
        }
    }

    /// @notice Sets the strategy calculations contract
    /// @dev Only the super admin can call this function
    /// @param _calculations The address of the strategy calculations contract
    function setStrategyCalculations(IStrategyCalculations _calculations) external onlySuperAdmin {
        require(address(_calculations) != address(0), "ZeroCalculations");
        calculations = _calculations;
    }

    /// @notice Sets the oracles for token price feeds
    /// @dev Only the super admin can call this function
    /// @param _oracles An array of Oracle structs containing token and oracle addresses
    function setOracles(Oracle[] calldata _oracles) external onlySuperAdmin {
        for (uint256 i; i < _oracles.length; i++) {
            require(_oracles[i].token != address(0), "ZeroOracleToken");
            require(_oracles[i].oracle != address(0), "ZeroOracleOracle");
            oracle[_oracles[i].token] = AggregatorV3Interface(_oracles[i].oracle);
            emit SetOracle(_oracles[i].token, _oracles[i].oracle);
        }
    }

    /// @notice Sets the default slippage for Curve swaps used during harvest
    /// @dev Only the admin and super admin can call this function
    /// @param _defaultSlippage The default slippage percentage (0-100)
    function setDefaultSlippageCurve(uint256 _defaultSlippage) external onlyAdmin {
        require(ONE_HUNDRED >= _defaultSlippage, "InvalidDefaultSlippage");
        emit SetSlippage(defaultSlippageCurve, _defaultSlippage, "Curve");
        defaultSlippageCurve = _defaultSlippage;
    }

    /// @notice Sets the default slippage for Uniswap swaps
    /// @dev Only the admin and super admin can call this function
    /// @param _defaultSlippage The default slippage percentage (0-100)
    function setDefaultSlippageUniswap(uint256 _defaultSlippage) external onlyAdmin {
        require(ONE_HUNDRED >= _defaultSlippage, "InvalidDefaultSlippage");
        emit SetSlippage(defaultSlippageUniswap, _defaultSlippage, "Uniswap");
        defaultSlippageUniswap = _defaultSlippage;
    }

    /// @notice Deletes the reward tokens array
    /// @dev Only the super admin can call this function
    function deleteRewards() external onlySuperAdmin {
        delete rewardTokens;
    }

    /// @notice Unpauses the contract deposits and increases the token allowances
    /// @dev Only the admin and super admin can call this function
    /// @dev This function also reactivates everything after a panic
    function unpause() external onlyAdmin {
        _unpause();
        _modifyAllowances(type(uint).max);
        _addLiquidityConvex();
        isPanicActive = false;
        emit PauseStatusChanged(false);
    }

    /// @notice Adds reward tokens to the strategy
    /// @notice New reward tokens need to add an oracle and swap path to be reinvested
    /// @dev Only the super admin can call this function
    /// @param tokens An array of token addresses to add as reward tokens
    /// @param minAmounts An array of minimum harvest amounts corresponding to the reward tokens
    function addRewardToken(
        address[] calldata tokens,
        uint256[] calldata minAmounts
    ) external onlySuperAdmin {
        _addRewardToken(tokens, minAmounts);
    }

    /// @notice Retrieves the reward tokens array
    /// @return An array of reward token addresses
    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }

    /// @notice Retrieves the allowed deposit tokens array
    /// @return An array of allowed deposit token addresses
    function getAllowedDepositTokens() external view returns (address[] memory) {
        return listAllowedDepositTokens;
    }

    /// @notice Pauses deposits, and withdraws all funds from the convex pool
    /// @dev Only the super admin can call this function
    /// @dev Users can still withdraw their deposit tokens
    function panic() public onlySuperAdmin {
        pause();
        isPanicActive = true;
        IConvexRewardPoolL1(rewardPool).withdrawAllAndUnwrap(false);
        emit PanicExecuted();
    }

    /// @notice Pauses deposits and modifies token allowances
    /// @dev Only the admin and super admin can call this function
    /// @dev Users can still withdraw their deposit tokens
    function pause() public onlyAdmin {
        _pause();
        _modifyAllowances(0);
        emit PauseStatusChanged(true);
    }

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return _rewardAmounts rewards the amount representing the pending rewards
    /// @return _rewardTokens addresses of the reward tokens
    /// @return _enoughRewards list indicating if the reward token is enough to harvest
    /// @return _atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvest()
        public
        view
        returns (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        )
    {
        return calculations.getPendingToHarvestView();
    }

    /// @notice Calculates the total balance of the strategy
    /// @return The total balance of the strategy
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    /// @notice Calculates the balance of the 'want' token held by the strategy
    /// @return The balance of the 'want' token
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @notice Calculates the balance of the 'want' token in the convex pool
    /// @return The balance of the 'want' token in the convex pool
    function balanceOfPool() public view returns (uint256) {
        return IConvexRewardPoolL1(rewardPool).balanceOf(address(this));
    }

    /// @notice Charges fees (performance or management) in the specified token
    /// @param feeType The type of fee to charge (performance or management)
    /// @param token The token in which to charge the fees
    /// @param amount The amount of tokens to charge fees on
    /// @return Charged fee amount.
    function chargeFees(FeeType feeType, address token, uint256 amount) internal returns (uint256) {
        (uint256 percentage, address feeRecipient) = feeType == FeeType.PERFORMANCE
            ? (performanceFee, performanceFeeRecipient)
            : (managementFee, managementFeeRecipient);

        if (percentage > 0) {
            uint256 feeAmount = (amount * percentage) / ONE_HUNDRED;
            IERC20Upgradeable(token).safeTransfer(feeRecipient, feeAmount);
            emit ChargedFees(feeType, feeAmount, feeRecipient);
            return feeAmount;
        }

        return 0;
    }

    /// @notice Adds liquidity to the convex pool using the 'want' token
    /// @dev This function is private and used internally
    function _addLiquidityConvex() private {
        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            booster.deposit(pid, wantBal, true);
        }
    }

    /// @notice Adds liquidity to the Curve pool using the deposit token
    /// @param _token The address of the token to deposit
    /// @param _amount Amount of tokens to deposit
    /// @param _minWant The minimum amount of 'want' tokens to obtain from the Curve pool
    /// @dev This function is private and used internally
    function _addLiquidityCurve(address _token, uint256 _amount, uint256 _minWant) private {
        uint256[POOL_SIZE] memory _amounts = calculations.getCurveAmounts(_token, _amount);
        if (paused()) IERC20Upgradeable(_token).safeApprove(pool, _amount);
        ICurveSwap(pool).add_liquidity(_amounts, _minWant, false);
    }

    /// @notice Modifies token allowances for the strategy
    /// @param _amount The new allowance amount
    /// @dev This function is private and used internally
    function _modifyAllowances(uint256 _amount) private {
        IERC20Upgradeable(want).safeApprove(address(booster), _amount);
        address[] memory allowedTokens = listAllowedDepositTokens;
        uint256 tokensLength = allowedTokens.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            IERC20Upgradeable(allowedTokens[i]).safeApprove(pool, _amount);
        }
    }

    /// @notice Swaps all of the given token for another token
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _minSwap The minimum amount of tokens to receive from the swap
    /// @return amountOut The amount of tokens received from the swap
    /// @dev This function is private and used internally
    function _exchangeAllToken(
        address _from,
        address _to,
        uint256 _minSwap
    ) private returns (uint256 amountOut) {
        return _exchangeTokenAmount(_from, _to, _getTokenBalance(_from), _minSwap);
    }

    /// @notice Swaps the specified amount of tokens from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _minSwap The minimum amount of tokens to receive from the swap
    /// @return amountOut The amount of tokens received from the swap
    /// @dev This function is private and used internally
    function _exchangeTokenAmount(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minSwap
    ) private returns (uint256 amountOut) {
        if (_amount < minimumToHarvest[_from]) return 0;
        bytes memory path = paths[_from][_to];
        require(path.length > 0, "Nonexistent Path");
        return UniV3Actions.swapV3WithDeadline(unirouterV3, path, _amount, _minSwap);
    }

    /// @notice Adds reward tokens to the strategy
    /// @notice New reward tokens need to add an oracle and swap path to be reinvested
    /// @param tokens An array of token addresses to add as reward tokens
    /// @param minAmounts An array of minimum harvest amounts corresponding to the reward tokens
    function _addRewardToken(address[] calldata tokens, uint256[] calldata minAmounts) private {
        uint256 tokensLength = tokens.length;
        require(tokensLength == minAmounts.length, "LengthsMismatch");
        for (uint256 i; i < tokensLength; i++) {
            address token = tokens[i];
            require(token != address(0), "ZeroRewardToken");
            require(token != want, "CannotUseWant");
            require(token != rewardPool, "CannotUseRewardPool");
            uint256 rewardTokensLength = rewardTokens.length;
            for (uint256 j; j < rewardTokensLength; j++) {
                require(token != rewardTokens[j], "TokenAlreadyExists");
            }
            rewardTokens.push(token);
            minimumToHarvest[token] = minAmounts[i];
            IERC20Upgradeable(token).safeApprove(unirouterV3, 0);
            IERC20Upgradeable(token).safeApprove(unirouterV3, type(uint).max);
            emit AddedRewardToken(token, minAmounts[i]);
        }
    }

    /// @notice Retrieves the balance of the specified token held by the strategy
    /// @param _token The address of the token
    /// @return The balance of the token
    /// @dev This function is private and used internally
    function _getTokenBalance(address _token) private view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }
}
