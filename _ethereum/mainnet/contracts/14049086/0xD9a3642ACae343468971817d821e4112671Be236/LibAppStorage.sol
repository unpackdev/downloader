pragma solidity ^0.8.0;

import "./StringsUpgradeable.sol";
import "./CountersUpgradeable.sol";

library LibAppStorage {
  using StringsUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  /// Total number of passes to sell.
  uint256 public constant TOTAL = 10500;
  bytes32 constant STORAGE_POSITION = keccak256("staxx.minting.storage");

  struct Presale {
    uint16 free;
    uint16 paid;
    uint32[7] __padding;
  }

  struct AppStorage {
    CountersUpgradeable.Counter counter;
    // Timestamp of the public launch.
    uint40 publicLaunchDate;
    // The root hash of the merkle proof used to validate the presale list.
    bytes32 rootHash;
    // Keep track of the number of passes claimed from the access list to prevent double dipping.
    mapping(address => uint256) claimedByAddress;
    string baseUrl;
    bool v2UpgradeComplete;
    // Keep track of the number of passes claimed from the presale list to prevent double dipping.
    mapping(address => Presale) presaleByAddress;
  }

  function appStorage() internal pure returns (AppStorage storage ds) {
    bytes32 position = STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function abs(int256 x) internal pure returns (uint256) {
    return uint256(x >= 0 ? x : -x);
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256) {
    return uint256(x < y ? x : y);
  }

  function clamp(int16 x) internal pure returns (uint16) {
    return uint16(x > 0 ? x : int16(0));
  }

  function getTokenUri(uint256 tokenId) internal view returns (string memory) {
    return string(abi.encodePacked(appStorage().baseUrl, tokenId.toString(), ".json"));
  }

  function totalSupply(AppStorage storage s) internal view returns (uint256) {
    return s.counter.current();
  }

  function nextTokenId(AppStorage storage s) internal returns (uint256) {
    s.counter.increment();
    return totalSupply(s);
  }

  function ensureEnoughSupply(AppStorage storage s, uint40 count) internal view {
    require(totalSupply(s) + count <= TOTAL, "Not enough supply to mint");
  }

  function ensureSaleLive(AppStorage storage s) internal view {
    require(block.timestamp >= s.publicLaunchDate, "Public sale has not started yet");
  }
}
