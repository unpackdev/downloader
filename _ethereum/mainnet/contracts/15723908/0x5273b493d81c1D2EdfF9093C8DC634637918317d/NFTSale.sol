// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./EnumerableSet.sol";

import "./INFTMintable.sol";

contract NFTSale is
    Initializable,
    AccessControlUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant MAX_FREE_MINT_PER_ACCOUNT = 1;

    function initialize(address _admin, INFTMintable _nftContract, uint256 _initialPrice) public initializer {
        require(address(_nftContract) != address(0), "zero address");
        require(_initialPrice > 0, "zero number");

        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        NFT_CONTRACT = _nftContract;
        _salePrice = _initialPrice;
    }

    INFTMintable public NFT_CONTRACT;
    uint256 private _salePrice;

    EnumerableSet.AddressSet private _whitelists;
    mapping(address => uint256) private _wlBought;

    event NFTMinted(address indexed minter, uint256 quantity);
    event FreeNFTMinted(address indexed minter, uint256 quantity);

    modifier restricted() {
        _restricted();
        _;
    }

    function _restricted() internal view {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not admin");
    }

    /**
     * @notice Set NFT Contract
     *
     * @dev External function to set nft contract. Only admin can call this function.
     * @param _nftContract NFT address.
     */

    function setNftContract(INFTMintable _nftContract) external restricted {
        require(address(_nftContract) != address(0), "zero address");

        NFT_CONTRACT = _nftContract;
    }

    /**
     * @notice Set price
     *
     * @dev Update price for an NFT. Only admin can call this function.
     * @param _newPrice New price.
     */

    function setSalePrice(uint256 _newPrice) external restricted {
        require(_newPrice > 0, "zero number");

        _salePrice = _newPrice;
    }

    /**
     * @notice Get Sale Price
     *
     * @dev External funciton to get sale price.
     */

    function salePrice() external view returns(uint256) {
        return _salePrice;
    }

    /**
     * @notice Add Whitelists
     *
     * @dev Owner add address to whitelist. Only admin can call this function.
     * @param _addresses Array of address.
     */

    function addWhitelists(address[] calldata _addresses) external restricted {
        require(_addresses.length > 0, "invalid length");

        for (uint256 i = 0; i < _addresses.length; i++) {
            _addWhitelist(_addresses[i]);
        }
    }

    /**
     * @notice Add Whitelist
     *
     * @dev Internal function to add whitelist address
     * @param _address Whitelist address.
     */

    function _addWhitelist(address _address) internal {
        require(_address != address(0), "zero address");
        require(!_whitelists.contains(_address), "whitelisted");

        _whitelists.add(_address);
    }

    /**
     * @notice Remove Whitelists
     *
     * @dev Owner remove address from whitelist. Only admin can call this function.
     * @param _addresses Array of address.
     */

    function removeWhitelists(address[] calldata _addresses) external restricted {
        require(_addresses.length > 0, "invalid length");

        for (uint256 i = 0; i < _addresses.length; i++) {
            _removeWhitelist(_addresses[i]);
        }
    }

    /**
     * @notice Remove Whitelist
     *
     * @dev Internal function to remove whitelist address
     * @param _address Whitelist address.
     */

    function _removeWhitelist(address _address) internal {
        require(_address != address(0), "zero address");
        require(_whitelists.contains(_address), "not whitelisted");

        _whitelists.remove(_address);
    }

    /**
     * @notice Is Whitelist
     *
     * @dev External function to check address is in whitelist
     * @param _address Address to check
     */

    function isWhitelist(address _address) external view returns(bool) {
        return _whitelists.contains(_address);
    }

    /**
     * @notice Can Mint
     *
     * @dev External function to check minter can use free mint
     * @param _minter Minter address
     */

    function canMintFree(address _minter) external view returns(bool) {
        return _canMintFree(_minter);
    }

    /**
     * @dev Internal function to check minter can use free mint.
     * @param _minter Minter address
     */

    function _canMintFree(address _minter) internal view returns(bool) {
        return _whitelists.contains(_minter) && _wlBought[_minter] < MAX_FREE_MINT_PER_ACCOUNT;
    }

    /**
     * @notice Mint Token
     *
     * @dev Mint new token.
     */

    function mint() external payable {
        require(msg.value >= _salePrice, "insufficient balance");

        NFT_CONTRACT.mint(_msgSender());

        // refund
        if (msg.value > _salePrice) {
            payable(_msgSender()).transfer(msg.value - _salePrice);
        }

        emit NFTMinted(_msgSender(), 1);
    }

    /**
     * @notice Free Mint
     *
     * @dev External function to free mint nft
     */

    function freeMint() external {
        require(_canMintFree(_msgSender()), "mint limited");

        NFT_CONTRACT.mint(_msgSender());

        _wlBought[_msgSender()] = _wlBought[_msgSender()] + 1;

        emit FreeNFTMinted(_msgSender(), 1);
    }

    /**
     * @notice Withdraw Funds
     *
     * @dev Withdraw collected funds. Only admin can call this function.
     */

    function withdraw() external restricted {
        payable(_msgSender()).transfer(address(this).balance);
    }
}