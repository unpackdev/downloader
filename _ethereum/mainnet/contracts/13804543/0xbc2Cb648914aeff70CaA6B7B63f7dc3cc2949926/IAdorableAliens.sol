// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "./IERC721.sol";
import "./IERC721Metadata.sol";

interface IAdorableAliens is IERC721, IERC721Metadata {
    function balanceOf(address owner) external override view returns (uint256 balance);
}
