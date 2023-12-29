// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface IFeeWallet {
    function withdraw() external returns (uint);
    function withdrawRaw() external returns (uint);
    function feeToken() external view returns (address);
    function feeTokenRaw() external view returns (address);
}
