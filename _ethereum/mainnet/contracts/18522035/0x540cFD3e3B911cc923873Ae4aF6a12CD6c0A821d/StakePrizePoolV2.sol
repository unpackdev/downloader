// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./IERC20Upgradeable.sol";

import "./Initializable.sol";

import "./PrizePoolV2.sol";

/**
 * @title  Asymetrix Protocol V2 StakePrizePoolV2
 * @author Asymetrix Protocol Inc Team
 * @notice The Stake Prize Pool V2 is a prize pool in which users can deposit an
 *         ERC20 token. These tokens are simply held by the Stake Prize Pool V2
 *         and become eligible for prizes. Prizes are added manually by the
 *         Stake Prize Pool V2 owner and are distributed to users at the end of
 *         the prize period.
 */
contract StakePrizePoolV2 is PrizePoolV2 {
    /// @notice Address of the stake token.
    IERC20Upgradeable private stakeToken;

    /// @dev Emitted when stake prize pool is deployed.
    /// @param stakeToken Address of the stake token.
    event Deployed(IERC20Upgradeable indexed stakeToken);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Deploy the Stake Prize Pool V2 contract.
     * @param _esAsx esASX token address.
     * @param _rewardsBooster RewardsBooster contract address.
     * @param _esAsxVesting EsAsxVesting contract address.
     * @param _uniswapWrapper A wrapper contract address that helps to interact
     *                        with Uniswap V3.
     * @param _asxOracle An oracle for ASX token that returns price of ASX token
     *                   in WETH.
     * @param _weth WETH token address.
     * @param _esAsxRewardPerSecond The reward per second that will be used in
     *                              time of distribution of esASX tokens.
     * @param _liquidationThreshold Minimum threshold for partial liquidation of
     *                              users' boosts.
     * @param _slippageTolerance A slippage tolerance to apply in time of swap
     *                           of ETH/WETH for ASX.
     */
    function initializeV2(
        address _esAsx,
        address _rewardsBooster,
        address _esAsxVesting,
        address _uniswapWrapper,
        address _asxOracle,
        address _weth,
        uint256 _esAsxRewardPerSecond,
        uint16 _liquidationThreshold,
        uint16 _slippageTolerance
    ) external reinitializer(2) {
        __PrizePoolV2_init_unchained(
            _esAsx,
            _rewardsBooster,
            _esAsxVesting,
            _uniswapWrapper,
            _asxOracle,
            _weth,
            _esAsxRewardPerSecond,
            _liquidationThreshold,
            _slippageTolerance
        );
    }

    /// @notice Determines whether the passed token can be transferred out as an
    ///         external award.
    /// @dev Different yield sources will hold the deposits as another kind of
    ///      token: such a Compound's cToken. The prize flush should not be
    ///      allowed to move those tokens.
    /// @param _externalToken The address of the token to check.
    /// @return True if the token may be awarded, false otherwise.
    function _canAwardExternal(address _externalToken) internal view override returns (bool) {
        return address(stakeToken) != _externalToken;
    }

    /// @notice Returns the total balance (in asset tokens). This includes the
    ///         deposits and interest.
    /// @return The underlying balance of asset tokens.
    function _balance() internal view override returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }

    /// @notice Returns the address of the ERC20 asset token used for deposits.
    /// @return Address of the ERC20 asset token.
    function _token() internal view override returns (IERC20Upgradeable) {
        return stakeToken;
    }
}
