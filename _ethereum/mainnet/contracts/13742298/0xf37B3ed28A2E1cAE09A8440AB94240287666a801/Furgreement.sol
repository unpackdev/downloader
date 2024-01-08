// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Furballs.sol";
import "./Fur.sol";
import "./FurProxy.sol";
import "./Zones.sol";
import "./SnackShop.sol";
import "./MetaData.sol";
import "./L2Lib.sol";
import "./Fuel.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
// import "./console.sol";

/// @title Furgreement
/// @author LFG Gaming LLC
/// @notice L2 proxy authority; has permissions to write to main contract(s)
contract Furgreement is EIP712, FurProxy {
  // Tracker of wallet balances
  Fuel public fuel;

  // Simple, fast check for a single allowed proxy...
  address private _job;

  constructor(
    address furballsAddress, address fuelAddress
  ) EIP712("Furgreement", "1") FurProxy(furballsAddress) {
    fuel = Fuel(fuelAddress);
    _job = msg.sender;
  }

  /// @notice Player signs an EIP-712 authorizing the ticket (fuel) usage
  /// @dev furballMoves defines desinations (zone-moves) for playMany
  function runTimekeeper(
    uint64[] calldata furballMoves,
    L2Lib.TimekeeperRequest[] calldata tkRequests,
    bytes[] calldata signatures
  ) external allowedProxy {
    // While TK runs, numMovedFurballs are collected to move zones at the end
    uint8 numZones = uint8(furballMoves.length);
    uint256[][] memory tokenIds = new uint256[][](numZones);
    uint32[] memory zoneNums = new uint32[](numZones);
    uint32[] memory zoneCounts = new uint32[](numZones);
    for (uint i=0; i<numZones; i++) {
      tokenIds[i] = new uint256[](furballMoves[i] & 0xFF);
      zoneNums[i] = uint32(furballMoves[i] >> 8);
      zoneCounts[i] = 0;
    }

    // Validate & run TK on each request
    for (uint i=0; i<tkRequests.length; i++) {
      L2Lib.TimekeeperRequest memory tkRequest = tkRequests[i];
      uint errorCode = _runTimekeeper(tkRequest, signatures[i]);
      require(errorCode == 0, errorCode == 0 ? "" : string(abi.encodePacked(
        FurLib.bytesHex(abi.encode(tkRequest.sender)),
        ":",
        FurLib.uint2str(errorCode)
      )));

      // Each "round" in the request represents a Furball
      for (uint i=0; i<tkRequest.rounds.length; i++) {
        _resolveRound(tkRequest.rounds[i], tkRequest.sender);

        uint zi = tkRequest.rounds[i].zoneListNum;
        if (numZones == 0 || zi == 0) continue;

        zi = zi - 1;
        uint zc = zoneCounts[zi];
        tokenIds[zi][zc] = tkRequest.rounds[i].tokenId;
        zoneCounts[zi] = uint32(zc + 1);
      }
    }

    // Finally, move furballs.
    for (uint i=0; i<numZones; i++) {
      uint32 zoneNum = zoneNums[i];
      if (zoneNum == 0 || zoneNum == 0x10000) {
        furballs.playMany(tokenIds[i], zoneNum, address(this));
      } else {
        furballs.engine().zones().overrideZone(tokenIds[i], zoneNum);
      }
    }
  }

  /// @notice Public validation function can check that the signature was valid ahead of time
  function validateTimekeeper(
    L2Lib.TimekeeperRequest memory tkRequest,
    bytes memory signature
  ) public view returns (uint) {
    return _validateTimekeeper(tkRequest, signature);
  }

  /// @notice Single Timekeeper run for one player; validates EIP-712 request
  function _runTimekeeper(
    L2Lib.TimekeeperRequest memory tkRequest,
    bytes memory signature
  ) internal returns (uint) {
    // Check the EIP-712 signature.
    uint errorCode = _validateTimekeeper(tkRequest, signature);
    if (errorCode != 0) return errorCode;

    // Burn tickets, etc.
    if (tkRequest.tickets > 0) fuel.burn(tkRequest.sender, tkRequest.tickets);

    //  Earn FUR (must be at least the amount approved by player)
    require(tkRequest.furReal >= tkRequest.furGained, "FUR");
    if (tkRequest.furReal > 0) {
      furballs.fur().earn(tkRequest.sender, tkRequest.furReal);
    }

    // Spend FUR (everything approved by player)
    if (tkRequest.furSpent > 0) {
      // Spend the FUR required for these actions
      furballs.fur().spend(tkRequest.sender, tkRequest.furSpent);
    }

    // Mint new furballs from an edition
    if (tkRequest.mintCount > 0) {
      // Edition is one-indexed, to allow for null
      address[] memory to = new address[](tkRequest.mintCount);
      for (uint i=0; i<tkRequest.mintCount; i++) {
        to[i] = tkRequest.sender;
      }

      // "Gift" the mint (FUR purchase should have been done above)
      furballs.mint(to, tkRequest.mintEdition, address(this));
    }

    return 0; // no error
  }

  /// @notice Validate a timekeeper request
  function _validateTimekeeper(
    L2Lib.TimekeeperRequest memory tkRequest,
    bytes memory signature
  ) internal view returns (uint) {
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
      keccak256("TimekeeperRequest(address sender,uint32 fuel,uint32 fur_gained,uint32 fur_spent,uint8 mint_edition,uint8 mint_count,uint64 deadline)"),
      tkRequest.sender,
      tkRequest.tickets,
      tkRequest.furGained,
      tkRequest.furSpent,
      tkRequest.mintEdition,
      tkRequest.mintCount,
      tkRequest.deadline
    )));

    address signer = ECDSA.recover(digest, signature);
    if (signer != tkRequest.sender) return 1;
    if (signer == address(0)) return 2;
    if (tkRequest.deadline != 0 && block.timestamp >= tkRequest.deadline) return 3;

    return 0;
  }

  /// @notice Give rewards/outcomes directly
  function _resolveRound(L2Lib.RoundResolution memory round, address sender) internal {
    if (round.expGained > 0) {
      // EXP gain (in explore mode)
      furballs.engine().zones().addExp(round.tokenId, round.expGained);
    }

    if (round.items.length != 0) {
      // First item is an optional drop
      if (round.items[0] != 0)
        furballs.drop(round.tokenId, round.items[0], 1);

      // Other items are pickups
      for (uint j=1; j<round.items.length; j++) {
        furballs.pickup(round.tokenId, round.items[j]);
      }
    }

    // Directly assign snacks...
    if (round.snackStacks.length > 0) {
      furballs.engine().snacks().giveSnacks(round.tokenId, round.snackStacks);
    }
  }

  /// @notice Proxy can be set to an arbitrary address to represent the allowed offline job
  function setJobAddress(address addr) external gameAdmin {
    _job = addr;
  }

  /// @notice Simple proxy allowed check
  modifier allowedProxy() {
    require(msg.sender == _job || furballs.isAdmin(msg.sender), "FPRXY");
    _;
  }
}
