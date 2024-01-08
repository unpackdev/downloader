// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ███    ███ ███████ ████████  █████  ███████ ██   ██ ██ █████████ ███████
// ████  ████ ██         ██    ██   ██ ██      ██  ██  ██ ██     ██    ███
// ██ ████ ██ █████      ██    ███████ ███████ █████   ██ ██     ██   ███
// ██  ██  ██ ██         ██    ██   ██      ██ ██  ██  ██ ██     ██  ███
// ██      ██ ███████    ██    ██   ██ ███████ ██   ██ ██ ██     ██ ███████
// 🥯 bagelface
// 🐦 @bagelface_
// 🎮 bagelface#2027
// 📬 bagelface@protonmail.com

interface ITraitz {
  function mint(uint256 tokenId, address to) external;
  function setMetadataURI(string memory URI) external;
  function setContractURI(string memory URI) external;
  function setBaseTokenURI(string memory URI) external;
  function setPrivateSeed(bytes32 seed) external;
}