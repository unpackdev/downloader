// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IStrategyConvex.sol";
import "./Initializable.sol";
import "./AggregatorV3Interface.sol";
import "./IAdminStructure.sol";
import "./SafeCast.sol";
import "./IConvex.sol";
import "./IGaugeFactory.sol";
import "./ICurveSwap.sol";
import "./IQuoter.sol";
import "./IERC20.sol";
import "./UniV3Actions.sol";
import "./ICVX.sol";

/// @title StrategyCalculationsL1 contract for calculating strategy-related values
contract StrategyCalculationsL1 is Initializable {
    using SafeCast for int256;

    /// @notice Address of the admin structure contract
    IAdminStructure public adminStructure;
    /// @notice Address of the strategy contract
    IStrategyConvex public strategy;
    /// @notice Address of the quoter contract
    IQuoter public quoter;

    /// @notice Constant for representing 100 (100%)
    uint256 public constant ONE_HUNDRED = 100 ether;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the StrategyCalculationsL1 contract
    /// @param _strategy The address of the StrategyConvex contract
    /// @param _quoter The address of the Quoter contract
    /// @param _adminStructure The address of the AdminStructure contract
    function initialize(
        IStrategyConvex _strategy,
        IQuoter _quoter,
        IAdminStructure _adminStructure
    ) public initializer {
        require(address(_strategy) != address(0), "ZeroStrategy");
        require(address(_quoter) != address(0), "ZeroQuoter");
        require(address(_adminStructure) != address(0), "ZeroAdminStructure");
        strategy = _strategy;
        quoter = _quoter;
        adminStructure = _adminStructure;
    }

    /// @dev Sets the Quoter contract address
    /// @param _quoter The address of the Quoter contract
    function setQuoter(IQuoter _quoter) external {
        adminStructure.isValidSuperAdmin(msg.sender);
        require(address(_quoter) != address(0), "ZeroQuoter");
        quoter = _quoter;
    }

    /// @dev Sets the StrategyConvex contract address
    /// @param _strategy The address of the StrategyConvex contract
    function setStrategy(IStrategyConvex _strategy) external {
        adminStructure.isValidSuperAdmin(msg.sender);
        require(address(_strategy) != address(0), "ZeroStrategy");
        strategy = _strategy;
    }

    /// @notice Estimates the deposit details for a specific token and amount
    /// @param _token The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return amountWant The minimum amount of LP tokens to get from curve deposit
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 amountWant) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        amountWant = calculateCurveDeposit(_token, _amount, _slippage);
    }

    /// @notice Estimates the withdrawal details for a specific user, token, maximum amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return withdrawable The minimum amount of tokens to get after the withdrawal
    function estimateWithdrawal(
        address _user,
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external view returns (uint256 minCurveOutput, uint256 withdrawable) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        uint256 maxClaim = calculateCurveMinWithdrawal(_token, _maxAmount, _slippage);
        minCurveOutput = maxClaim;
        uint256 _userDeposit = strategy.userWantDeposit(_user);
        uint256 _rewards = 0;
        if (_userDeposit < _maxAmount) {
            uint256 rewardsPercentage = ((_maxAmount - _userDeposit) * 1e18) / _maxAmount;
            _rewards = (maxClaim * rewardsPercentage) / 1e18;
        }
        uint256 _performanceFee = strategy.performanceFee();
        uint256 performancefeeAmount = (_rewards * _performanceFee) / ONE_HUNDRED;
        uint256 depositMinusRewards = maxClaim - _rewards;
        uint256 _managementFee = strategy.managementFee();
        uint256 managementfeeAmount = (depositMinusRewards * _managementFee) / ONE_HUNDRED;
        withdrawable = maxClaim - managementfeeAmount - performancefeeAmount;
    }

    /// @notice Estimates the rewards details for a specific user, token, amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return claimable The minimum amount of tokens to get after the claim of rewards
    function estimateRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 minCurveOutput, uint256 claimable) {
        return _estimateRewards(_token, _amount, _slippage, strategy.userWantDeposit(_user));
    }

    /// @notice Estimates the total claimable rewards for all users using a specific token and slippage
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return claimable The total claimable amount of tokens
    function estimateAllUsersRewards(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 claimable) {
        (, claimable) = _estimateRewards(_token, _amount, _slippage, strategy.totalWantDeposits());
    }

    /// @notice Estimates the want balance after a harvest
    /// @param _slippage The allowed slippage percentage
    /// @return Returns the new want amount
    function estimateWantAfterHarvest(uint256 _slippage) external returns (uint256) {
        uint256 wantBalance = strategy.balanceOf();
        (
            uint256[] memory rewardAmounts,
            address[] memory rewardTokens,
            bool[] memory enoughRewards,
            bool atLeastOne
        ) = getPendingToHarvestView();
        if (!atLeastOne) return wantBalance;
        address depositToken = strategy.depositToken();
        uint256 totalInDeposit;
        for (uint256 i = 0; i < rewardAmounts.length; i++) {
            totalInDeposit += enoughRewards[i]
                ? estimateSwap(rewardTokens[i], depositToken, rewardAmounts[i], _slippage)
                : 0;
        }
        uint256 extraWant = calculateCurveDeposit(depositToken, totalInDeposit, _slippage);
        return wantBalance + extraWant;
    }

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return rewardAmounts rewards the amount representing the pending rewards
    /// @return rewardTokens addresses of the reward tokens
    /// @return enoughRewards list indicating if the reward token is enough to harvest
    /// @return atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvestView()
        public
        view
        returns (
            uint256[] memory rewardAmounts,
            address[] memory rewardTokens,
            bool[] memory enoughRewards,
            bool atLeastOne
        )
    {
        rewardTokens = strategy.getRewardTokens();
        rewardAmounts = new uint256[](rewardTokens.length);
        enoughRewards = new bool[](rewardTokens.length);
        rewardAmounts[0] = IConvexRewardPoolL1(strategy.rewardPool()).earned(address(strategy)); // CRV
        rewardAmounts[1] = estimateCVXRewards(rewardAmounts[0]); // CVX
        for (uint256 i; i < rewardAmounts.length; i++) {
            rewardAmounts[i] += _getTokenBalance(rewardTokens[i]); // Adding exsting balance
            enoughRewards[i] = rewardAmounts[i] >= strategy.minimumToHarvest(rewardTokens[i]);
            if (enoughRewards[i]) atLeastOne = true;
        }
    }

    /**
     * @notice Estimates the amoung of CVX rewards that the strategy can receive
     * @dev The amount of CVX is determined by the amount of CVX
     * @param _crvAmount The amount of crv rewards
     * @return The amount of cvx rewards tokens available to be claimed
     */
    function estimateCVXRewards(uint256 _crvAmount) public view virtual returns (uint256) {
        ICVXL1 cvx = ICVXL1(strategy.getRewardTokens()[1]);
        uint256 supply = cvx.totalSupply();
        uint256 maxSupply = cvx.maxSupply();
        uint256 totalCliffs = cvx.totalCliffs();
        uint256 reductionPerCliff = cvx.reductionPerCliff();
        uint256 cliff = supply / reductionPerCliff;
        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs - cliff;
            uint256 cvxAmount = (_crvAmount * reduction) / totalCliffs;
            uint256 amtTillMax = maxSupply - supply;
            if (cvxAmount > amtTillMax) cvxAmount = amtTillMax;
            return cvxAmount;
        }

        return 0;
    }

    /**
     * @dev Returns the amount of tokens deposited by a specific user in the indicated token
     * @param _user The address of the user.
     * @param _token The address of the token.
     * @return The amount of tokens deposited by the user.
     */
    function userDeposit(address _user, address _token) external view returns (uint256) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        uint256 userWant = strategy.userWantDeposit(_user);
        if (userWant == 0) return 0;
        return calculateCurveMinWithdrawal(_token, userWant, 0);
    }

    /**
     * @dev Returns the total amount of tokens deposited in the strategy in the indicated token
     * @param _token The address of the token.
     * @return The total amount of tokens deposited.
     */
    function totalDeposits(address _token) external view returns (uint256) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        uint256 totalWant = strategy.totalWantDeposits();
        if (totalWant == 0) return 0;
        return calculateCurveMinWithdrawal(_token, totalWant, 0);
    }

    /// @notice Retrieves the minimum amount of tokens to swap from a specific fromToken to toToken
    /// @param _fromToken The address of the token to swap from
    /// @param _toToken The address of the token to swap to
    /// @return The minimum amount of tokens to swap
    function getAutomaticSwapMin(
        address _fromToken,
        address _toToken
    ) public view returns (uint256) {
        AggregatorV3Interface _oracleFrom = AggregatorV3Interface(strategy.oracle(_fromToken));
        AggregatorV3Interface _oracleTo = AggregatorV3Interface(strategy.oracle(_toToken));
        uint256 fromTokenPrice = (_oracleFrom.latestAnswer().toUint256() * 1e18) /
            (10 ** _oracleFrom.decimals());
        uint256 toTokenPrice = (_oracleTo.latestAnswer().toUint256() * 1e18) /
            (10 ** _oracleTo.decimals());
        uint256 minAmount = (fromTokenPrice * _getTokenBalance(_fromToken)) /
            toTokenPrice /
            (10 ** (18 - IERC20(_toToken).decimals()));
        return (minAmount * (ONE_HUNDRED - strategy.defaultSlippageUniswap())) / ONE_HUNDRED;
    }

    /// @notice Retrieves the minimum amount of LP tokens to obtained from a curve deposit
    /// @param _depositAmount The amount to deposit
    /// @return The minimum amount of LP tokens to obtained from the deposit on curve
    function getAutomaticCurveMinLp(uint256 _depositAmount) public view returns (uint256) {
        address _depositToken = strategy.depositToken();
        AggregatorV3Interface _oracle = AggregatorV3Interface(strategy.oracle(_depositToken));
        uint256 oneTokenPrice = (_oracle.latestAnswer().toUint256() * 1e18) /
            (10 ** _oracle.decimals());
        uint256 depositUsdPrice = (_depositAmount * oneTokenPrice) /
            (10 ** IERC20(_depositToken).decimals());
        uint256 depositUsdPriceWithSlippage = (depositUsdPrice *
            (ONE_HUNDRED - strategy.defaultSlippageCurve())) / ONE_HUNDRED;
        return
            (depositUsdPriceWithSlippage * 1e18) / ICurveSwap(strategy.pool()).get_virtual_price();
    }

    /// @notice Estimates the amount of tokens to swap from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _slippage The allowed slippage percentage
    /// @return estimate The estimated amount of tokens to receive after the swap
    function estimateSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _slippage
    ) public returns (uint256 estimate) {
        if (_from == _to) return _amount;
        uint256 amountOut = quoter.quoteExactInput(strategy.paths(_from, _to), _amount);
        return _getMinimum(amountOut, _slippage);
    }

    /// @notice Calculates the minimum amount of tokens to receive from Curve for a specific token and maximum amount
    /// @param _token The address of the token to withdraw
    /// @param _amount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum amount of tokens to receive from Curve
    function calculateCurveMinWithdrawal(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) public view returns (uint256) {
        (, uint8 index) = strategy.allowedDepositTokens(_token);
        uint256 amount = ICurveSwap(strategy.pool()).calc_withdraw_one_coin(
            _amount,
            int128(uint128(index))
        );
        return _getMinimum(amount, _slippage);
    }

    /// @notice Calculates the amount of LP tokens to get on curve deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return The amount of LP tokens to get
    function calculateCurveDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) public view returns (uint256) {
        uint256[2] memory amounts = getCurveAmounts(_token, _amount);
        uint256 calcAmount = ICurveSwap(strategy.pool()).calc_token_amount(amounts, true);
        return _getMinimum(calcAmount, _slippage);
    }

    /// @notice Formats the array input for curve
    /// @param _depositToken The address of the deposit token
    /// @param _amount The amount to deposit
    /// @return amounts An array of token amounts to use in curve
    function getCurveAmounts(
        address _depositToken,
        uint256 _amount
    ) public view returns (uint256[2] memory amounts) {
        (, uint8 index) = strategy.allowedDepositTokens(_depositToken);
        amounts[index] = _amount;
    }

    /// @dev Estimates the rewards for a specific token and amount, taking into account slippage and deposit amount.
    /// @param _token The address of the token for which rewards are being estimated
    /// @param _amount The amount of tokens being considered
    /// @param _slippage The slippage percentage to consider
    /// @param _depositAmount The total deposit amount in the strategy
    /// @return minCurveOutput The minimum output from the Curve pool
    /// @return claimable The claimable rewards for the specified token and amount
    function _estimateRewards(
        address _token,
        uint256 _amount,
        uint256 _slippage,
        uint256 _depositAmount
    ) private view returns (uint256 minCurveOutput, uint256 claimable) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        if (
            _depositAmount == 0 ||
            _amount == 0 ||
            strategy.balanceOf() == 0 ||
            _depositAmount >= _amount
        ) return (0, 0);
        uint256 rewards = _amount - _depositAmount;
        minCurveOutput = calculateCurveMinWithdrawal(_token, rewards, _slippage);
        uint256 _performanceFee = strategy.performanceFee();
        uint256 performancefeeAmount = (minCurveOutput * _performanceFee) / ONE_HUNDRED;
        claimable = minCurveOutput - performancefeeAmount;
    }

    /// @notice Retrieves the balance of a specific token held by the Strategy
    /// @param _token The address of the token
    /// @return The token balance
    function _getTokenBalance(address _token) private view returns (uint256) {
        return IERC20(_token).balanceOf(address(strategy));
    }

    /// @notice Retrieves the minimum value between a specific amount and a slippage percentage
    /// @param _amount The amount
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum value
    function _getMinimum(uint256 _amount, uint256 _slippage) private pure returns (uint256) {
        return _amount - ((_amount * _slippage) / ONE_HUNDRED);
    }
}
