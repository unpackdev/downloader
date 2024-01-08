// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISwitchAcross {
    function feeWallet() external view returns (address);
    function totalSlideOfToken(address _token) external view returns (uint);
    function collectSlide(address _token) external returns (uint amount);
    function inSn() external view returns (uint);
    function outSn() external view returns (uint);
    function transferIn(address _to, address[] memory _tokens, uint[] memory _values) external payable;
    function transferOut(address _from, address[] memory _tokens, uint[] memory _values, bytes memory _signature) external;
    function queryWithdraw(address _token, uint _value) external view returns (uint);
}
