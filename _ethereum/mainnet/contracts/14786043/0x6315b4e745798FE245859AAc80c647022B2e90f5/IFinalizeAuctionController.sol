// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFinalizeAuctionController {
    function finalize(uint32 _auctionId) external;

    function cancel(uint32 _auctionId) external;

    function adminCancel(uint32 _auctionId, string memory _reason) external;

    function getAuctionType() external view returns (string memory);
}
