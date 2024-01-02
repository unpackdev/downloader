// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";
import "./ERC20Upgradeable.sol";
import "./UUPSUpgradeable.sol";

contract SocratesToken is OwnableUpgradeable, ERC20Upgradeable, UUPSUpgradeable {
    uint256 constant MAX_SUPPLY = 100_000_000 * (10 ** 18);
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin) public initializer {
        __ERC20_init("SOC", "SOC");
        __Ownable_init(defaultAdmin);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "ERC20: minting more than total supply");
        _mint(to, amount);
    }

    function decimals() public view virtual override(ERC20Upgradeable) returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override(ERC20Upgradeable) returns (uint256) {
        return super.totalSupply();
    } 
}
