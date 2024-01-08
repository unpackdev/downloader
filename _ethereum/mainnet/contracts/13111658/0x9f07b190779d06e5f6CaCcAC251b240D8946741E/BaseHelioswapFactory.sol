// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IBaseHelioswapFactory.sol";
import "./HelioswapConstants.sol";
import "./SafeCast.sol";
import "./BaseModule.sol";

contract BaseHelioswapFactory is IBaseHelioswapFactory, BaseModule, Ownable, Pausable {
    using SafeCast for uint256;

    uint256 private _defaultFee;
    uint256 private _defaultSlippageFee;
    uint256 private _defaultDecayPeriod;

    constructor(address _mothership) public BaseModule(_mothership) {
        _defaultFee = HelioswapConstants._DEFAULT_FEE.toUint104();
        _defaultSlippageFee = HelioswapConstants._DEFAULT_SLIPPAGE_FEE.toUint104();
        _defaultDecayPeriod = HelioswapConstants._DEFAULT_DECAY_PERIOD.toUint104();
    }

    function shutdown() external onlyOwner {
        _pause();
    }

    function isActive() external view override returns (bool) {
        return !paused();
    }

    function defaults()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (_defaultFee, _defaultSlippageFee, _defaultDecayPeriod);
    }

    function defaultFee() external view override returns (uint256) {
        return _defaultFee;
    }

    function defaultSlippageFee() external view override returns (uint256) {
        return _defaultSlippageFee;
    }

    function defaultDecayPeriod() external view override returns (uint256) {
        return _defaultDecayPeriod;
    }

    function setDefaultFee(uint256 _fee) external onlyOwner override returns (uint256) {
        _defaultFee = _fee;
        return _defaultFee;
    }

    function setDefaultSlippageFee(uint256 _slippageFee)
        external
        onlyOwner
        override
        returns (uint256)
    {
        _defaultSlippageFee = _slippageFee;
        return _defaultSlippageFee;
    }

    function setDefaultDecayPeriod(uint256 _decayPeriod)
        external
        onlyOwner
        override
        returns (uint256)
    {
        _defaultDecayPeriod = _decayPeriod;
        return _defaultDecayPeriod;
    }
}
