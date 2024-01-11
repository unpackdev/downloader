// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import "./IImpossibleERC20.sol";

interface IImpossiblePair is IImpossibleERC20 {
    enum TradeState {
        SELL_ALL,
        SELL_TOKEN_0,
        SELL_TOKEN_1,
        SELL_NONE
    }

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event ChangeInvariant(bool _isXybk, uint256 _newBoost0, uint256 _newBoost1);
    event UpdatedTradeFees(uint256 _oldFee, uint256 _newFee);
    event UpdatedDelay(uint256 _oldDelay, uint256 _newDelay);
    event UpdatedTradeState(TradeState _tradeState);
    event UpdatedWithdrawalFeeRatio(uint256 _oldWithdrawalFee, uint256 _newWithdrawalFee);
    event UpdatedBoost(
        uint32 _oldBoost0,
        uint32 _oldBoost1,
        uint32 _newBoost0,
        uint32 _newBoost1,
        uint256 _start,
        uint256 _end
    );

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address); // address of token0

    function token1() external view returns (address); // address of token1

    function getReserves() external view returns (uint256, uint256); // reserves of token0/token1

    function calcBoost() external view returns (uint256, uint256);

    function mint(address) external returns (uint256);

    function burn(address) external returns (uint256, uint256);

    function swap(
        uint256,
        uint256,
        address,
        bytes calldata
    ) external;

    function skim(address to) external;

    function sync() external;

    function getPairSettings()
        external
        view
        returns (
            uint16,
            TradeState,
            bool
        ); // Uses single storage slot, save gas

    function delay() external view returns (uint256); // Amount of time delay required before any change to boost etc, denoted in seconds

    function initialize(
        address,
        address,
        address,
        address
    ) external;
}
