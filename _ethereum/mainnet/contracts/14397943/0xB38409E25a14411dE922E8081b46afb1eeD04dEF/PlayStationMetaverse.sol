// SPDX-License-Identifier: MIT

//    ____  _        _ __   ______ _____  _  _____ ___ ___  _   _   __  __ _____ _____  ___     _______ ____  ____  _____ 
//   |  _ \| |      / \\ \ / / ___|_   _|/ \|_   _|_ _/ _ \| \ | | |  \/  | ____|_   _|/ \ \   / / ____|  _ \/ ___|| ____|
//   | |_) | |     / _ \\ V /\___ \ | | / _ \ | |  | | | | |  \| | | |\/| |  _|   | | / _ \ \ / /|  _| | |_) \___ \|  _|  
//   |  __/| |___ / ___ \| |  ___) || |/ ___ \| |  | | |_| | |\  | | |  | | |___  | |/ ___ \ V / | |___|  _ < ___) | |___ 
//   |_|   |_____/_/   \_\_| |____/ |_/_/   \_\_| |___\___/|_| \_| |_|  |_|_____| |_/_/   \_\_/  |_____|_| \_\____/|_____|
//                                                                                                                        

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

/// @custom:security-contact PlayStationMetaverse@PlayStation.com
contract PlayStationMetaverse is ERC20, Pausable, Ownable {
    constructor() ERC20("PlayStation Metaverse", "PlayStation") {
        _mint(msg.sender, 100000000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
