// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IHeroManager {
  function heroPower(uint256 heroId) external view returns (uint256);

  function heroPrimaryAttribute(uint256 heroId) external view returns (uint256);

  function heroLevel(uint256 heroId) external view returns (uint256);

  function bulkExpUp(uint256[] calldata heroIds, bool won) external;

  function heroEnergy(uint256 heroId) external view returns (uint256);

  function spendHeroEnergy(uint256 heroId) external;

  function expUp(uint256 heroId, bool won) external;

  function token() external view returns (address);

  function nft() external view returns (address);

  function validateHeroIds(uint256[] calldata heroIds, address owner)
    external
    view
    returns (bool);

  function validateHeroEnergies(uint256[] calldata heroIds)
    external
    view
    returns (bool);

  function rewardsPayeer() external view returns (address);
}
