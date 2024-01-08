//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPalette {
  /// @dev Returns the total amount of tokens stored by the contract.
  function totalSupply() external view returns (uint256);

  /// @dev Returns the remaining amount of tokens.
  function remainingSupply() external view returns (uint256);

  /// @dev Mints new token and transfers it to msgSender.
  function mint() external;

  /// @dev tokenId is from 1 to MAX_SUPPLY.
  function getPalette(uint256 tokenId) external view returns (string[5] memory);

  /// @dev specifying a multiple of 16 for seed will change the color code.
  function getRandomColorCode(uint256 seed) external view returns (string memory);

  /**
   * @dev hue: 0 ~ 360
   *      saturation: 0 ~ 100
   *      brightness: 0 ~ 100
   */
  function getColorCodeFromHSV(
    uint256 hue,
    uint256 saturation,
    uint256 brightness
  ) external pure returns (string memory);
}
