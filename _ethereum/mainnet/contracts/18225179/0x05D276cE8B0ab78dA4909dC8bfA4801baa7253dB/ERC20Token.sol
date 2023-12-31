// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ContextUpgradeable.sol";


contract UpgradableERC20 is  Initializable,
    UUPSUpgradeable,
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable {
   

    function initialize() initializer public {
        __ERC20_init_unchained('Gyaan Governance Token', 'GYDAO');
        __Pausable_init_unchained();
        __Ownable_init_unchained();

        _mint(msg.sender, 500000000 * 10**18);
    }

     /**
        @dev Pause the contract (stopped state) by owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
        @dev Unpause the contract (normal state) by owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

     /**
     * @dev For authorizing the uups upgrade
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}


