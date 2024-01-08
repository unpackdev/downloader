// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchTicket {
    function changeOwner(address _user) external;
    function mint(address to, uint value) external returns (bool);
    function burn(address from, uint value) external returns (bool);
}
