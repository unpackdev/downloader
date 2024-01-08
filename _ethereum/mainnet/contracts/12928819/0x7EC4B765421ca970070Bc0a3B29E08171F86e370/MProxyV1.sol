// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./EIP20Interface.sol";
import "./MProxyInterface.sol";
import "./SafeEIP20.sol";

contract MProxyV1 is MProxyInterface{

    using SafeEIP20 for EIP20Interface;

    address reservesReceiver;

    constructor(address _reservesReceiver) public {
        reservesReceiver = _reservesReceiver;
    }

    function proxyClaimReward(address asset, address recipient, uint amount) override external{
        EIP20Interface(asset).safeTransferFrom(msg.sender, recipient, amount);
    }

    function proxySplitReserves(address asset, uint amount) override external{
        EIP20Interface(asset).safeTransferFrom(msg.sender, reservesReceiver, amount);
    }

}