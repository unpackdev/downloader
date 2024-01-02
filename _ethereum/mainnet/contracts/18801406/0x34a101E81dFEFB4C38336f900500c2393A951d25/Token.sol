// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract DEDOGE is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    mapping(address => bool) internal usersOnHold;

    function initialize(address initialOwner) initializer public {
        __ERC20_init("DEDOGE", "DDG");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init(initialOwner);

        _mint(msg.sender, 4200000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
    internal
    override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {

        require(usersOnHold[from] == false, "funds on hold");
        //0.42% fee for all transactions
                uint256 fee = (value * 42)/10000;
                uint256 resultAmount = value - fee;
        super._update(from, to, resultAmount);
        super._update(from, address(0), fee);
    }

    function removeFromHoldList(address user) public onlyOwner {
        delete usersOnHold[user];
    }

    function putOnHold(address user) public onlyOwner {
        usersOnHold[user] = true;
    }
}



