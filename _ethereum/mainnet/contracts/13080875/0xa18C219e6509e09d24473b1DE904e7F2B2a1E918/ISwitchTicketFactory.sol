// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchTicketFactory {
    function treasury() external view returns (address);
    function getTokenMap(address _token) external view returns (address);
    function isTicket(address _ticket) external view returns (bool);
    function deposit(address _token, uint _value, address _to) external payable returns (address);
    function queryWithdrawInfo(address _user, address _ticket) external view returns (uint balance, uint amount);
    function queryWithdraw(address _user, address _ticket) external view returns (uint);
    function withdraw(bool isETH, address _to, address _ticket, uint _value) external returns (bool);
}