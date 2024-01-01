// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ICurveConvexPeriphery {
    ///
    /// @dev calculates amount of LP token to receive from the pool based on deposit amount
    /// @param pool address providing LP tokens
    /// @param depositAmount amount of deposit tokens to provide to pool. Amount is always in deposit tokens.
    /// @param isDeposit flag to check is the operation for removing or adding the liquidity
    /// @return amount of LP tokens to receive
    ///
    function calcTokenAmount(
        address pool,
        uint256 depositAmount,
        bool isDeposit
    ) external view returns (uint256);

    ///
    /// @dev calculates amount of token on index i inside the pool to receive when burning LP tokens
    /// @param pool address LP token's pool
    /// @param burnAmount amount of LP tokens to burn
    /// @param i token index in the pool
    /// @return amount of token to receive
    ///
    function calcWithdrawOneCoin(
        address pool,
        uint256 burnAmount,
        int128 i
    ) external view returns (uint256);

    ///
    /// @dev calculates amount to receive when swapping "from" "to"
    /// @param pool address of swap pool
    /// @param from token address exchanging "from"
    /// @param to token address exchanging "to"
    /// @param input amount of "from" token to exchange
    /// @return amount of "to" token to receive after exchange
    ///
    function getExchangeAmount(
        address pool,
        address from,
        address to,
        uint256 input
    ) external view returns (uint256);

    ///
    /// @dev Calculates pool exposure in deposit tokens, used as a part of rebalancing process
    /// @param targetExposure target exposure in deposit tokens
    /// @return array of pool exposure difference between current and target exposure in deposit tokens
    /// @return pool allocation in bps
    ///
    function exposureDiff(
        uint256 targetExposure
    ) external view returns (int256[8] memory, uint256[] memory);

    ///
    /// @dev Calculates exchange from CRV and CVX amount to deposit tokens amount
    /// @param inputs array [CRV amount, CVX amount]
    /// @return array [CRV in deposit token amount, CVX in deposit token amount]
    /// @return array which stores results of each exchange hop from CRV to target deposit token
    /// @return array which stores results of each exchange hop from CVX to target deposit token
    ///
    function crvCvxToDepositCcy(
        uint256[2] memory inputs
    )
        external
        view
        returns (uint256[2] memory, uint256[] memory, uint256[] memory);

    ///
    /// @dev Used as supporting method to main strategy contract totalAssets()
    /// Includes all assets under strategy management, includes amount deployed in staked LP tokens,
    /// emergency mode assets and to be deployed assets
    /// @return total amount of assets in deposit tokens
    ///
    function totalAssets() external view returns (uint256);

    ///
    /// @dev Used as supporting method to main strategy contract needEmergencyMode().
    /// Checks if there is a need for emergency mode, verifies depeg and low-liquidity conditions
    /// @return flag indicating if there is need to go into emergency mode
    ///
    function needEmergencyMode() external view returns (bool);

    ///
    /// @dev Used as supporting method to main strategy contract status()
    /// checks strategy status
    /// @return string with strategy metadata
    ///
    function status() external view returns (string memory);
}
