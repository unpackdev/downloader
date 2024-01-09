// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Counters.sol";
import "./OpenSeaSharedStorefrontIds.sol";
import "./OpenSeaSharedStorefrontInterface.sol";

library EtherGrassOwners {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  //address public constant OS_ADDRESS = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656; // Rinkeby
  address public constant OS_ADDRESS = 0x495f947276749Ce646f68AC8c248420045cb7b5e; // Mainnet

  function isEtherGrassToken(uint _tokenId) public pure returns (bool) {
    uint256[50] memory allEtherGrassIds = OpenSeaSharedStorefrontIds.vipIds();
    bool isInEtherGrassIds = false;

    for (uint256 i = 0; i < allEtherGrassIds.length; i++) {
      if (_tokenId == allEtherGrassIds[i]) {
        isInEtherGrassIds = true;
        break;
      }
    }

    return isInEtherGrassIds;
  }


  function etherGrassIdsOwned(address _address) public view returns (uint256[] memory) {

    OpenSeaSharedStorefrontInterface openSeaSharedStorefront = OpenSeaSharedStorefrontInterface(OS_ADDRESS);

    address[] memory senderAddressArray = new address[](50);
    uint256[] memory allEtherGrassIdsArray = new uint256[](50);
    uint256[50] memory allEtherGrassIds = OpenSeaSharedStorefrontIds.vipIds();

    for (uint256 i = 0; i < allEtherGrassIds.length; i++) {
      senderAddressArray[i] = _address;
      allEtherGrassIdsArray[i] = allEtherGrassIds[i];
    }

    uint256[] memory balanceOfResult = openSeaSharedStorefront.balanceOfBatch(senderAddressArray, allEtherGrassIdsArray);
    uint256[] memory ownedEtherGrassIds = new uint256[](balanceOfResult.length);
    uint ownedIdCounter = 0;

    for (uint256 i = 0; i < balanceOfResult.length; i++) {
      if (balanceOfResult[i] == 1) {
        ownedEtherGrassIds[ownedIdCounter] = allEtherGrassIds[i];
        ownedIdCounter += 1;
      }
    }

    uint256[] memory ownedEtherGrassIdsTrimmed = new uint256[](ownedIdCounter);

    for (uint256 i = 0; i < ownedIdCounter; i++) {
      ownedEtherGrassIdsTrimmed[i] = ownedEtherGrassIds[i];
    }

    return ownedEtherGrassIdsTrimmed;
  }


  function etherGrassIdsClaimable(address _address, uint256 _mintsPerId, mapping (uint256 => uint256) storage _idsUsed) public view returns (uint256[] memory) {

    uint256[] memory ownedEtherGrassIds = etherGrassIdsOwned(_address);
    uint256[] memory claimableIds = new uint256[](ownedEtherGrassIds.length);
    uint claimableIdsCounter = 0;

    for (uint256 i = 0; i < ownedEtherGrassIds.length; i++) {
      if (_idsUsed[ownedEtherGrassIds[i]] < _mintsPerId) {
        claimableIds[claimableIdsCounter] = ownedEtherGrassIds[i];
        claimableIdsCounter += 1;
      }
    }

    uint256[] memory claimableIdsTrimmed = new uint256[](claimableIdsCounter);

    for (uint256 i = 0; i < claimableIdsCounter; i++) {
      claimableIdsTrimmed[i] = claimableIds[i];
    }

    return claimableIdsTrimmed;
  }


  function etherGrassMintsClaimable(address _address, uint256 _mintsPerId, mapping (uint256 => uint256) storage _idsUsed) public view returns (uint256) {
    uint256[] memory ownedEtherGrassIds = etherGrassIdsOwned(_address);
    uint256 claimableMintsCounter = 0;

    for (uint256 i = 0; i < ownedEtherGrassIds.length; i++) {
      claimableMintsCounter += (_mintsPerId - _idsUsed[ownedEtherGrassIds[i]]);
    }

    return claimableMintsCounter;
  }


  function ownsToken(address _address, uint _tokenId) public view returns (bool) {

    OpenSeaSharedStorefrontInterface openSeaSharedStorefront = OpenSeaSharedStorefrontInterface(OS_ADDRESS);
    return (openSeaSharedStorefront.balanceOf(_address, _tokenId) == 1);
  }

}