pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract MareBits is OwnableUpgradeable, ERC20Upgradeable {
        function initialize(string memory name, string memory symbol, uint256 initialSupply, address owner) public virtual initializer {
                __MareBitsFixedSupply_init(name, symbol, initialSupply, owner);
        }

        function __MareBitsFixedSupply_init(string memory name, string memory symbol, uint256 initialSupply, address owner) internal initializer {
                __Context_init_unchained();
                __Ownable_init_unchained();
                __ERC20_init_unchained(name, symbol);
                __MareBits_init_unchained(name, symbol, initialSupply, owner);
        }

        function __MareBits_init_unchained(string memory name, string memory symbol, uint256 initialSupply, address owner) internal initializer {
                _mint(owner, initialSupply);
        }
        uint256[50] private __gap;
}
