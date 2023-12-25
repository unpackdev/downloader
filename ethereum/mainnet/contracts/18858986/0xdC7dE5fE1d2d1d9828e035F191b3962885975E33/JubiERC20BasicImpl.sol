//SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";
import "./SafeERC20.sol";


/**
 * @title JubiERC20BasicImpl
 * @notice This contract is used as a template for  ERC20 tokens in the jubi.io ecosystem.
 * @dev The intention is for a new version to be deployed from the Jubi factory, with the appropriate values.
 */
contract JubiERC20BasicImpl is
    ERC20,
    Ownable,
    ERC20Burnable,
    ERC20Permit
{
    using SafeERC20 for ERC20;

    string public constant version = "1.0.0";
    string public constant contractType = "JubiERC20BasicImpl";

    bool public transferPaused;

    /// @notice Accounts which are granted access to mint/burn tokens
    mapping(address => bool) public minters;

    event MinterSet(address indexed account, bool canMint);
    
    event TokenRecovered(address indexed tokenAddress, address indexed toAddress, uint256 tokenAmount);
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @notice The ERC20 token constructor with a new name and symbol.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_) 
        Ownable() 
        ERC20Permit(name_)
    {
        pause();
    }

    /**
     * @notice Pauses token transfers minting, and burning.
     * @dev Owner still has rights to transfer/burn tokens while paused.
     */
    function pause() public onlyOwner {
        transferPaused=true;
    }

    /**
     * @notice Unpauses token transfers minting, and burning.
     */
    function unpause() public onlyOwner {
        transferPaused=false;
    }

    /**
     * @notice Returns true if the token is paused, and false otherwise.
     * @dev This function is present for backwards compatibility.
     */
    function paused() public view returns (bool) {
        return transferPaused;
    }
    
    /**
     * @notice Add accounts which are allowed to mint new tokens.
     */
    function setMinter(address account, bool canMint) external onlyOwner {
        minters[account] = canMint;
        emit MinterSet(account, canMint);
    }

    /**
     * @notice Mints new tokens to the specified address if the token is not paused.
     * @dev This function can only be called by the Minters
     * @param to The address to send the new tokens to.
     * @param amount The amount of new tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from the specified account if the token is not paused.
     * @dev This function can only be called by the Minter
     * @param account The account to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function burnFrom(address account, uint256 amount) public override onlyMinter {
        _burn(account, amount);
    }

    /**
     * @notice Burns tokens from the sender's account if the token is not paused.
     * @dev This function can only be called by the Minter
     * @param amount The amount of tokens to burn.
     */
    function burn(uint256 amount) public override onlyMinter {
        _burn(msg.sender, amount);
    }

    /**
     * @notice If the token is paused, only the Owner can transfer tokens.
     * @dev Overrides the _beforeTokenTransfer function from the ERC20 and ERC20Snapshot contracts.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        // If paused, the owner can still transfer their tokens.
        require(!transferPaused || msg.sender == owner(), "Pausable: paused");

        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Recovers ERC20 tokens sent to the contract.
     * This function can only be called by the Owner.
     * @param tokenAddress The address of the ERC20 token to recover.
     * @param toAddress The address to send the recovered ERC20 tokens to.
     * @param tokenAmount The amount of ERC20 tokens to recover.
     */
    function recoverERC20(
        address tokenAddress,
        address toAddress,
        uint256 tokenAmount
    ) public onlyOwner {
        ERC20(tokenAddress).safeTransfer(toAddress, tokenAmount);
        emit TokenRecovered(tokenAddress, toAddress, tokenAmount);
    }

    // The following functions are overrides required by Solidity.
    /**
     * @dev Overrides the _afterTokenTransfer function from the ERC20 and ERC20Votes contracts.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Overrides the _mint function from the ERC20 and ERC20Votes contracts.
     * @param to The address to send the new tokens to.
     * @param amount The amount of new tokens to mint.
     */
    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._mint(to, amount);
    }

    /**
     * @dev Overrides the _burn function from the ERC20 and ERC20Votes contracts.
     * @param account The account to burn tokens from.
     * @param amount The amount of tokens to burn.
     */
    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20) {
        super._burn(account, amount);
    }

    function _requireMinter() internal view {
        require(minters[msg.sender]|| msg.sender == owner(), "Only Minters");
    }

    modifier onlyMinter() {
        _requireMinter();
        _;
    }
}
