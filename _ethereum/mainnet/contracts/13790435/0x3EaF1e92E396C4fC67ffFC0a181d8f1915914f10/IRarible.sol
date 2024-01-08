// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";

interface IRarible is IERC721Enumerable, IERC721Metadata {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}
