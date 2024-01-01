// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface IBridgeAdminOracle {
    function getFee() external view returns (uint256);
    function checkChain(uint64 chainId) external view returns(bool);
    function getFeeReceiver() external view returns (address);
    function checkToken(address _token) external view returns(bool);
}
