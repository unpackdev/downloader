// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";

// Main contract used for the token
contract Token is Initializable, ERC20Upgradeable {
//
    // Number of decimals in token
    uint8 public constant _decimals = 18;
    // Total supply of tokens - total_coins * 10^decimals
    uint256 public _total_supply;
    // Contract owner address
    address public _owner;
    // Contract version identifier
    string public _version;

    // Emitted when version is updated
    event VersionChanged(string new_version);

    // Restrict function to specific callers
    modifier ownerOnly {
        require(msg.sender == _owner, "Action not permitted");
        _;
    }

    // Constructor for upgradeable contract
    function initialize(
        string memory name,
        string memory symbol,
        string memory version,
        uint256 total_coins
    ) public virtual initializer {
        __ERC20_init(name, symbol);
        _total_supply = total_coins * (10**_decimals);
        _owner = 0x4cC8310479aCd5C8b6E6693A49B028Ec97899F38;
        _mint(_owner, _total_supply);
        _version = version;
    }

    // Update the contract version text
    function updateVersionText(string memory version) public ownerOnly {
        _version = version;
        emit VersionChanged(_version);
    }

    // Number of coin decimals
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
