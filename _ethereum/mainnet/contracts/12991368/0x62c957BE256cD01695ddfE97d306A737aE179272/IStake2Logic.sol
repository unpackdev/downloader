//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStake2Logic {
    /// @dev event on create vault
    /// @param vault the vault address created
    /// @param paytoken the token used for staking by user
    /// @param cap  allocated reward amount
    event CreatedVault2(address indexed vault, address paytoken, uint256 cap);

    /// @dev event on create stake contract in vault
    /// @param vault the vault address
    /// @param stakeContract the stake contract address created
    /// @param phase the phase of TOS platform
    event CreatedStakeContract2(
        address indexed vault,
        address indexed stakeContract,
        uint256 phase
    );

    /// @dev Set stakeVaultLogic address by _phase
    /// @param _phase the stake type
    /// @param _logic the vault logic address
    function setVaultLogicByPhase(uint256 _phase, address _logic) external;

    /// @dev create vault2
    /// @param _cap  allocated reward amount
    /// @param _miningPerSecond  the mining per second
    /// @param _NonfungiblePositionManager  NonfungiblePositionManager of uniswapV3
    /// @param _UniswapV3Factory  UniswapV3Factory of uniswapV3
    /// @param _token0  token0 address
    /// @param _token1  token1 address
    /// @param _name   name
    function createVault2(
        uint256 _cap,
        uint256 _miningPerSecond,
        address _NonfungiblePositionManager,
        address _UniswapV3Factory,
        address _token0,
        address _token1,
        string memory _name
    ) external;

    /// @dev set pool information
    /// @param target  target address
    /// @param uniswapInfo [NonfungiblePositionManager,UniswapV3Factory,token0,token1]
    function setPool(address target, address[4] memory uniswapInfo) external;

    /// @dev set pool address with tokenId
    /// @param target  target address
    /// @param tokenId  tokenId
    function setPoolAddressWithTokenId(address target, uint256 tokenId)
        external;

    /// @dev Mining interval setting (seconds)
    /// @param target  target address
    /// @param miningIntervalSeconds the mining interval (sec)
    function setMiningIntervalSeconds(
        address target,
        uint256 miningIntervalSeconds
    ) external;

    /// @dev reset coinage's last mining time variable for tes
    /// @param target  target address
    function resetCoinageTime(address target) external;

    /// @dev set the start time of vault2
    /// @param vault  a vault address
    /// @param startTime  mining start time
    function setStartTimeOfVault2(address vault, uint256 startTime) external;

    /// @dev set mining end time
    /// @param vault  a vault address
    /// @param endTime  mining end time
    function setEndTimeOfVault2(address vault, uint256 endTime) external;
}
