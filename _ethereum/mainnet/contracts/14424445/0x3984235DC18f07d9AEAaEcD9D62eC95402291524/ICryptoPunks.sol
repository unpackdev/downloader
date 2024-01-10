// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ICryptoPunks {
    function punkIndexToAddress(uint256 punkIndex)
        external
        view
        returns (address owner);
}
