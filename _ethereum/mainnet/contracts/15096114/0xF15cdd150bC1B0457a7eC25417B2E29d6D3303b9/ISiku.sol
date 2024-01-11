
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;
import "./IERC721AQueryableUpgradeable.sol";

interface ISiku is IERC721AQueryableUpgradeable{
    error onlyWhitelistedAllowed();

    function mint(uint256 quantity, bytes32[] calldata _proof) payable external;
    function setBaseURI(string memory _baseTokenURI) external;
}