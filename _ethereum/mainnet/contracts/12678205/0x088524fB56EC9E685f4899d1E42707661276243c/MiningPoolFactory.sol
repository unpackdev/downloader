// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "./Clones.sol";
import "./ERC165.sol";
import "./Address.sol";
import "./IMiningPoolFactory.sol";
import "./IMiningPool.sol";

abstract contract MiningPoolFactory is IMiningPoolFactory, ERC165 {
    using Clones for address;

    address private _controller;

    constructor() ERC165() {
        _registerInterface(IMiningPoolFactory(0).newPool.selector);
        _registerInterface(IMiningPoolFactory(0).poolType.selector);
    }

    function _setController(address controller_) internal {
        _controller = controller_;
    }

    function newPool(address emitter, address baseToken)
        public
        virtual
        override
        returns (address pool)
    {
        address predicted = this.poolAddress(emitter, baseToken);
        if (_isDeployed(predicted)) {
            // already deployed;
            return predicted;
        } else {
            // not deployed;
            bytes32 salt = keccak256(abi.encodePacked(emitter, baseToken));
            pool = _controller.cloneDeterministic(salt);
            require(
                predicted == pool,
                "Different result. This factory has a serious problem."
            );
            IMiningPool(pool).initialize(emitter, baseToken);
            emit NewMiningPool(emitter, baseToken, pool);
            return pool;
        }
    }

    function controller() public view override returns (address) {
        return _controller;
    }

    function getPool(address emitter, address baseToken)
        public
        view
        override
        returns (address)
    {
        address predicted = this.poolAddress(emitter, baseToken);
        return _isDeployed(predicted) ? predicted : address(0);
    }

    function poolAddress(address emitter, address baseToken)
        external
        view
        virtual
        override
        returns (address pool)
    {
        bytes32 salt = keccak256(abi.encodePacked(emitter, baseToken));
        pool = _controller.predictDeterministicAddress(salt);
    }

    function _isDeployed(address pool) private view returns (bool) {
        return Address.isContract(pool);
    }
}
