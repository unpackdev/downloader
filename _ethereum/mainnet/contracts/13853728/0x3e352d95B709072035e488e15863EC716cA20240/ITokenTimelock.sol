// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;


interface ITokenTimelock {
    function acceptAdmin() external;
    function delay() external view returns (uint256);
    function GRACE_PERIOD() external view returns (uint256);
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function cancelTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external;
    function queueTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external returns (bytes32);
    function executeTransaction(address target, uint256 value, string calldata signature, bytes calldata data, uint256 eta) external payable returns (bytes memory);
}
