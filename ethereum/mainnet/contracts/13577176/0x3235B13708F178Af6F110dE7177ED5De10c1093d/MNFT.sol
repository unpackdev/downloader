pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";

contract MNFT is ERC20PresetMinterPauser {
    constructor() ERC20PresetMinterPauser("MNFT", "MNFT") {}
}
