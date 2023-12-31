// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

contract Initializable {
    bool private _initialized = false;

    modifier initializer() {
        // solhint-disable-next-line reason-string
        require(!_initialized);
        _;
        _initialized = true;
    }

    function initialized() external view returns (bool) {
        return _initialized;
    }
}
