//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IComptroller {
    function buyShares(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata
    ) external returns (uint256[] memory sharesReceivedAmounts_);

    function redeemSharesDetailed(
        uint256,
        address[] calldata,
        address[] calldata
    ) external returns (address[] memory, uint256[] memory);

    function callOnExtension(
        address,
        uint256,
        bytes calldata
    ) external;
}
