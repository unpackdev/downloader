// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

/*
 ▄████▄   ██▀███   ▄▄▄      ▒███████▒▓██   ██▓
▒██▀ ▀█  ▓██ ▒ ██▒▒████▄    ▒ ▒ ▒ ▄▀░ ▒██  ██▒
▒▓█    ▄ ▓██ ░▄█ ▒▒██  ▀█▄  ░ ▒ ▄▀▒░   ▒██ ██░
▒▓▓▄ ▄██▒▒██▀▀█▄  ░██▄▄▄▄██   ▄▀▒   ░  ░ ▐██▓░
▒ ▓███▀ ░░██▓ ▒██▒ ▓█   ▓██▒▒███████▒  ░ ██▒▓░
░ ░▒ ▒  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░▒▒ ▓░▒░▒   ██▒▒▒
  ░  ▒     ░▒ ░ ▒░  ▒   ▒▒ ░░░▒ ▒ ░ ▒ ▓██ ░▒░
░          ░░   ░   ░   ▒   ░ ░ ░ ░ ░ ▒ ▒ ░░
░ ░         ░           ░  ░  ░ ░     ░ ░
░                           ░         ░ ░
 ▄████▄   ██▓     ▒█████   █     █░ ███▄    █   ██████
▒██▀ ▀█  ▓██▒    ▒██▒  ██▒▓█░ █ ░█░ ██ ▀█   █ ▒██    ▒
▒▓█    ▄ ▒██░    ▒██░  ██▒▒█░ █ ░█ ▓██  ▀█ ██▒░ ▓██▄
▒▓▓▄ ▄██▒▒██░    ▒██   ██░░█░ █ ░█ ▓██▒  ▐▌██▒  ▒   ██▒
▒ ▓███▀ ░░██████▒░ ████▓▒░░░██▒██▓ ▒██░   ▓██░▒██████▒▒
░ ░▒ ▒  ░░ ▒░▓  ░░ ▒░▒░▒░ ░ ▓░▒ ▒  ░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░
  ░  ▒   ░ ░ ▒  ░  ░ ▒ ▒░   ▒ ░ ░  ░ ░░   ░ ▒░░ ░▒  ░ ░
░          ░ ░   ░ ░ ░ ▒    ░   ░     ░   ░ ░ ░  ░  ░
░ ░          ░  ░    ░ ░      ░             ░       ░
░

Crazy Clowns Insane Asylum
2021, V1.1
https://ccia.io
*/

interface INFTStaking {
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

  function NFTTokens(address) external view returns (address);

  function addEvolvePath(
    address from_address,
    address to_address,
    bool burn_original,
    address fee_contract,
    uint256 evolve_fee
  ) external;

  function addNftReward(address contract_address, uint256 reward_per_block_day) external;

  function blockPerDay() external view returns (uint256);

  function claimAll(address _tokenAddress) external;

  function claimReward(
    address _user,
    address _tokenAddress,
    uint256 _tokenId
  ) external;

  function dailyReward(address) external view returns (uint256);

  function deleteEvolvePath(address from_address) external;

  function emergencyUnstake(address _tokenAddress, uint256 _tokenId) external;

  function evolvePath(address original_nft_address, uint256 token_id) external;

  function evolvePathList(address)
    external
    view
    returns (
      address to_address,
      bool burn_original,
      address fee_contract,
      uint256 evolve_fee
    );

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function getStakedTokens(address _user, address _tokenAddress) external view returns (uint256[] memory tokenIds);

  function grantRole(bytes32 role, address account) external;

  function hasRole(bytes32 role, address account) external view returns (bool);

  function pendingReward(
    address _user,
    address _tokenAddress,
    uint256 _tokenId
  ) external view returns (uint256);

  function removeNftReward(address contract_address) external;

  function renounceRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function rewardsToken() external view returns (address);

  function stake(
    address _tokenAddress,
    uint256 _tokenId,
    address _account
  ) external;

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function tokenOwner(address, uint256) external view returns (address);

  function unstake(address _tokenAddress, uint256 _tokenId) external;

  function updateBlockPerDay(uint256 _blockPerDay) external;
}
