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
  address private constant _TOGETHER = address(0xb04B8B5A0ba5e9e8029DD01DE2CA22Af50926353);
  address private constant _XXYYZZ = address(0xFf6000a85baAc9c4854fAA7155e70BA850BF726b);

  /// @notice Set painting fee that you will be paid when Together collectors use your
  /// XXYYZZ NFTs to paint their Together NFTs.
  /// @param fee painting fee (in wei)
  function setPaintingFee(uint256 fee) external {
    paintingFees[msg.sender] = fee;
    emit PaintingFeeUpdated(msg.sender, fee);
  }

  /// @notice Paint your Together NFT with an XXYYZZ NFT.
  /// @param togetherTokenId Together token id
  /// @param xxyyzzTokenId XXYYZZ token id
  function paint(uint16 togetherTokenId, uint24 xxyyzzTokenId) external payable {
    address xxyyzzTokenOwner = IERC721(_XXYYZZ).ownerOf(xxyyzzTokenId);

    if (!IERC721(_XXYYZZ).isApprovedForAll(xxyyzzTokenOwner, address(this))) {
      // Check if xxyyzz token owner approved this contract
      revert XXYYZZTokenNotApprovedForTransferByPainter();
    }

    if (!IERC721(_TOGETHER).isApprovedForAll(msg.sender, address(this))) {
      // Check if Together msg sender approved this contract
      revert TogetherTokenNotApprovedForTransferByPainter();
    }

    if (msg.value != paintingFees[xxyyzzTokenOwner]) {
      // Check if the correct painting fee was sent for this particular xxyyzz token owner
      revert IncorrectPaintingFee();
    }

    // Transfer Together NFT to this contract
    IERC721(_TOGETHER).transferFrom(msg.sender, address(this), togetherTokenId);

    // Transfer xxyyzz NFT to this contract
    IERC721(_XXYYZZ).transferFrom(xxyyzzTokenOwner, address(this), xxyyzzTokenId);

    // Paint Together NFT with xxyyzz color
    Together(_TOGETHER).colorBackground(togetherTokenId, xxyyzzTokenId);

    // Transfer Together NFT back to msg sender
    IERC721(_TOGETHER).transferFrom(address(this), msg.sender, togetherTokenId);

    // Transfer xxyyzz NFT back to original owner
    IERC721(_XXYYZZ).transferFrom(address(this), xxyyzzTokenOwner, xxyyzzTokenId);

    // Send fee to xxyyzz token owner
    payable(xxyyzzTokenOwner).transfer(msg.value);
  }
}
