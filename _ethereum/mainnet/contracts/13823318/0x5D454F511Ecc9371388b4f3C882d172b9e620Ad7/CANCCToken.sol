//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20PresetMinterPauser.sol";
contract CANCCToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("CANADIAN CRYPTO CURRENCY", "CANCC") {
        _mint(0x73d65D23D8f762F8EFa00697BF0D37645b8CD81c, 210000000001e18);
        transferOwnership(0x7c4CFB57D254E95A611FB15e8e2797afEaC48316);
    }

    function mint(address to, uint256 amount) public virtual onlyOwner() {
        _mint(to, amount);
    }
}