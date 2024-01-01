// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract FeeManager {
    /// @notice token address
    address public token;

    constructor(address _token) {
        require(_token != address(0), "_token address cannot be 0");
        token = _token;
        _lock = _NOT_LOCKED;
    }

    modifier onlyToken() {
        require(msg.sender == token, "only token");
        _;
    }

    uint256 private constant _NOT_LOCKED = 1;
    uint256 private constant _LOCKED = 2;
    uint256 private _lock;

    modifier lock() {
        if (_lock == _NOT_LOCKED) {
            _lock = _LOCKED;
            _;
            _lock = _NOT_LOCKED;
        }
    }

    function syncFee() external onlyToken lock {
        _syncFee();
    }

    function canSyncFee(address sender, address recipient) external view virtual returns (bool shouldSyncFee);

    function _syncFee() internal virtual;
}