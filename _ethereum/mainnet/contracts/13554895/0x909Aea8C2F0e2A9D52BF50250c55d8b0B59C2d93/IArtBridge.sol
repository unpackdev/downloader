// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./BridgeBeams.sol";

interface IArtBridge {
  function mint(
    uint256 _id,
    uint256 _amount,
    address _to
  ) external;

  function reserve(
    uint256 _id,
    uint256 _amount,
    address _to
  ) external;

  function nextProjectId() external view returns (uint256);

  function projects(uint256 _id)
    external
    view
    returns (
      uint256 id,
      string memory name,
      string memory artist,
      string memory description,
      string memory website,
      uint256 supply,
      uint256 maxSupply,
      uint256 startBlock
    );

  function minters(address _minter) external view returns (bool);

  function projectToTokenPrice(uint256 _id) external view returns (uint256);

  function projectState(uint256 _id)
    external
    view
    returns (BridgeBeams.ProjectState memory);
}
