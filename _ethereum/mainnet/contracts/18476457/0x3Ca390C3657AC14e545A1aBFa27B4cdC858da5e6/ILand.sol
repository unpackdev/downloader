// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721EnumerableUpgradeable.sol";

interface ILand is IERC721EnumerableUpgradeable {
    event NFTMinted (address to, uint256[] ids);
    event NFTClaimed (address to, uint256 id, uint256 nekoId);

    function currentId() external view returns (uint256);

    function mintToken(address to, bool isClaim, uint256 nekoId) external;

    function mintBatchToken(address to, uint256 amount) external;

    function genesisMinter(address) external view returns (bool);

    function baseURI() external view returns (string memory);
}