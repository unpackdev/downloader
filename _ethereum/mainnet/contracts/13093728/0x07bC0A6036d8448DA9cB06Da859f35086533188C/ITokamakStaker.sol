//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface ITokamakStaker {
    /// @dev set the tokamak Layer2 address
    /// @param _layer2 new the tokamak Layer2 address
    function setTokamakLayer2(address _layer2) external;

    /// @dev get the addresses yhat used in uniswap interfaces
    /// @return uniswapRouter the address of uniswapV3 Router
    /// @return npm the address of positionManagerAddress
    /// @return ext the address of ext
    /// @return fee the amount of fee
    /// @return uniswapV2Router uniswapV2 router address
    function getUniswapInfo()
        external
        view
        returns (
            address uniswapRouter,
            address npm,
            address ext,
            uint256 fee,
            address uniswapV2Router
        );

    /// @dev Change the TON holded in contract have to WTON, or change WTON to TON.
    /// @param amount the amount to be changed
    /// @param toWTON if it's true, TON->WTON , else WTON->TON
    function swapTONtoWTON(uint256 amount, bool toWTON) external;

    /// @dev  staking the staked TON in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param stakeAmount the amount that stake to layer2
    function tokamakStaking(address _layer2, uint256 stakeAmount) external;

    /// @dev  request unstaking the wtonAmount in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    /// @param wtonAmount the amount requested to unstaking
    function tokamakRequestUnStaking(address _layer2, uint256 wtonAmount)
        external;

    /// @dev  request unstaking the wtonAmount in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakRequestUnStakingAll(address _layer2) external;

    /// @dev process unstaking in layer2 in tokamak
    /// @param _layer2 the layer2 address in tokamak
    function tokamakProcessUnStaking(address _layer2) external;

    /// @dev exchange holded WTON to TOS using uniswap-v3
    /// @param _amountIn the input amount
    /// @param _amountOutMinimum the minimun output amount
    /// @param _deadline deadline
    /// @param _sqrtPriceLimitX96 sqrtPriceLimitX96
    /// @param _kind the function type, if 0, use exactInputSingle function, else if, use exactInput function
    function exchangeWTONtoTOS(
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        uint256 _deadline,
        uint160 _sqrtPriceLimitX96,
        uint256 _kind
    ) external returns (uint256 amountOut);
}
