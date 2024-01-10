// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./IZDAORegistry.sol";
import "./IZNSHub.sol";

contract ZDAORegistry is IZDAORegistry, OwnableUpgradeable {
  IZNSHub public znsHub;

  mapping(uint256 => uint256) private ensTozDAO;
  mapping(uint256 => uint256) private zNATozDAOId;

  // The zdao at index 0 is a null zDAO
  // We use a mapping instead of an array for upgradeability
  mapping(uint256 => ZDAORecord) public zDAORecords;

  // More of a 'new zdao index' tracker
  uint256 private numZDAOs;

  modifier onlyZNAOwner(uint256 zNA) {
    require(znsHub.ownerOf(zNA) == msg.sender, "Not zNA owner");
    _;
  }

  modifier onlyValidZDAO(uint256 daoId) {
    require(daoId > 0 && daoId < numZDAOs && !zDAORecords[daoId].destroyed, "Invalid zDAO");
    _;
  }

  function initialize(address _znsHub) external initializer {
    __Ownable_init();

    znsHub = IZNSHub(_znsHub);
    zDAORecords[0] = ZDAORecord({
      id: 0,
      ensSpace: "",
      gnosisSafe: address(0),
      associatedzNAs: new uint256[](0),
      destroyed: false
    });

    numZDAOs = 1;
  }

  function addNewDAO(string calldata ensSpace, address gnosisSafe) external onlyOwner {
    uint256 ensId = _ensId(ensSpace);
    require(ensTozDAO[ensId] == 0, "ENS already has zDAO");

    zDAORecords[numZDAOs] = ZDAORecord({
      id: numZDAOs,
      ensSpace: ensSpace,
      gnosisSafe: gnosisSafe,
      associatedzNAs: new uint256[](0),
      destroyed: false
    });

    ensTozDAO[ensId] = numZDAOs;

    emit DAOCreated(numZDAOs, ensSpace, gnosisSafe);

    numZDAOs += 1;
  }

  function addZNAAssociation(uint256 daoId, uint256 zNA)
    external
    onlyValidZDAO(daoId)
    onlyZNAOwner(zNA)
  {
    _associatezNA(daoId, zNA);
  }

  function removeZNAAssociation(uint256 daoId, uint256 zNA)
    external
    onlyValidZDAO(daoId)
    onlyZNAOwner(zNA)
  {
    uint256 currentDAOAssociation = zNATozDAOId[zNA];
    require(currentDAOAssociation == daoId, "zNA not associated");

    _disassociatezNA(daoId, zNA);
  }

  /* --- Admin functions  --- */

  function adminSetZNSHub(address _znsHub) external onlyOwner {
    znsHub = IZNSHub(_znsHub);
  }

  function adminRemoveDAO(uint256 daoId) external onlyValidZDAO(daoId) onlyOwner {
    zDAORecords[daoId].destroyed = true;
    ensTozDAO[_ensId(zDAORecords[daoId].ensSpace)] = 0;

    emit DAODestroyed(daoId);
  }

  function adminAssociateZNA(uint256 daoId, uint256 zNA) external onlyOwner onlyValidZDAO(daoId) {
    _associatezNA(daoId, zNA);
  }

  function adminDisassociateZNA(uint256 daoId, uint256 zNA)
    external
    onlyOwner
    onlyValidZDAO(daoId)
  {
    uint256 currentDAOAssociation = zNATozDAOId[zNA];
    require(currentDAOAssociation == daoId, "zNA not associated");

    _disassociatezNA(daoId, zNA);
  }

  function adminModifyZDAO(
    uint256 daoId,
    string calldata ensSpace,
    address gnosisSafe
  ) external onlyOwner onlyValidZDAO(daoId) {
    ZDAORecord storage zDAO = zDAORecords[daoId];

    uint256 newEnsId = _ensId(ensSpace);
    uint256 existingEnsId = _ensId(zDAO.ensSpace);

    if (newEnsId != existingEnsId) {
      ensTozDAO[existingEnsId] = 0;
      ensTozDAO[newEnsId] = daoId;
    }

    zDAO.ensSpace = ensSpace;
    zDAO.gnosisSafe = gnosisSafe;

    emit DAOModified(daoId, ensSpace, gnosisSafe);
  }

  /* --- View Methods --- */

  // The number of actual zDAO's (excludes '0' which is null)
  function numberOfzDAOs() external view returns (uint256) {
    return numZDAOs - 1;
  }

  function getzDAOById(uint256 daoId) external view returns (ZDAORecord memory) {
    return zDAORecords[daoId];
  }

  function listzDAOs(uint256 startIndex, uint256 endIndex)
    external
    view
    returns (ZDAORecord[] memory)
  {
    uint256 numDaos = numZDAOs;
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
    require(
      daoId != 0 && daoId < numZDAOs && !zDAORecords[daoId].destroyed,
      "No zDAO associated with zNA"
    );
    return zDAORecords[daoId];
  }

  function getzDAOByEns(string calldata ensSpace) external view returns (ZDAORecord memory) {
    uint256 ensHash = _ensId(ensSpace);
    uint256 daoId = ensTozDAO[ensHash];
    require(daoId != 0, "No zDAO at ens space");
    require(!zDAORecords[daoId].destroyed, "zDAO destroyed");

    return zDAORecords[daoId];
  }

  function doeszDAOExistForzNA(uint256 zNA) external view returns (bool) {
    return zNATozDAOId[zNA] != 0;
  }

  /* --- Internal Methods ---  */

  function _associatezNA(uint256 daoId, uint256 zNA) internal {
    uint256 currentDAOAssociation = zNATozDAOId[zNA];
    require(currentDAOAssociation != daoId, "zNA already linked to DAO");

    // If an association already exists, remove it
    if (currentDAOAssociation != 0) {
      _disassociatezNA(currentDAOAssociation, zNA);
    }

    zNATozDAOId[zNA] = daoId;
    zDAORecords[daoId].associatedzNAs.push(zNA);

    emit LinkAdded(daoId, zNA);
  }

  function _disassociatezNA(uint256 daoId, uint256 zNA) internal {
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

  function _ensId(string memory ensSpace) private pure returns (uint256) {
    uint256 ensHash = uint256(keccak256(abi.encodePacked(ensSpace)));
    return ensHash;
  }
}
