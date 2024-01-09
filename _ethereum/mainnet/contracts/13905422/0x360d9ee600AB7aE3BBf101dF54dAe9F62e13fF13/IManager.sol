// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManager {
    function treasury() external view returns (address);
    function verifier() external view returns (address);
    function vendor() external view returns (address);
    function acceptedPayments(address _token) external view returns (bool);
}
