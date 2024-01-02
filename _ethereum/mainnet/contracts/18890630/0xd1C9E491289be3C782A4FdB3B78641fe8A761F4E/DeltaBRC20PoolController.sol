// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./DeltaBRC20PoolProxy.sol";
import "./IDeltaPool.sol";
import "./IDeltaPoolController.sol";

contract DeltaBRC20PoolController is Ownable, IDeltaPoolController {
    bool private initialized;

    address[] public pools;
    address public poolImplementation;
    address public poolAdmin;
    address public devAddress;

    uint256[] public levelOfStakeCounts;
    uint256[] public defaultShareAllocRulers; // base  100000
    uint256 public maxLevel; // 1 - 5

    event PoolCreated(
        address pool,
        address[5] args1,
        uint256[6] args2,
        IDeltaNFT.UnlockArgs unlockArgs
    );

    event PoolImplementationUpdated(address poolImplementation);
    event PoolCreated(address pool);
    event SetShareAlloc(uint256 level, uint val);
    event SetLevelOfPower(uint256 level, uint val);

    event DevAddressUpdated(address devAddress);

    function initialize(
        address _owner,
        address _devAddress,
        address _poolImplementation,
        address _poolAdmin,
        uint256[] memory stakeAmounts,
        uint256[] memory shareAllocs
    ) external {
        require(!initialized, "initialize: Already initialized!");
        _transferOwnership(_owner);
        devAddress = _devAddress;
        poolImplementation = _poolImplementation;
        poolAdmin = _poolAdmin;

        for (uint256 i = 0; i < stakeAmounts.length; i++) {
            levelOfStakeCounts.push(stakeAmounts[i]);
        }

        for (uint256 i = 0; i < shareAllocs.length; i++) {
            defaultShareAllocRulers.push(shareAllocs[i]);
        }

        maxLevel = levelOfStakeCounts.length;
        initialized = true;
    }

    function updatePoolImplementation(
        address _poolImplementation
    ) external onlyOwner {
        poolImplementation = _poolImplementation;
        emit PoolImplementationUpdated(_poolImplementation);
    }

    function createPoolProxy(
        address[5] calldata args1,
        uint256[6] calldata args2,
        IDeltaNFT.UnlockArgs calldata _unlockArgs,
        bytes32 _merkleRoot
    ) external onlyOwner {
        DeltaBRC20PoolProxy pool = new DeltaBRC20PoolProxy(
            poolImplementation,
            poolAdmin,
            abi.encodeWithSignature(
                "initialize(address[5],uint256[6])",
                args1,
                args2
            )
        );

        address poolAddress = address(pool);

        IDeltaNFT(args1[4]).grantRole(
            keccak256(bytes("ROLE_MINTER")),
            poolAddress
        );

        IDeltaPool(poolAddress).setUnlockArgsAddRoot(_unlockArgs, _merkleRoot);
        pools.push(poolAddress);
        emit PoolCreated(poolAddress, args1, args2, _unlockArgs);
    }

    function setShareAlloc(uint256 level, uint val) external onlyOwner {
        require(level < maxLevel, "error level");
        defaultShareAllocRulers[level] = val;
        emit SetShareAlloc(level, val);
    }

    function getShareAlloc(
        uint256 level
    ) external view override returns (uint256) {
        require(level < maxLevel, "error level");
        return defaultShareAllocRulers[level];
    }

    function setLevelOfPower(
        uint256 levelBorder,
        uint borderValue
    ) external onlyOwner {
        require(levelBorder < maxLevel, "error border");
        levelOfStakeCounts[levelBorder] = borderValue;
        emit SetLevelOfPower(levelBorder, borderValue);
    }

    function getLevelByAmount(
        uint256 stakeAmount
    ) external view override returns (uint256) {
        if (stakeAmount < levelOfStakeCounts[0]) {
            return 0;
        } else {
            for (uint256 i = maxLevel - 1; i > 0; i--) {
                if (stakeAmount >= levelOfStakeCounts[i]) {
                    return i + 1;
                }
            }
        }
        return 1;
    }

    function updatedDevAddress(address _devAddress) external onlyOwner {
        devAddress = _devAddress;
        emit DevAddressUpdated(_devAddress);
    }

    function getDevAddress() external view override returns (address) {
        return devAddress;
    }

    function getMaxLevel() external view override returns (uint256) {
        return maxLevel;
    }

    function allPoolsOf(uint256 index) external view returns (address) {
        return pools[index];
    }

    function allPoolsOfLength() external view returns (uint256) {
        return pools.length;
    }
}
