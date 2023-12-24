// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./IERC721Receiver.sol";

import "./IBorrowHandlers.sol";

import "./Objects.sol";

interface IBorrowFacet is IBorrowHandlers, IERC721Receiver {
    function borrow(BorrowArg[] calldata args) external returns (uint256[] memory loanIds);
}
