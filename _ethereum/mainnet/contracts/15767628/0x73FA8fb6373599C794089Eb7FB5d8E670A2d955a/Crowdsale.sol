// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Mintable.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with proper currency.
 */
contract Crowdsale is ContextUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // The token being sold
    IERC1155Mintable private _token;

    // The token received for NFT
    IERC20Upgradeable private _currency;

    // Address where funds are collected
    address private _wallet;

    // Amount of funds raised
    uint256 private _fundsRaised;

    /**
     * Event for token purchase logging
     * @param beneficiary who got the tokens
     * @param value paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed beneficiary, uint256 value, uint256 amount);

    struct SaleInfo {
        uint256 supply;
        uint256 price;
        uint256 tokenId;
        string tokenUri;
        uint256 minted; // number of minted tokens
        bool isActive;
    }

    mapping(uint256 => SaleInfo) public sales;
    uint256 public salesCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param owner_ Address of crowdsale contract owner
     * @param wallet_ Address where collected funds will be forwarded to
     * @param currency_ Address of the token received for NFT
     * @param token_ Address of the token being sold
     */
    function initialize(
        address owner_,
        address wallet_,
        IERC20Upgradeable currency_,
        IERC1155Mintable token_
    ) public initializer {
        __Context_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        require(owner_ != address(0), "Owner is the zero address");
        require(wallet_ != address(0), "Wallet is the zero address");
        require(address(token_) != address(0), "Token is the zero address");

        transferOwnership(owner_);

        _wallet = wallet_;
        _currency = currency_;
        _token = token_;

        _addSale(2000, 500 * 10**6, 1, "ipfs://QmQmtbBdD1SvAAu6MfKmbk1t5hCVzPHnmti7SKqLZJwnqm");
    }

    function setWallet(address wallet_) external onlyOwner {
        require(wallet_ != address(0), "Wallet is the zero address");
        _wallet = wallet_;
    }

    function setCurrency(address currency_) external onlyOwner {
        require(currency_ != address(0), "Wallet is the zero address");
        _currency = IERC20Upgradeable(currency_);
    }

    function setToken(address token_) external onlyOwner {
        _setToken(IERC1155Mintable(token_));
    }

    function addSale(
        uint256 supply,
        uint256 price,
        uint256 tokenId,
        string calldata tokenUri
    ) external onlyOwner {
        require(supply > 0, "Invalid supply");
        require(price > 0, "Invalid price");

        _addSale(supply, price, tokenId, tokenUri);
    }

    function activateSale(uint256 saleIdx) external onlyOwner {
        require(sales[saleIdx].supply != 0, "Sale does not exist");

        sales[saleIdx].isActive = true;
    }

    function deactivateSale(uint256 saleIdx) external onlyOwner {
        require(sales[saleIdx].supply != 0, "Sale does not exist");

        sales[saleIdx].isActive = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC1155Mintable) {
        return _token;
    }

    /**
     * @return the token received for NFT.
     */
    function currency() public view returns (IERC20Upgradeable) {
        return _currency;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address) {
        return _wallet;
    }

    /**
     * @return the amount of wei raised.
     */
    function fundsRaised() public view returns (uint256) {
        return _fundsRaised;
    }

    /**
     * @param saleIdx Sale index
     * @param tokenAmount Amount of token to buy
     */
    function buyTokens(uint256 saleIdx, uint256 tokenAmount) external whenNotPaused {
        SaleInfo memory sale = sales[saleIdx];

        _preValidatePurchase(_msgSender(), sale, tokenAmount);

        sales[saleIdx].minted = sale.minted + tokenAmount;
        _processPurchase(_msgSender(), tokenAmount, sale);
    }

    function _addSale(
        uint256 supply,
        uint256 price,
        uint256 tokenId,
        string memory tokenUri
    ) internal {
        uint256 newSalesCount = salesCount;
        sales[newSalesCount] = SaleInfo(supply, price, tokenId, tokenUri, 0, false);
        salesCount = newSalesCount + 1;
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised() + weiAmount <= cap);
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Token amount to purchase
     */
    function _preValidatePurchase(
        address beneficiary,
        SaleInfo memory sale,
        uint256 tokenAmount
    ) internal view virtual {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(sale.supply != 0, "Sale does not exist");
        require(sale.isActive == true, "Sale is inactive");
        require(sale.minted + tokenAmount <= sale.supply, "Too many tokens claimed");
        require(tokenAmount > 0, "Invalid token amount claimed");
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     * @param sale Sale data
     */
    function _processPurchase(
        address beneficiary,
        uint256 tokenAmount,
        SaleInfo memory sale
    ) internal virtual {
        // calculate funds to be transferred
        uint256 value = tokenAmount * sale.price;
        _fundsRaised = _fundsRaised + value;

        _currency.safeTransferFrom(beneficiary, _wallet, value);
        _token.mint(beneficiary, sale.tokenId, tokenAmount, sale.tokenUri);

        emit TokensPurchased(beneficiary, value, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Allows to change token address.
     */
    function _setToken(IERC1155Mintable token_) internal {
        require(address(token_) != address(0), "Token is the zero address");
        _token = token_;
    }

    uint256[46] private __gap;
}
