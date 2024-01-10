// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./IZDAORegistry.sol";
import "./IZNSHub.sol";

contract ZDAORegistry is IZDAORegistry, OwnableUpgradeable {
  IZNSHub public znsHub;

  mapping(uint256 => uint256) private ensTozDAO;
  mapping(uint256 => uint256) private zNATozDAOId;
  ZDAORecord[] public zDAORecords;

  modifier onlyZNAOwner(uint256 zNA) {
    require(znsHub.ownerOf(zNA) == msg.sender, "Not zNA owner");
    _;
  }

  modifier onlyValidZDAO(uint256 daoId) {
    require(daoId > 0 && daoId < zDAORecords.length, "Invalid daoId");
    _;
  }

  function initialize(address _znsHub) external initializer {
    __Ownable_init();

    znsHub = IZNSHub(_znsHub);
    zDAORecords.push(
      ZDAORecord({id: 0, ensSpace: "", gnosisSafe: address(0), associatedzNAs: new uint256[](0)})
    );
  }

  function setZNSHub(address _znsHub) external onlyOwner {
    znsHub = IZNSHub(_znsHub);
  }

  function addNewDAO(string calldata ensSpace, address gnosisSafe) external onlyOwner {
    uint256 zDAOId = zDAORecords.length;
    zDAORecords.push(
      ZDAORecord({
        id: zDAOId,
        ensSpace: ensSpace,
        gnosisSafe: gnosisSafe,
        associatedzNAs: new uint256[](0)
      })
    );

    emit DAOCreated(zDAOId, ensSpace, gnosisSafe);
  }

  function addZNAAssociation(uint256 daoId, uint256 zNA)
    external
    onlyValidZDAO(daoId)
    onlyZNAOwner(zNA)
  {
    uint256 currentDAOAssociation = zNATozDAOId[zNA];
    require(currentDAOAssociation != daoId, "zNA already linked to DAO");

    // If an association already exists, remove it
    if (currentDAOAssociation != 0) {
      _removeZNAAssociation(currentDAOAssociation, zNA);
    }

    zNATozDAOId[zNA] = daoId;
    zDAORecords[daoId].associatedzNAs.push(zNA);

    emit LinkAdded(daoId, zNA);
  }

  function removeZNAAssociation(uint256 daoId, uint256 zNA)
    external
    onlyValidZDAO(daoId)
    onlyZNAOwner(zNA)
  {
    uint256 currentDAOAssociation = zNATozDAOId[zNA];
    require(currentDAOAssociation == daoId, "zNA not associated");

    _removeZNAAssociation(daoId, zNA);
  }

  function numberOfzDAOs() external view returns (uint256) {
    return zDAORecords.length - 1;
  }

  function getzDAOById(uint256 daoId) external view returns (ZDAORecord memory) {
    return zDAORecords[daoId];
  }

  function listzDAOs(uint256 startIndex, uint256 endIndex)
    external
    view
    returns (ZDAORecord[] memory)
  {
    uint256 numDaos = zDAORecords.length;
    require(startIndex != 0, "start index = 0, use 1");
    require(startIndex <= endIndex, "start index > end");
    require(startIndex < numDaos, "start index > length");
    require(endIndex < numDaos, "end index > length");

    if (numDaos == 1) {
      return new ZDAORecord[](0);
    }

    uint256 numRecords = endIndex - startIndex + 1;
    ZDAORecord[] memory records = new ZDAORecord[](numRecords);

    for (uint256 i = 0; i < numRecords; ++i) {
      records[i] = zDAORecords[startIndex + i];
    }

    return records;
  }

  function getzDaoByZNA(uint256 zNA) external view returns (ZDAORecord memory) {
    uint256 daoId = zNATozDAOId[zNA];
    require(daoId != 0 && daoId < zDAORecords.length, "No zDAO associated with zNA");
    return zDAORecords[daoId];
  }

  function getzDAOByEns(string calldata ensSpace) external view returns (ZDAORecord memory) {
    uint256 ensHash = uint256(keccak256(abi.encodePacked(ensSpace)));
    uint256 daoId = ensTozDAO[ensHash];
    require(daoId != 0, "No zDAO at ens space");
    return zDAORecords[daoId];
  }

  function doeszDAOExistForzNA(uint256 zNA) external view returns (bool) {
    return zNATozDAOId[zNA] != 0;
  }

  function _removeZNAAssociation(uint256 daoId, uint256 zNA) internal {
    ZDAORecord storage dao = zDAORecords[daoId];
    uint256 length = zDAORecords[daoId].associatedzNAs.length;

    for (uint256 i = 0; i < length; i++) {
      if (dao.associatedzNAs[i] == zNA) {
        dao.associatedzNAs[i] = dao.associatedzNAs[length - 1];
        dao.associatedzNAs.pop();
        zNATozDAOId[zNA] = 0;

        emit LinkRemoved(daoId, zNA);
        break;
      }
    }
  }
}
