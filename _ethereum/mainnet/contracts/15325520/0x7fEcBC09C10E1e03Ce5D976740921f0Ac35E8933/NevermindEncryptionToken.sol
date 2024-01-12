
// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./Pausable.sol";

/// @custom:security-contact techops@autonymsystems.com
contract NevermindEncryptionToken is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable {
    function decimals() public view override returns (uint8) {
		return 0;
	}

    constructor() ERC20("Nevermind Encryption Token", "NVM") {
        _mint(msg.sender, 50000000 * 10 ** decimals());
    }


    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
