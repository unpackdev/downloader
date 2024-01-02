// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

import "./IERC721.sol";
import "./Together.sol";
import "./EventsAndErrors.sol";

/// @title Painter
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice Painter is a protocol that allows for painting of a Together collector's NFTs via an XXYYZZ collector's NFTs.
contract Painter is EventsAndErrors {
  mapping(address wallet => uint256 fee) public paintingFees;
  mapping(address wallet => uint256 earnings) public paintingEarnings;
  address private immutable _together;
  address private immutable _xxyyzz;

  constructor(address together, address xxyyzz) {
    _together = together;
    _xxyyzz = xxyyzz;
  }

  /// @notice Set painting fee that you will be paid when Together collectors use your
  /// XXYYZZ NFTs to paint their Together NFTs.
  /// @param fee painting fee (in wei)
  function setPaintingFee(uint256 fee) external {
    paintingFees[msg.sender] = fee;
    emit PaintingFeeUpdated(msg.sender, fee);
  }

  /// @notice Withdraw earnings that you accumulated when Together collectors used your
  /// XXYYZZ NFTs to paint their Together NFTs.
  function withdrawPaintingEarnings() external {
    // Effects
    uint256 earnings = paintingEarnings[msg.sender];
    paintingEarnings[msg.sender] = 0;

    // Interactions
    (bool success, ) = msg.sender.call{ value: earnings }("");
    require(success);
  }

  /// @notice Paint your Together NFT with an XXYYZZ NFT.
  /// @param togetherTokenId Together token id
  /// @param xxyyzzTokenId XXYYZZ token id
  function paint(uint16 togetherTokenId, uint24 xxyyzzTokenId) external payable {
    address xxyyzzTokenOwner = IERC721(_xxyyzz).ownerOf(xxyyzzTokenId);

    if (!IERC721(_xxyyzz).isApprovedForAll(xxyyzzTokenOwner, address(this))) {
      // Check if xxyyzz token owner approved this contract
      revert XXYYZZTokenNotApprovedForTransferByPainter();
    }

    if (!IERC721(_together).isApprovedForAll(msg.sender, address(this))) {
      // Check if Together msg sender approved this contract
      revert TogetherTokenNotApprovedForTransferByPainter();
    }

    if (msg.value != paintingFees[xxyyzzTokenOwner]) {
      // Check if the correct painting fee was sent for this particular xxyyzz token owner
      revert IncorrectPaintingFee();
    }

    // Update xxyyzz token owner earnings with the painting fee
    unchecked {
      paintingEarnings[xxyyzzTokenOwner] += msg.value;
    }

    // Transfer Together NFT to this contract
    IERC721(_together).transferFrom(msg.sender, address(this), togetherTokenId);

    // Transfer xxyyzz NFT to this contract
    IERC721(_xxyyzz).transferFrom(xxyyzzTokenOwner, address(this), xxyyzzTokenId);

    // Paint Together NFT with XXYYZZ color
    Together(_together).colorBackground(togetherTokenId, xxyyzzTokenId);

    // Transfer Together NFT back to msg sender
    IERC721(_together).transferFrom(address(this), msg.sender, togetherTokenId);

    // Transfer xxyyzz NFT back to original owner
    IERC721(_xxyyzz).transferFrom(address(this), xxyyzzTokenOwner, xxyyzzTokenId);
  }
}
