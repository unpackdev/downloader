//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./IERC721Receiver.sol";

interface IFlashNFTReceiver is IERC721Receiver {
    function executeOperation(address nftAddress, uint256 nftId, uint256 feeInWeth, address msgSender, bytes calldata data) external returns (bool);
}