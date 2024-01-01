// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IEtherspotWalletFactory {
    function getAddress(
        address owner,
        uint256 index
    ) external view returns (address proxy);
}
