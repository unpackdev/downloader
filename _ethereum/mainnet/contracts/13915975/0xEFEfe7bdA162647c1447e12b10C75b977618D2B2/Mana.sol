// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IRift.sol";

/// @title Mana (for Adventurers)
/// @notice This contract mints Mana for Crystals
/// @custom:unaudited This contract has not been audited. Use at your own risk.
contract Mana is Context, Ownable, ERC20 {
    event MintMana(address indexed recipient, uint256 amount);

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) mintControllers;
    mapping(address => bool) burnControllers;
    IERC721Enumerable public crystalsContract;
    IRift public iRift;

    constructor() Ownable() ERC20("Adventure Mana", "AMNA") {
        _mint(_msgSender(), 1000000);
    }

    function ownerSetRift(address rift) public onlyOwner {
        iRift = IRift(rift);
    }

    /// @notice function for Crystals contract to mint on behalf of to
    /// @param recipient address to send mana to
    /// @param amount number of mana to mint
    function ccMintTo(address recipient, uint256 amount) external {
        // Check that the msgSender is from Crystals
        require(mintControllers[msg.sender], "Only controllers can mint");

        _mint(recipient, amount);
        emit MintMana(recipient, amount);
    }

    function burn(address from, uint256 amount) external {
        require(burnControllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
    * enables an address to mint
    * @param controller the address to enable
    */
    function addMintController(address controller) external onlyOwner {
        mintControllers[controller] = true;
    }

    /**
    * disables an address from minting
    * @param controller the address to disbale
    */
    function removeMintController(address controller) external onlyOwner {
        mintControllers[controller] = false;
    }

    /**
    * enables an address to burn
    * @param controller the address to enable
    */
    function addBurnController(address controller) external onlyOwner {
        burnControllers[controller] = true;
    }

    /**
    * disables an address from burning
    * @param controller the address to disbale
    */
    function removeBurnController(address controller) external onlyOwner {
        burnControllers[controller] = false;
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }
}
