pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";

contract MNTC is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("MNTC", "MNTC") {}
}
