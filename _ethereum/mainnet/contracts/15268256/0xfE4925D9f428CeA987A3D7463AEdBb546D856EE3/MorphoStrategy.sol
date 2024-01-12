// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ClaimFullSingleRewardStrategy.sol";
import "./ICErc20.sol";
import "./IMorpho.sol";
import "./ICompoundStrategyContractHelper.sol";

contract MorphoStrategy is ClaimFullSingleRewardStrategy {
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */

    /// @notice Helper value
    uint256 public immutable MANTISSA = 10 ** 18;

    /* ========== STATE VARIABLES ========== */

    /// @notice Morpho contract
    IMorpho public immutable morpho;
    /// @notice Compound market
    ICErc20 public immutable cToken;
    /// @notice helper contract that holds funds
    ICompoundStrategyContractHelper public immutable strategyHelper;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Set initial values
     * @param _morpho Morpho contract
     * @param _comp COMP token, reward token
     * @param _cToken Comptroller implementaiton
     * @param _underlying Underlying asset
     */
    constructor(
        IMorpho _morpho,
        IERC20 _comp,
        ICErc20 _cToken,
        IERC20 _underlying,
        ICompoundStrategyContractHelper _strategyHelper
    )
        BaseStrategy(_underlying, 1, 0, 0, 0, false, false, address(0)) 
        ClaimFullSingleRewardStrategy(_comp) 
    {
        require(address(_morpho) != address(0), "MorphoStrategy::constructor: Morpho address cannot be 0");
        require(address(_cToken) != address(0), "MorphoStrategy::constructor: cToken address cannot be 0");
        require(address(_underlying) == _cToken.underlying(), "MorphoStrategy::constructor: Underlying and cToken underlying do not match");
        require(_cToken == _strategyHelper.cToken(), "MorphoStrategy::constructor: cToken is not the same as helpers cToken");
        morpho = _morpho;
        cToken = _cToken;
        strategyHelper = _strategyHelper;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Get strategy balance
     * @return Strategy balance
     */
    function getStrategyBalance() public view override returns(uint128) {
        uint256 cTokenBalance = _getcTokenBalance();
        return SafeCast.toUint128(_getcTokenValue(cTokenBalance));
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    /**
     * @notice claim COMP from the morpho contract
     * @dev claimRewards fails if there are no pending rewards, with the custom error AmountIsZero. there is currently no way to catch custom errors with Solidity, and no way to get the claimable rewards without calling the function. so we instead check if the contract has some balance, and if so, call claimRewards.
     */
    function _claimStrategyReward() internal override returns(uint128) {
        // claim COMP rewards
        uint256 rewardAmount = strategyHelper.claimRewards(_getcTokenBalance() > 0 ? true : false);

        // add already claimed rewards
        rewardAmount += strategies[self].pendingRewards[address(rewardToken)];

        return SafeCast.toUint128(rewardAmount);
    }

    /**
     * @dev Transfers underlying tokens to the morpho contract
     */
    function _deposit(uint128 amount, uint256[] memory) internal override returns(uint128) {

        underlying.safeTransfer(address(strategyHelper), amount);

        uint256 cTokenBalanceNew = strategyHelper.deposit(amount);

        return SafeCast.toUint128(_getcTokenValue(cTokenBalanceNew));
    }

    /**
     * @dev Withdraw lp tokens from the Morpho market
     */
    function _withdraw(uint128 shares, uint256[] memory) internal override returns(uint128) {

        // check strategy helper cToken balance
        uint256 cTokenBalance = _getcTokenBalance();
        uint256 cTokenWithdraw = (cTokenBalance * shares) / strategies[self].totalShares;

        uint256 undelyingWithdrawn = strategyHelper.withdraw(_getcTokenValue(cTokenWithdraw));

        return SafeCast.toUint128(undelyingWithdrawn);
    }

    /**
     * @dev Emergency withdraw
     */
    function _emergencyWithdraw(address, uint256[] calldata data) internal override {
        strategyHelper.withdrawAll(data);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Get value of the desired cToken amount in the underlying asset
     * @param cTokenBalance cToken value
     * @return underlyingAmount value og `cTokenBalance` in underlying token
     */
    function _getcTokenValue(uint256 cTokenBalance) private view returns(uint256) {
        if (cTokenBalance == 0)
            return 0;

        uint256 exchangeRateCurrent = cToken.exchangeRateStored();
        return (exchangeRateCurrent * cTokenBalance) / MANTISSA;
    }

    /**
     * @dev Get cToken balance from the Morpho contract.
     */
    function _getcTokenBalance() private view returns(uint256) {
        (uint inP2P, uint onPool) = morpho.supplyBalanceInOf(address(cToken), address(strategyHelper));
        return (inP2P + onPool);
    }
}
