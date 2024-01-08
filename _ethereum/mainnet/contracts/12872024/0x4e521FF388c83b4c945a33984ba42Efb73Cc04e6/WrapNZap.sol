// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./IWrappedETH.sol";

contract WrapNZap {
    address public zappee;
    IWrappedETH public wrapper;

    constructor(address _zappee, address _wrapper) payable {
        zappee = _zappee;
        wrapper = IWrappedETH(_wrapper);
        if (msg.value > 0) {
            _zap(msg.value);
        }
    }

    function poke() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "WrapNZap: no balance");

        _zap(balance);
    }

    function _zap(uint256 value) internal {
        // wrap
        wrapper.deposit{value: value}();

        // send to zappee
        require(wrapper.transfer(zappee, value), "WrapNZap: transfer failed");
    }

    receive() external payable {
        _zap(msg.value);
    }
}
