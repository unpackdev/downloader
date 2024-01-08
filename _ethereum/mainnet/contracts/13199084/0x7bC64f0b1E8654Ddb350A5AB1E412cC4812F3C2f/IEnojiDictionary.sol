//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IEnojiDictionary {
    function emoji(uint256 i) external view returns (string memory);

    function emojisCount() external view returns (uint256);

    function color(uint256 i) external view returns (string memory);

    function colorsCount() external view returns (uint256);
}
