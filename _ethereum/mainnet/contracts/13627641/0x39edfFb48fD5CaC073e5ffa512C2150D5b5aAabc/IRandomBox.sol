//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IRandomBox {
    function getPartIds(uint256 index)
        external
        view
        returns (uint256[] memory partIds);
}
