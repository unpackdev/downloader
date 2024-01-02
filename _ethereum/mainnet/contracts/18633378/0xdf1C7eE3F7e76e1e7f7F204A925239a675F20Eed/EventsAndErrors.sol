// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

contract EventsAndErrors {
  event PaintingFeeUpdated(address indexed wallet, uint256 fee);

  error XXYYZZTokenNotApprovedForTransferByPainter();
  error TogetherTokenNotApprovedForTransferByPainter();
  error IncorrectPaintingFee();
}
