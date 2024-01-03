// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./IHegic.sol";

interface IHegicNFT is IERC721 {
    function tokenizeOption(uint256, address) external returns (uint256);

    function isValidToken(uint256) external view returns (bool);

    function getUnderlyingOptionParams(uint256) external view returns (Option memory);

    function exerciseOption(uint256) external returns (uint256);
}
