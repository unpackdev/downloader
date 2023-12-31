// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID4ARoyaltySplitterFactory {
    function createD4ARoyaltySplitter(
        address protocolFeePool,
        uint256 protocolShare,
        address daoFeePool,
        uint256 daoShare
    )
        external
        returns (address);
}
