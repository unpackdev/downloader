// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
error NotMinter();
error InvalidArgument(uint256 argument);
error InvalidStringArgument();
error NotTokenOwner(uint256 tokenId, address messageSender, address actualOwner);
error NotWithdrawable(uint256 tokenId, uint256 depositId, uint256 maturity);
