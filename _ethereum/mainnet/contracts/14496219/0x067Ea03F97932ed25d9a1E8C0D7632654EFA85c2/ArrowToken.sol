// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/**
    @title Arrow Token Implementation
*/
contract ArrowToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // implement the UUPS interface
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /** 
        @notice Mint an `_initialSupply` amount of tokens upon contract creation
        @dev If we were to upgrade the initializer by introducing new variables, we need to create a normal function like `initializeV2` (https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786/53), and make sure to include all existing variables from the current version of the contract to avoid storage collision
    */
    function initialize(uint256 _initialSupply, string memory _name, string memory _symbol) public initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, _initialSupply);
    }
    /**     
        @notice Mint and issue new tokens to a specified address
        @param _to the address to issue new tokens to
        @param _amount the amount of tokens to be mint and transfered to `_to` 
   */
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
