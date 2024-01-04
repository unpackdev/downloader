// contracts/treasure.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155PresetMinterPauser.sol";
import "./ERC1155Holder.sol";
import "./Ownable.sol";

contract Treasure is ERC1155PresetMinterPauser, ERC1155Holder, Ownable {
  string public name = "ScienceVR Treasure";
  string public symbol = "SVRT";

  constructor() public ERC1155PresetMinterPauser("https://vault.sciencevr.com/item/{id}.json") {

  }

  function contractURI() public view returns (string memory) {
    return "https://vault.sciencevr.com/treasure";
  }
}
