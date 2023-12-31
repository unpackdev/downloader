// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CartaeMock {
    function mint() external payable {}

    function balanceOf(
        address account,
        uint256 id
    ) public view virtual returns (uint256) {}

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {}
}
