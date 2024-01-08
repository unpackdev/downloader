// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Initializable.sol";
import "./IStrategyStorage.sol";
import "./OhUpgradeable.sol";

contract OhStrategyStorage is Initializable, OhUpgradeable, IStrategyStorage {
    bytes32 internal constant _BANK_SLOT = 0xd2eff96e29993ca5431993c3a205e12e198965c0e1fdd87b4899b57f1e611c74;
    bytes32 internal constant _UNDERLYING_SLOT = 0x0fad97fe3ec7d6c1e9191a09a0c4ccb7a831b6605392e57d2fedb8501a4dc812;
    bytes32 internal constant _DERIVATIVE_SLOT = 0x4ff4c9b81c0bf267e01129f4817e03efc0163ee7133b87bd58118a96bbce43d3;
    bytes32 internal constant _REWARD_SLOT = 0xaeb865605058f37eedb4467ee2609ddec592b0c9a6f7f7cb0db3feabe544c71c;

    constructor() {
        assert(_BANK_SLOT == bytes32(uint256(keccak256("eip1967.strategy.bank")) - 1));
        assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategy.underlying")) - 1));
        assert(_DERIVATIVE_SLOT == bytes32(uint256(keccak256("eip1967.strategy.derivative")) - 1));
        assert(_REWARD_SLOT == bytes32(uint256(keccak256("eip1967.strategy.reward")) - 1));
    }

    function initializeStorage(
        address bank_,
        address underlying_,
        address derivative_,
        address reward_
    ) internal initializer {
        _setBank(bank_);
        _setUnderlying(underlying_);
        _setDerivative(derivative_);
        _setReward(reward_);
    }

    /// @notice The Bank that the Strategy is associated with
    function bank() public view override returns (address) {
        return getAddress(_BANK_SLOT);
    }

    /// @notice The underlying token the Strategy invests in AaveV2
    function underlying() public view override returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    /// @notice The derivative token received from AaveV2 (aToken)
    function derivative() public view override returns (address) {
        return getAddress(_DERIVATIVE_SLOT);
    }

    /// @notice The reward token received from AaveV2 (stkAave)
    function reward() public view override returns (address) {
        return getAddress(_REWARD_SLOT);
    }

    function _setBank(address _address) internal {
        setAddress(_BANK_SLOT, _address);
    }

    function _setUnderlying(address _address) internal {
        setAddress(_UNDERLYING_SLOT, _address);
    }

    function _setDerivative(address _address) internal {
        setAddress(_DERIVATIVE_SLOT, _address);
    }

    function _setReward(address _address) internal {
        setAddress(_REWARD_SLOT, _address);
    }
}
