// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IStake2Logic.sol";
import "./IERC20.sol";
import "./IStake2Vault.sol";
import "./AccessibleCommon.sol";
import "./StakeProxyStorage.sol";

interface IIStakeUniswapV3 {
    function setPool(address[4] memory uniswapInfo) external;

    function setSaleStartTime(uint256 _saleStartTime) external;

    function setMiningIntervalSeconds(uint256 _intervalSeconds) external;

    function resetCoinageTime() external;

    function setPoolAddress(uint256 tokenId) external;
}

interface IIIStake2Vault {
    function stakeAddress() external view returns (address);
}

/// @title The logic of TOS Plaform
/// @notice Admin can createVault, createStakeContract.
/// User can excute the tokamak staking function of each contract through this logic.

contract Stake2Logic is StakeProxyStorage, AccessibleCommon, IStake2Logic {
    modifier nonZero(uint256 _value) {
        require(_value > 0, "Stake2Logic: zero");
        _;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Stake2Logic: zero address");
        _;
    }

    constructor() {}

    /// @dev Set stakeVaultLogic address by _phase
    /// @param _phase the stake type
    /// @param _logic the vault logic address
    function setVaultLogicByPhase(uint256 _phase, address _logic)
        external
        override
        onlyOwner
        nonZeroAddress(address(stakeVaultFactory))
        nonZeroAddress(_logic)
    {
        stakeVaultFactory.setVaultLogicByPhase(_phase, _logic);
    }

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
    ) external override onlyOwner nonZeroAddress(address(stakeVaultFactory)) {
        uint256 _phase = 2;
        uint256 stakeType = 2;
        bytes32 vaultName = keccak256(abi.encodePacked(_name));
        uint256 cap = _cap;
        uint256 miningPerSecond = _miningPerSecond;

        // console.log("tos %s", tos );
        // console.log("stakeFactory %s", address(stakeFactory) );
        // console.log("miningPerSecond %d , cap %d, stakeType %d ", miningPerSecond, cap , stakeType);
        // console.log("tos %s", tos );

        address vault =
            stakeVaultFactory.create2(
                _phase,
                [tos, address(stakeFactory)],
                [stakeType, cap, miningPerSecond],
                _name,
                address(this)
            );

        require(vault != address(0), "Stake2Logic: vault2 is zero");

        uint256 phase = _phase;
        address[4] memory uniswapInfo =
            [_NonfungiblePositionManager, _UniswapV3Factory, _token0, _token1];

        stakeRegistry.addVault(vault, phase, vaultName);
        emit CreatedVault2(vault, _NonfungiblePositionManager, cap);

        address[4] memory _addr = [tos, address(0), vault, address(0)];
        address _contract =
            stakeFactory.create(
                stakeType,
                _addr,
                address(stakeRegistry),
                [cap, miningPerSecond, 0]
            );
        require(_contract != address(0), "Stake2Logic: vault2 deploy fail");

        IIStakeUniswapV3(_contract).setPool(uniswapInfo);
        IStake2Vault(vault).setStakeAddress(_contract);
        stakeRegistry.addStakeContract(vault, _contract);

        emit CreatedStakeContract2(vault, _contract, phase);
    }

    /// @dev set pool information
    /// @param target  target address
    /// @param uniswapInfo [NonfungiblePositionManager,UniswapV3Factory,token0,token1]
    function setPool(address target, address[4] memory uniswapInfo)
        external
        override
        onlyOwner
        nonZeroAddress(target)
    {
        IIStakeUniswapV3(target).setPool(uniswapInfo);
    }

    /// @dev set pool address with tokenId
    /// @param target  target address
    /// @param tokenId  tokenId
    function setPoolAddressWithTokenId(address target, uint256 tokenId)
        external
        override
        onlyOwner
        nonZeroAddress(target)
        nonZero(tokenId)
    {
        IIStakeUniswapV3(target).setPoolAddress(tokenId);
    }

    /// @dev Mining interval setting (seconds)
    /// @param target  target address
    /// @param miningIntervalSeconds the mining interval (sec)
    function setMiningIntervalSeconds(
        address target,
        uint256 miningIntervalSeconds
    ) external override onlyOwner nonZeroAddress(target) {
        IIStakeUniswapV3(target).setMiningIntervalSeconds(
            miningIntervalSeconds
        );
    }

    /// @dev reset coinage's last mining time variable for tes
    /// @param target  target address
    function resetCoinageTime(address target)
        external
        override
        onlyOwner
        nonZeroAddress(target)
    {
        IIStakeUniswapV3(target).resetCoinageTime();
    }

    /// @dev set the start time of vault2
    /// @param vault  a vault address
    /// @param startTime  mining start time
    function setStartTimeOfVault2(address vault, uint256 startTime)
        external
        override
        onlyOwner
        nonZeroAddress(vault)
    {
        address stakeAddress = IIIStake2Vault(vault).stakeAddress();
        require(
            stakeAddress != address(0),
            "Stake2Logic: stakeAddress is zero"
        );

        IStake2Vault(vault).setMiningStartTime(startTime);
        IIStakeUniswapV3(stakeAddress).setSaleStartTime(startTime);
    }

    /// @dev set mining end time
    /// @param vault  a vault address
    /// @param endTime  mining end time
    function setEndTimeOfVault2(address vault, uint256 endTime)
        external
        override
        onlyOwner
        nonZeroAddress(vault)
    {
        IStake2Vault(vault).setMiningEndTime(endTime);
    }
}
