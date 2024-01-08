// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchTreasurySubscriber {
    function subscribeTreasury(address _sender, address _from, address _to, address _token, uint _value) external returns (bool);
}
