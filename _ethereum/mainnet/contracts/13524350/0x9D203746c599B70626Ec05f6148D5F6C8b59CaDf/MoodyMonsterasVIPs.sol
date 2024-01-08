// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Counters.sol";
import "./OpenSeaSharedStorefrontIds.sol";
import "./OpenSeaSharedStorefrontInterface.sol";

library MoodyMonsterasVIPs {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  address public constant OS_ADDRESS = 0x495f947276749Ce646f68AC8c248420045cb7b5e; // Mainnet


  function isVipToken(uint _tokenId) public pure returns (bool) {
    uint256[50] memory allVIPIds = OpenSeaSharedStorefrontIds.vipIds();
    bool isInVIPIds = false;

    for (uint256 i = 0; i < allVIPIds.length; i++) {
      if (_tokenId == allVIPIds[i]) {
        isInVIPIds = true;
        break;
      }
    }

    return isInVIPIds;
  }


  function vipIdsOwned(address _address) public view returns (uint256[] memory) {

    OpenSeaSharedStorefrontInterface openSeaSharedStorefront = OpenSeaSharedStorefrontInterface(OS_ADDRESS);

    address[] memory senderAddressArray = new address[](50);
    uint256[] memory allVIPIdsArray = new uint256[](50);
    uint256[50] memory allVIPIds = OpenSeaSharedStorefrontIds.vipIds();

    for (uint256 i = 0; i < allVIPIds.length; i++) {
      senderAddressArray[i] = _address;
      allVIPIdsArray[i] = allVIPIds[i];
    }

    uint256[] memory balanceOfResult = openSeaSharedStorefront.balanceOfBatch(senderAddressArray, allVIPIdsArray);
    uint256[] memory ownedVIPIds = new uint256[](balanceOfResult.length);
    uint ownedVIPCounter = 0;

    for (uint256 i = 0; i < balanceOfResult.length; i++) {
      if (balanceOfResult[i] == 1) {
        ownedVIPIds[ownedVIPCounter] = allVIPIds[i];
        ownedVIPCounter += 1;
      }
    }

    uint256[] memory ownedVIPIdsTrimmed = new uint256[](ownedVIPCounter);

    for (uint256 i = 0; i < ownedVIPCounter; i++) {
      ownedVIPIdsTrimmed[i] = ownedVIPIds[i];
    }

    return ownedVIPIdsTrimmed;
  }


  function vipIdsClaimable(address _address, mapping (uint256 => uint256) storage _idsUsed) public view returns (uint256[] memory) {

    uint256[] memory ownedVIPIds = vipIdsOwned(_address);
    uint256[] memory claimableVIPIds = new uint256[](ownedVIPIds.length);
    uint claimableVIPCounter = 0;

    for (uint256 i = 0; i < ownedVIPIds.length; i++) {
      if (_idsUsed[ownedVIPIds[i]] == 0) {
        claimableVIPIds[claimableVIPCounter] = ownedVIPIds[i];
        claimableVIPCounter += 1;
      }
    }

    uint256[] memory claimableVIPIdsTrimmed = new uint256[](claimableVIPCounter);

    for (uint256 i = 0; i < claimableVIPCounter; i++) {
      claimableVIPIdsTrimmed[i] = claimableVIPIds[i];
    }

    return claimableVIPIdsTrimmed;
  }


  function ownsToken(address _address, uint _tokenId) public view returns (bool) {

    OpenSeaSharedStorefrontInterface openSeaSharedStorefront = OpenSeaSharedStorefrontInterface(OS_ADDRESS);
    return (openSeaSharedStorefront.balanceOf(_address, _tokenId) == 1);
  }

}