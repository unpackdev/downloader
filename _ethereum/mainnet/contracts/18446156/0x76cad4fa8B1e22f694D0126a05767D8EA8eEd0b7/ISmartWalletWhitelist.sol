// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ISmartWalletWhitelist {
    function check(address) external view returns (bool);
}
