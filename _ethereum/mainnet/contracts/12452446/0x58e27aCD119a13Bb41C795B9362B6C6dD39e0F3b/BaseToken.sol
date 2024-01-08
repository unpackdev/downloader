// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./IERC165.sol";
import "./IERC1363.sol";
import "./IERC1363Receiver.sol";
import "./IERC1363Spender.sol";
import "./ERC165Checker.sol";
import "./ERC165.sol";
import "./ERC1363.sol";
import "./Ownable.sol";
import "./TokenRecover.sol";
import "./EnumerableSet.sol";
import "./AccessControl.sol";

import "./Roles.sol";
import "./Pausable.sol";

/**
 * @title BaseToken
 * @dev Implementation of the BaseToken
 */
contract BaseToken is ERC20Capped, ERC20Burnable, ERC1363, Roles, TokenRecover, Pausable {

    // indicates if minting is finished
    bool private _mintingFinished = false;

    // indicates if transfer is enabled
    bool private _transferEnabled = false;

    /**
     * @dev Emitted during finish minting
     */
    event MintFinished();

    /**
     * @dev Emitted during transfer enabling
     */
    event TransferEnabled();

    /**
     * @dev Tokens can be minted only before minting finished.
     */
    modifier canMint() {
        require(!_mintingFinished, "BaseToken: minting is finished");
        _;
    }

    /**
     * @dev Tokens can be moved only after if transfer enabled or if you are an approved operator.
     */
    modifier canTransfer(address from) {
        require(
            _transferEnabled || hasRole(OPERATOR_ROLE, from),
            "BaseToken: transfer is not enabled or from does not have the OPERATOR role"
        );
        _;
    }

    /**
     * @param name Name of the token
     * @param symbol A symbol to be used as ticker
     * @param decimals Number of decimals. All the operations are done using the smallest and indivisible token unit
     * @param cap Maximum number of tokens mintable
     * @param initialSupply Initial token supply
     * @param transferEnabled If transfer is enabled on token creation
     * @param mintingFinished If minting is finished after token creation
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap,
        uint256 initialSupply,
        bool transferEnabled,
        bool mintingFinished
    )
        public
        ERC20Capped(cap)
        ERC1363(name, symbol)
    {
        (
            mintingFinished == false || cap == initialSupply,
            "BaseToken: if finish minting, cap must be equal to initialSupply"
        );

        _setupDecimals(decimals);

        if (initialSupply > 0) {
            _mint(owner(), initialSupply);
        }

        if (mintingFinished) {
            finishMinting();
        }

        if (transferEnabled) {
            enableTransfer();
        }
    }

    /**
     * @return if minting is finished or not.
     */
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @return if transfer is enabled or not.
     */
    function transferEnabled() public view returns (bool) {
        return _transferEnabled;
    }

    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens
     * @param value The amount of tokens to mint
     */
    function mint(address to, uint256 value) public canMint onlyMinter whenNotPaused {
        _mint(to, value);
    }

    /**
     * @dev Function to burn tokens.
     * @param from The address of the tokens to be burned (if someone else's tokens is to be burned, other people's approve is required, but this is generally not allowed)
     * @param value The amount of tokens to burn
     */
    function burn(address from, uint256 value) public canMint onlyMinter whenNotPaused {
        _burn(from, value);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to
     * @param value The amount to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function transfer(address to, uint256 value) public virtual override(ERC20) canTransfer(_msgSender()) whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address which you want to send tokens from
     * @param to The address which you want to transfer to
     * @param value the amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(address from, address to, uint256 value) public virtual override(ERC20) canTransfer(from) whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Function to stop minting new tokens.
     */
    function finishMinting() public canMint onlyOwner {
        _mintingFinished = true;

        emit MintFinished();
    }

    /**
     * @dev Function to enable transfers.
     */
    function enableTransfer() public onlyOwner {
        _transferEnabled = true;

        emit TransferEnabled();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }
}