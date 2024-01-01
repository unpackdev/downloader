// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";

contract ACMToken is
    Initializable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    fallback() external payable {}

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _supplyOwner
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __ReentrancyGuard_init();
        __Ownable_init();
        _mint(_supplyOwner, _initialSupply);
    }

}