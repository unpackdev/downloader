// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";                                       

contract LoreumToken is ERC20, ERC20Permit, Ownable {
    
    /**************************************************
        Token State Variables
     **************************************************/

    /**
    * @notice The maximum number of tokens that can ever be minted.
    * @dev This value is immutable, meaning that it can only be set once, during the contract deployment.
    */
    uint256 public immutable maxSupply;
    
    /**************************************************
        Constructor
     **************************************************/

    /**
    * @notice Constructor for the Loreum token.
    * @dev Mints an initial amount of tokens to the provided receiver's address. 
    * Also sets the max supply of the token.
    * This contract inherits from the OpenZeppelin's Ownable, ERC20, and ERC20Permit contracts.
    * @param premintReceiver The address that will receive the initial minted tokens.
    * @param premintAmount The amount of tokens to mint initially and give to the premintReceiver.
    * @param _maxSupply The maximum supply that this token can ever reach.
    */
    constructor(
        address premintReceiver, 
        uint256 premintAmount, 
        uint256 _maxSupply
    ) Ownable() ERC20("Loreum", "LORE") ERC20Permit("Loreum") {
        require(_maxSupply >= premintAmount, "LoreumToken::constructor() _maxSupply < premintAmount");
        _mint(premintReceiver, premintAmount);
        maxSupply = _maxSupply;
    }

    /**************************************************
        Functions
     **************************************************/

    /**
    * @notice Burns the specified amount of tokens from the caller's account.
    * @dev This function is virtual, meaning that it can be overridden in derived contracts.
    * @param amount The amount of tokens to be burned from the caller's account.
    */
    function burn(uint256 amount) external virtual { _burn(_msgSender(), amount); }

    /**
    * @notice Mints the given amount of tokens to the specified account.
    * @dev Can only be called by the contract owner.
    * @param account The address of the account to mint tokens to.
    * @param amount The amount of tokens to mint.
    */
    function mint(address account, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "LoreumToken::mint() totalSupply() + amount > maxSupply");
        _mint(account, amount);
    }

}
