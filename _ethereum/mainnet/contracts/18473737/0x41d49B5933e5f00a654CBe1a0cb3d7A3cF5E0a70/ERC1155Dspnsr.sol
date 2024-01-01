// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IERC20.sol";
import "./ERC1155.sol";
import "./ERC1155Holder.sol";
import "./ERC1155Receiver.sol";
import "./AccessControl.sol";
import "./Shareholders.sol";
import "./LockURI.sol";

/**
 * @title ERC1155Dspnsr
 * ERC1155Dspnsr - DSPNSR, powered by Satoshi's Closet
 * Mint your NFTs today at https://www.dspnsr.st/sell
 */
contract ERC1155Dspnsr is ERC1155, ERC1155Holder, Shareholders, LockURI, AccessControl {

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    // Set prices for items that can be minted
    uint256[] private _itemPrices;
    // Set payable token addresses for items that can be minted
    address[] private _itemTokenAddresses;
    // Set supplies for items that can be minted
    uint256[] private _itemSupplies;
    // Admin Role for Satoshi's Closet
    bytes32 public constant DSPNSR_ADMIN_ROLE = keccak256("DSPNSR_ADMIN_ROLE");


    /**
     * @dev Constructor
     * @param _name Contract name
     * @param _symbol Contract symbol
     * @param _uri Sets initial URI for metadata. Same for all tokens. Relies on id substitution by the client - https://token-cdn-domain/{id}.json
     * @param _shares The number of shares each shareholder has
     * @param _shareholder_addresses Payment address for each shareholder
     * @param itemPrices_ Initial item prices. This can be empty
     * @param itemTokenAddresses_ Initial item payable token addresses. Default is null, which maps to native token for the chain. If using something other than default, token address needs to be provided. This can by empty
     * @param itemSupplies_ Initial item supplies. This can be empty
     * @param admin Admin address that will be used by Satoshi's Closet to facilitate minting via WLT mobile app using Apple / Google Pay
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256[] memory _shares,
        address payable[] memory _shareholder_addresses,
        uint256[] memory itemPrices_,
        address[] memory itemTokenAddresses_,
        uint256[] memory itemSupplies_,
        address admin
    ) ERC1155(_uri) Shareholders(_shares, _shareholder_addresses){
        name = _name;
        symbol = _symbol;
        require(itemPrices_.length == itemSupplies_.length, "itemPrices_ and itemSupplies_ must have the same length");
        _itemPrices = itemPrices_;
        _itemTokenAddresses = itemTokenAddresses_;
        _itemSupplies = itemSupplies_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DSPNSR_ADMIN_ROLE, msg.sender);
        _grantRole(DSPNSR_ADMIN_ROLE, admin);
    }

    /**
     * @dev See https://forum.openzeppelin.com/t/derived-contract-must-override-function-supportsinterface/6315
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the max total supply of all tokens
     */
    function totalSupply() public view returns (uint256) {
        uint256 supply = 0;
        for(uint8 i=0; i < _itemSupplies.length; i++){
            supply += _itemSupplies[i];
        }
        return supply;
    }

    /**
     * @dev Returns the item prices array
     */
    function itemPrices() public view returns (uint256[] memory) {
        return _itemPrices;
    }

    /**
     * @dev Returns the item supplies array
     */
    function itemSupplies() public view returns (uint256[] memory) {
        return _itemSupplies;
    }

    /**
     * @dev For owner to set the base metadata URI while isUriLocked is false
     * @param _uri string - new value for metadata URI
     */
    function setURI(string memory _uri) public onlyOwner {
        require(isUriLocked == false, "URI is locked. Cannot set the base URI");
        _setURI(_uri);
    }

    /**
     * @dev Mint items using ERC-20 token
     * @param _to The address to mint to
     * @param tokenId The token ID to mint
     * @param amount The number of items to mint
     */
    function erc20Mint(address _to, uint256 tokenId, uint256 amount) public {
        require(tokenId > 0 && tokenId <= _itemPrices.length, "Token not available for minting");
        require(amount > 0, "Amount cannot be 0");
        require(amount <= _itemSupplies[tokenId - 1], "Not enough supply of this token"); // Starting from token ID 1
        address tokenAddress = _itemTokenAddresses[tokenId - 1];
        require(tokenAddress != address(0), "Token minting via native currency. Use mint function");
        IERC20 token = IERC20(tokenAddress);
        uint256 totalTransferAmount = _itemPrices[tokenId - 1] * amount;
        require(token.allowance(msg.sender, address(this)) >= totalTransferAmount, "Allowance not sufficient");
        require(token.transferFrom(msg.sender, address(this), totalTransferAmount), "Transfer failed");
        _mint(_to, tokenId, amount, "");
        _itemSupplies[tokenId - 1] -= amount;
    }

    /**
     * @dev Mint items
     * @param _to The address to mint to.
     * @param tokenId The token ID to mint.
     * @param amount The number of items to mint.
     */
    function mint(address _to, uint256 tokenId, uint256 amount) public payable {
        require(tokenId > 0 && tokenId <= _itemPrices.length, "Token not available for minting");
        require(amount > 0, "Amount cannot be 0");
        require(msg.value == _itemPrices[tokenId - 1] * amount, "Wrong minting fee"); // Starting from token ID 1
        require(_itemTokenAddresses[tokenId - 1] == address(0), "Token minting via non-native currency. Use erc20mint instead."); // make sure minting is in native currency. use erc20_mint for non-native currency
        require(amount <= _itemSupplies[tokenId - 1], "Not enough supply of this token"); // Starting from token ID 1
        _mint(_to, tokenId, amount, "");
        _itemSupplies[tokenId - 1] -= amount;
    }

    
    /**
    * @dev Mint items by Owner / Admin
    * @param _to The address to mint to.
    * @param tokenId The token ID to mint.
    * @param amount The number of items to mint.
    */
    function ownerMint(address _to, uint256 tokenId, uint256 amount) public onlyRole(DSPNSR_ADMIN_ROLE) {
        require(tokenId > 0 && tokenId <= _itemPrices.length, "Token not available for minting");
        require(amount <= _itemSupplies[tokenId - 1], "Not enough supply of this token"); // Starting from token ID 1
        _mint(_to, tokenId, amount, "");
        _itemSupplies[tokenId - 1] -= amount;
    }

}
