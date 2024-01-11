// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./Context.sol";
import "./IPoolFactory.sol";
import "./IManager.sol";
import "./Pool.sol";

contract PoolFactory is Context, IPoolFactory {
    address public override treasury;

    address public override WNATIVE;
    IManager public manager;

    uint256 public feeRatio = 0;
    uint256 public BONE = 1e4;

    // map of created pools - by reward token
    mapping(address => address) public override rewardPools;

    constructor(
        address _treasury,
        address _nativeToken,
        address _manager
    ) {
        treasury = _treasury;
        WNATIVE = _nativeToken; // @dev _nativeToken must be a wrapped native token or all subsequent pool logic will fail
        manager = IManager(_manager);
    }

    modifier onlyAdmin() {
        require(manager.isAdmin(_msgSender()), "Pool::onlyAdmin");
        _;
    }

    modifier onlyGovernance() {
        require(manager.isGorvernance(_msgSender()), "Pool::onlyGovernance");
        _;
    }

    /*
     * @notice Deploy a reward pool
     * @param _rewardToken: reward token address for POOL rewards
     * @param _rewardPerBlock: the amountof tokens to reward per block for the entire POOL
     * remaining parmas define the condition variables for the first NATIVE token staking pool for this REWARD
     */
    function deployPool(
        address _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _nativeAllocPoint,
        uint256 _nativeStartBlock,
        uint256 _nativeBonusMultiplier,
        uint256 _nativeBonusEndBlock,
        uint256 _nativeMinStakePeriod
    ) external override onlyAdmin {
        require(rewardPools[_rewardToken] == address(0), "PoolFactory::deployPool: REWARD_POOL_ALREADY_DEPLOYED");

        bytes memory bytecode = type(Pool).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(
                _rewardToken,
                _rewardPerBlock,
                treasury,
                _nativeAllocPoint,
                _nativeStartBlock,
                _nativeBonusMultiplier,
                _nativeBonusEndBlock,
                _nativeMinStakePeriod
            )
        );
        address poolAddress;

        assembly {
            poolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        rewardPools[_rewardToken] = poolAddress;

        IPool(poolAddress).initialize(
            _rewardToken,
            _rewardPerBlock,
            treasury,
            WNATIVE,
            _nativeAllocPoint,
            _nativeStartBlock,
            _nativeBonusMultiplier,
            _nativeBonusEndBlock,
            _nativeMinStakePeriod,
            address(manager)
        );

        emit PoolCreated(_rewardToken, poolAddress);
    }

    // Update Treasury. NOTE: better for treasury to be upgradable so no need to use this.
    function setTreasury(address newTreasury) external override onlyAdmin {
        treasury = newTreasury;
    }

    // Update Wrapped Native implementation, @dev this must be a wrapped native token or all subsequent pool logic can fail
    // NOTE: better for WNATIVE to be upgradable so no need to use this.
    function setNative(address newNative) external override onlyAdmin {
        WNATIVE = newNative;
    }

    function setFeeRatio(uint256 _feeRatio, uint256 _BONE) external override onlyGovernance {
        feeRatio = _feeRatio;
        BONE = _BONE;
    }

    function getFee() external view override returns (uint256, uint256) {
        return (feeRatio, BONE);
    }
}
