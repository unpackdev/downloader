// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721PresetMinterPauserAutoId} from'@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol';

contract BAYCDPCards is ERC721PresetMinterPauserAutoId(
  'BAYC Diamond Pepe Cards', 
  'BAYC-DP', 
  'ipfs://QmcnHu9JhDgthi9V1DmJfdgejfzoLzQgL2vjLfQMZMA1ok/'
) {

  function mintMultiple(address[] memory addresses) public {
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");
    for (uint i = 0; i < addresses.length; i++) {
      mint(addresses[i]);
    }
  }

}