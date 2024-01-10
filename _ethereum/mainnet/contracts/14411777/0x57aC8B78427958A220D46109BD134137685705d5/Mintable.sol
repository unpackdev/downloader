// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Config.sol";

abstract contract Mintable is Initializable, ERC721Upgradeable, OwnableUpgradeable, Config {
    enum Sale {
        Closed,
        PreSale,
        Public
    }

    using ECDSAUpgradeable for bytes32;
    Sale public sale;
    mapping(address => uint256) public preSaleMintedTokens;
    address private _preSaleSigner;
    uint256 private _nextTokenId;
    bool private _hasMintedReserved;

    // solhint-disable-next-line func-name-mixedcase
    function __Mintable_init(Sale _sale, address preSaleSigner_) internal onlyInitializing {
        __Mintable_init_unchained(_sale, preSaleSigner_);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Mintable_init_unchained(Sale _sale, address preSaleSigner_)
        internal
        onlyInitializing
    {
        sale = _sale;
        _preSaleSigner = preSaleSigner_;
        _nextTokenId = 1 + RESERVED_TOKENS;
    }

    function setPreSaleSigner(address preSaleSigner_) external onlyOwner {
        _preSaleSigner = preSaleSigner_;
    }

    function setSale(Sale _sale) external onlyOwner {
        sale = _sale;
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    /**
     * Public mint method.
     * @dev Can't be called from a contract to avoid emptying
     * @param count The count of tokens to mint
     */
    function mint(uint256 count)
        external
        payable
        checkSale(Sale.Public)
        checkCount(count)
        checkFunds(count)
        checkSellableSupply(count)
    {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, ERROR_CONTRACT_MINT);

        _mintToken(count);
    }

    /**
     * Presale mint method
     * @param count The count of tokens to mint
     */
    function mintPreSale(uint256 count, bytes memory signature)
        external
        payable
        checkSale(Sale.PreSale)
        checkPreSaleCount(count)
        checkPreSaleSignature(signature)
        checkFunds(count)
        checkSellableSupply(count)
    {
        preSaleMintedTokens[msg.sender] = count + preSaleMintedTokens[msg.sender];
        _mintToken(count);
    }

    /**
     * Mint reserved token
     * @dev Mint RESERVED_TOKENS all at once
     * @dev Reserved tokens are always from 1-40
     * @dev Only owner can use this
     */
    function mintReserved() external onlyOwner checkReservedSupply {
        _hasMintedReserved = true;
        for (uint256 i = 1; i < RESERVED_TOKENS + 1; i++) {
            _safeMint(msg.sender, i);
        }
    }

    /**
     * Internal mint method that does the actual mint
     * @param count The count of tokens to mint
     */
    function _mintToken(uint256 count) private {
        for (uint256 i = 1; i < count + 1; i++) {
            _safeMint(msg.sender, _nextTokenId - 1 + i);
        }

        _nextTokenId += count;
    }

    /**
     * Check if sale is in appropriate status
     * @param _sale The sale status to validate
     */
    modifier checkSale(Sale _sale) {
        require(sale == _sale, ERROR_SALE);
        _;
    }

    /**
     * Check if mint count is under MAX_PER_MINT
     * @param count The count to mint
     */
    modifier checkCount(uint256 count) {
        require(count > 0 && count < MAX_PER_MINT + 1, ERROR_MAX_PER_MINT);
        _;
    }

    /**
     * Check if user can pay for mint
     * @param count The count to mint
     */
    modifier checkFunds(uint256 count) {
        require(msg.value == count * PRICE, ERROR_FUNDS);
        _;
    }

    /**
     * Check if there is still supply left
     * @param count The count to mint
     */
    modifier checkSellableSupply(uint256 count) {
        require(count + totalSupply() < MAX_SUPPLY + 1, ERROR_MAX_SUPPLY);
        _;
    }

    /**
     * Check if user has already minted in presale
     * @param count The count to mint
     */
    modifier checkPreSaleCount(uint256 count) {
        require(
            count + preSaleMintedTokens[msg.sender] < MAX_PRE_SALE_MINT + 1,
            ERROR_MAX_PRE_SALE_MINT
        );
        _;
    }

    /**
     * Check if the signature for presale is done by proper signer
     * @param signature The presale signatgure
     */
    modifier checkPreSaleSignature(bytes memory signature) {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender));
        address signer = digest.toEthSignedMessageHash().recover(signature);
        require(signer != address(0) && signer == _preSaleSigner, ERROR_PRE_SALE_SIGNATURE);
        _;
    }

    /**
     * Check if reserved has been minted
     */
    modifier checkReservedSupply() {
        require(_hasMintedReserved == false, ERROR_RESERVED_MINTED);
        _;
    }
}
