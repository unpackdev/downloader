// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";

import "./AbstractAdapter.sol";
import "./CurveV1_Base.sol";
import "./ICurveV1Adapter.sol";
import "./IAdapter.sol";
import "./ICreditManagerV2.sol";
import "./ICurvePool.sol";
import "./ICRVToken.sol";
import "./ICurveRegistry.sol";

import "./CreditAccount.sol";
import "./CreditManager.sol";
import "./WadRayMath.sol";

// EXCEPTIONS
import "./IErrors.sol";

import "./console.sol";

address constant CURVE_REGISTER = 0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5;

/// @title CurveV1Base adapter
/// @dev Implements exchange logic except liquidity operations
contract CurveV1AdapterBase is
    AbstractAdapter,
    ICurveV1Adapter,
    ReentrancyGuard
{
    // LP token, it could be named differently in some Curve Pools,
    // so we set the same value to cover all possible cases
    address public immutable override token;
    address public immutable override lp_token;

    uint16 public constant _gearboxAdapterVersion = 2;

    /// @dev Constructor
    /// @param _creditManager Address Credit manager
    /// @param _curvePool Address of curve-compatible pool
    constructor(address _creditManager, address _curvePool)
        AbstractAdapter(_creditManager, _curvePool)
    {
        if (_curvePool == address(0)) revert ZeroAddressException(); // F:[ACV1-1]

        address _token;
        try ICurvePool(_curvePool).token() returns (address tokenFromPool) {
            _token = tokenFromPool;
        } catch {
            address curveRegister = CURVE_REGISTER;
            _token = ICurveRegistry(CURVE_REGISTER).get_lp_token(_curvePool);
        }
        token = _token; //F:[ACV1-2]
        lp_token = _token;
    }

    function coins(uint256 i) external view override returns (address) {
        return ICurvePool(targetContract).coins(i);
    }

    /// @dev Exchanges two assets on Curve-compatible pools. Restricted for pool calls only
    /// @param i Index value for the coin to send
    /// @param j Index value of the coin to receive
    /// @param dx Amount of i being exchanged
    /// @param min_dy Minimum amount of j to receive
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external override nonReentrant {
        address tokenIn = ICurvePool(targetContract).coins(uint256(uint128(i))); // F:[ACV1-4]
        address tokenOut = ICurvePool(targetContract).coins(
            uint256(uint128(j))
        ); // F:[ACV1-4]
        _executeFastCheck(tokenIn, tokenOut, msg.data, true);
    }

    function exchange_all(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external override nonReentrant {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        address tokenIn = ICurvePool(targetContract).coins(uint256(uint128(i))); //F:[ACV1-5,7]
        address tokenOut = ICurvePool(targetContract).coins(
            uint256(uint128(j))
        ); // F:[ACV1-4]

        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount) - 1; //F:[ACV1-5,7]
        uint256 min_dy = (dx * rateMinRAY) / RAY; //F:[ACV1-5]

        _executeFastCheck(
            creditAccount,
            tokenIn,
            tokenOut,
            abi.encodeWithSelector(
                ICurvePool.exchange.selector,
                i,
                j,
                dx,
                min_dy
            ),
            true
        );
    }

    // TODO: Cover with tests for 2-, 3- and 4- assets adapter
    function remove_liquidity_one_coin(
        uint256, // _token_amount,
        int128 i,
        uint256 // min_amount
    ) external virtual override nonReentrant {
        address tokenOut = ICurvePool(targetContract).coins(
            uint256(uint128(i))
        ); // F:[ACV1-4]
        _executeFastCheck(lp_token, tokenOut, msg.data, true);
    }

    function _remove_liquidity_one_coin(address tokenOut, bytes memory callData)
        internal
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        );

        _executeFastCheck(lp_token, tokenOut, callData, false);
        creditManager.checkAndEnableToken(creditAccount, tokenOut);
    }

    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external
        virtual
        override
        nonReentrant
    {
        address tokenOut = ICurvePool(targetContract).coins(
            uint256(uint128(i))
        ); // F:[ACV1-4]
        _remove_all_liquidity_one_coin(i, tokenOut, minRateRAY);
    }

    function _remove_all_liquidity_one_coin(
        int128 i,
        address tokenOut,
        uint256 rateMinRAY
    ) internal {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); //F:[ACV1-3]

        uint256 amount = IERC20(lp_token).balanceOf(creditAccount) - 1; //F:[ACV1-5,7]

        _executeFastCheck(
            creditAccount,
            lp_token,
            tokenOut,
            abi.encodeWithSelector(
                ICurvePool.remove_liquidity_one_coin.selector,
                amount,
                i,
                (amount * rateMinRAY) / RAY
            ),
            false
        );
    }

    function exchange_underlying(
        int128, // i
        int128, // j
        uint256, // dx
        uint256 // min_dy
    ) external pure override {
        revert NotImplementedException();
    }

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePool(targetContract).get_dy_underlying(i, j, dx);
    }

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePool(targetContract).get_dy(i, j, dx);
    }

    function get_virtual_price() external view override returns (uint256) {
        return ICurvePool(targetContract).get_virtual_price();
    }

    function _gearboxAdapterType()
        external
        pure
        virtual
        override
        returns (AdapterType)
    {
        return AdapterType.CURVE_V1_2ASSETS;
    }

    function add_all_liquidity_one_coin(int128, uint256) external virtual {
        revert NotImplementedException();
    }
}
