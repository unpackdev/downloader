// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IMigratable {
  event Migrated(address _to);

  function migratedTo() external view returns (address _to);
}
