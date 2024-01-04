//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./ERC20PresetMinterPauser.sol";


contract LodeXToken is ERC20PresetMinterPauser {

  constructor(string memory name, string memory symbol)
    ERC20PresetMinterPauser(name, symbol) { }

}
