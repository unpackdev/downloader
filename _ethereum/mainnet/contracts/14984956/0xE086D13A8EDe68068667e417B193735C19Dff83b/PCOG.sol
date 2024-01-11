// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

//import "./InterfacePCOG.sol";

import "./ERC20SnapshotUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";


contract PCOG is ERC20SnapshotUpgradeable, PausableUpgradeable, OwnableUpgradeable {

    function initialize() initializer external {
        __ERC20_init("PRECOG Token", "PCOG");
        //_mint(_msgSender(), 1e27);
        _mint(_msgSender(), (98 * 10 ** 24) );
        __Ownable_init();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override (ERC20SnapshotUpgradeable) whenNotPaused {
        ERC20SnapshotUpgradeable._beforeTokenTransfer(from, to, amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}