// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccount {
    function init(address _authCenter) external;
    
    function getBalance(address[] memory _tokens) external view returns (uint256, uint256[] memory);

    function pull(
        address token,
        uint256 amt,
        address to
    ) external returns (uint256 _amt);

    function push(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);
}
