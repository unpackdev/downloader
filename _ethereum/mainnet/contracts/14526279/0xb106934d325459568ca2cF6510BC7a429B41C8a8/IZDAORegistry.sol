// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IZDAORegistry {
  struct ZDAORecord {
    uint256 id;
    string ensSpace;
    address gnosisSafe;
    uint256[] associatedzNAs;
    bool destroyed;
  }

  // function zNATozDAOId(uint256 zNA) external view returns (uint256);

  function numberOfzDAOs() external view returns (uint256);

  function getzDAOById(uint256 daoId) external view returns (ZDAORecord memory);

  function getzDAOByEns(string calldata ensSpace) external view returns (ZDAORecord memory);

  function listzDAOs(uint256 startIndex, uint256 endIndex)
    external
    view
    returns (ZDAORecord[] memory);

  function doeszDAOExistForzNA(uint256 zNA) external view returns (bool);

  function getzDaoByZNA(uint256 zNA) external view returns (ZDAORecord memory);

  event DAOCreated(uint256 indexed daoId, string ensSpace, address gnosisSafe);
  event DAOModified(uint256 indexed daoId, string endSpace, address gnosisSafe);
  event DAODestroyed(uint256 indexed daoId);
  event LinkAdded(uint256 indexed daoId, uint256 indexed zNA);
  event LinkRemoved(uint256 indexed daoId, uint256 indexed zNA);
}
