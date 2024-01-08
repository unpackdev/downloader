// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Initializable.sol";
import "./IAaveV2StrategyStorage.sol";
import "./OhUpgradeable.sol";

contract OhAaveV2StrategyStorage is Initializable, OhUpgradeable, IAaveV2StrategyStorage {
    bytes32 internal constant _STAKED_TOKEN_SLOT = 0x6ffcc641b9dd32ae63496168decfef38477654371686576c048aacac7664aa89;
    bytes32 internal constant _LENDING_POOL_SLOT = 0x32da969ce0980814ec712773a44ab0fbc7a926f6c25ab5c3ab143cbaf257713b;
    bytes32 internal constant _INCENTIVES_CONTROLLER_SLOT = 0x8354a0ba382ef5f265c75cfb638fc27db941b9db0fd5dc17719a651d5d4cda15;
    bytes32 internal constant _REWARD_COOLDOWN_SLOT = 0x29ba1167c1adca0c8d6bf06d5964666a1db7a70ebfda62e977c0e3331d7b3923;

    constructor() {
        assert(_STAKED_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.aaveV2Strategy.stakedToken")) - 1));
        assert(_LENDING_POOL_SLOT == bytes32(uint256(keccak256("eip1967.aaveV2Strategy.lendingPool")) - 1));
        assert(_INCENTIVES_CONTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.aaveV2Strategy.incentivesController")) - 1));
        assert(_REWARD_COOLDOWN_SLOT == bytes32(uint256(keccak256("eip1967.aaveV2Strategy.rewardCooldown")) - 1));
    }

    function initializeAaveV2Storage(
        address stakedToken_,
        address lendingPool_,
        address incentiveController_
    ) internal initializer {
        _setStakedToken(stakedToken_);
        _setLendingPool(lendingPool_);
        _setIncentiveController(incentiveController_);
        _setRewardCooldown(block.timestamp + 864000); // initialize with 10 day reward lag
    }

    function stakedToken() public view override returns (address) {
        return getAddress(_STAKED_TOKEN_SLOT);
    }

    function lendingPool() public view override returns (address) {
        return getAddress(_LENDING_POOL_SLOT);
    }

    function incentivesController() public view override returns (address) {
        return getAddress(_INCENTIVES_CONTROLLER_SLOT);
    }

    function rewardCooldown() public view returns (uint256) {
        return getUInt256(_REWARD_COOLDOWN_SLOT);
    }

    function _setStakedToken(address stakedToken_) internal {
        setAddress(_STAKED_TOKEN_SLOT, stakedToken_);
    }

    function _setLendingPool(address lendingPool_) internal {
        setAddress(_LENDING_POOL_SLOT, lendingPool_);
    }

    function _setIncentiveController(address incentiveController_) internal {
        setAddress(_INCENTIVES_CONTROLLER_SLOT, incentiveController_);
    }

    function _setRewardCooldown(uint256 rewardCooldown_) internal {
        setUInt256(_REWARD_COOLDOWN_SLOT, rewardCooldown_);
    }
}
