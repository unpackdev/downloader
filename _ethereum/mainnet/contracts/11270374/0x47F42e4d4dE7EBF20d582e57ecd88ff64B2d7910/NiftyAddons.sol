pragma solidity ^0.6.0;

import "./ERC1155PresetMinterPauser.sol";

contract NiftyAddons is ERC1155PresetMinterPauser {
    constructor(string memory uri) public ERC1155PresetMinterPauser(uri) {}
}
