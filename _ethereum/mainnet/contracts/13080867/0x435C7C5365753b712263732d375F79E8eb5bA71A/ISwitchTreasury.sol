// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchTreasury {
    function tokenBalanceOf(address _token) external returns (uint);
    function mint(address _token, address _to, uint _value) external returns (uint);
    function burn(address _token, address _from, uint _value) external returns (uint);
    function deposit(address _from, address _token, uint _value) external payable returns (uint);
    function queryWithdraw(address _user, address _token) external view returns (uint);
    function withdraw(bool _isETH, address _to, address _token, uint _value) external returns (uint);
}
