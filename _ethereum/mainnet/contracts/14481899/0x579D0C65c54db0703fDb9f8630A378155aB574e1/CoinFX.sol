//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";

contract CoinFX is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("CoinFX", "FXR") {}
}
