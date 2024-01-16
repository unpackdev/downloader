// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./draft-IERC2612.sol";
import "./IERC4626.sol";
import "./IVotes.sol";
import "./IERC1046.sol";
import "./IERC1363.sol";

/// @custom:security-contact security@p00ls.com
interface IP00lsTokenBase is IERC20, IERC1046, IERC1363, IERC2612, IVotes
{
    function owner() external view returns (address);
    function setTokenURI(string calldata) external;
    function setName(address, string calldata) external;
}

/// @custom:security-contact security@p00ls.com
interface IP00lsTokenCreator is IP00lsTokenBase {
    function xCreatorToken() external view returns (IP00lsTokenXCreator);
    function merkleRoot() external view returns (bytes32);
    function isClaimed(uint256) external view returns (bool);
    function claim(uint256, address, uint256, bytes32[] calldata) external;
}

/// @custom:security-contact security@p00ls.com
interface IP00lsTokenXCreator is IP00lsTokenBase, IERC4626 {
    function creatorToken() external view returns (IP00lsTokenCreator);
    function escrow() external view returns (address);
    function convertToAssetsAtBlock(uint256 shares, uint256 blockNumber) external view returns (uint256);
    function __delegate(address, address) external;
}
