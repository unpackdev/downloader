// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Initializable.sol";
import "./ICurve3PoolStrategyStorage.sol";
import "./OhUpgradeable.sol";

contract OhCurve3PoolStrategyStorage is Initializable, OhUpgradeable, ICurve3PoolStrategyStorage {
    bytes32 internal constant _POOL_SLOT = 0x6c9960513c6769ea8f48802ea7b637e9ce937cc3d022135cc43626003296fc46;
    bytes32 internal constant _GAUGE_SLOT = 0x85c79ab2dc779eb860ec993658b7f7a753e59bdfda156c7391620a5f513311e6;
    bytes32 internal constant _MINTR_SLOT = 0x3e7777dca2f9f31e4c2d62ce76af8def0f69b868d665539787b25b39a9f7224f;
    bytes32 internal constant _INDEX_SLOT = 0xd5700a843c20bfe827ca47a7c73f83287e1b32b3cd4ac659d79f800228d617fd;

    constructor() {
        assert(_POOL_SLOT == bytes32(uint256(keccak256("eip1967.curve3PoolStrategy.pool")) - 1));
        assert(_GAUGE_SLOT == bytes32(uint256(keccak256("eip1967.curve3PoolStrategy.gauge")) - 1));
        assert(_MINTR_SLOT == bytes32(uint256(keccak256("eip1967.curve3PoolStrategy.mintr")) - 1));
        assert(_INDEX_SLOT == bytes32(uint256(keccak256("eip1967.curve3PoolStrategy.index")) - 1));
    }

    function initializeCurve3PoolStorage(
        address pool_,
        address gauge_,
        address mintr_,
        uint256 index_
    ) internal initializer {
        _setPool(pool_);
        _setGauge(gauge_);
        _setMintr(mintr_);
        _setIndex(index_);
    }

    function pool() public view override returns (address) {
        return getAddress(_POOL_SLOT);
    }

    function gauge() public view override returns (address) {
        return getAddress(_GAUGE_SLOT);
    }

    function mintr() public view override returns (address) {
        return getAddress(_MINTR_SLOT);
    }

    function index() public view override returns (uint256) {
        return getUInt256(_INDEX_SLOT);
    }

    function _setPool(address pool_) internal {
        setAddress(_POOL_SLOT, pool_);
    }

    function _setGauge(address gauge_) internal {
        setAddress(_GAUGE_SLOT, gauge_);
    }

    function _setMintr(address mintr_) internal {
        setAddress(_MINTR_SLOT, mintr_);
    }

    function _setIndex(uint256 index_) internal {
        setUInt256(_INDEX_SLOT, index_);
    }
}
