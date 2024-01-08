// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./Ownable.sol";
import "./Strings.sol";
import "./OpenSeaWhitelistERC721.sol";
import "./IEthMap.sol";


contract ETHMapZones is OpenSeaWhitelistERC721("ETHMap Zones", "ZONES"), Ownable() {
/** ==========  Constants  ========== */

  IEthMap public constant map = IEthMap(0xB6bbf89c3DbBa20Cb4d5cABAa4A386ACbbAb455e);
  address public immutable oldContract;

/** ==========  Storage  ========== */

  mapping(uint256 => address) public pendingZoneOwners;

/** ==========  Constructor  ========== */

  constructor(address _oldContract) {
    _setBaseURI("https://ethmap.world/");
    oldContract = _oldContract;
  }

/** ==========  Queries  ========== */

  function baseTokenURI() public view virtual returns (string memory) {
    return baseURI();
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
  }

  function canWrapZone(uint256 id) public view returns (bool) {
    return pendingZoneOwners[id] == msg.sender && zoneOwner(id) == address(this);
  }

  function zoneOwner(uint256 zoneId) internal view returns (address owner) {
    (,owner,) = map.getZone(zoneId);
  }

/** ==========  Actions  ========== */

  function _wrap(uint256 zoneId) internal {
    (,address owner, uint256 sellPrice) = map.getZone(zoneId);
    require(owner == address(this), "ETHMapZones: Contract has not received zone.");
    pendingZoneOwners[zoneId] = address(0);
    if (sellPrice > 0) {
      map.sellZone(zoneId, 0);
    }
    _mint(msg.sender, zoneId);
  }

  function migrate(uint256 zoneId) external {
    IERC721(oldContract).transferFrom(msg.sender, address(this), zoneId);
    ETHMapZones(oldContract).unwrapZone(zoneId);
    _wrap(zoneId);
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    _setBaseURI(_baseURI);
  }

  function prepareToWrapZone(uint256 zoneId) external {
    require(zoneOwner(zoneId) == msg.sender, "ETHMapZones: caller is not zone owner.");
    pendingZoneOwners[zoneId] = msg.sender;
  }

  function wrapZone(uint256 zoneId) external {
    require(pendingZoneOwners[zoneId] == msg.sender, "ETHMapZones: Zone not prepared for wrap.");
    _wrap(zoneId);
  }

  function unwrapZone(uint256 zoneId) external {
    require(_isApprovedOrOwner(_msgSender(), zoneId), "ETHMapZones: caller is not owner nor approved.");
    _burn(zoneId);
    map.transferZone(zoneId, _msgSender());
  }

  function claimUnpreparedZone(uint256 zoneId) external onlyOwner {
    require(pendingZoneOwners[zoneId] == address(0), "ETHMapZones: Zone prepared for wrap.");
    require(!_exists(zoneId), "ETHMapZones: Zone already wrapped.");
    require(zoneOwner(zoneId) == address(this), "ETHMapZones: Contract has not received zone.");
    _mint(msg.sender, zoneId);
  }
}