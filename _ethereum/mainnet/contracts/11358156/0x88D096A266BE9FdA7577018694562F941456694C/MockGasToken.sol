// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./GasToken.sol";

/* solium-disable */
contract MockGasToken is GasToken {
    // test helpers
    uint public _mintAmount_;
    uint public _freeAmount_;
    uint public _freeUpToAmount_;
    address public _transferTo_;
    uint public _transferAmount_;

    function mint(uint _amount) external override {
        _mintAmount_ = _amount;
    }

    function free(uint _amount) external override returns (bool) {
        _freeAmount_ = _amount;
        return true;
    }

    function freeUpTo(uint _amount) external override returns (uint) {
        _freeUpToAmount_ = _amount;
        return 0;
    }

    function transfer(address _to, uint _amount) external override returns (bool) {
        _transferTo_ = _to;
        _transferAmount_ = _amount;

        return true;
    }

    function balanceOf(address) external view override returns (uint) {
        return 0;
    }
}
