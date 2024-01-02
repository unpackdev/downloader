// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC1155StoreGeneric {
    /**
     * @notice Struct for a token sale
     * @param _token The token being sold
     * @param _tokenId The token id being sold
     * @param _unitSize Number of tokens being sold as a single unit
     * @param _totalUnitSupply Total number of units being offered
     * @param _unitPrice Price of a single unit
     * @param _unitsPerUser Max amount of units allowed for a single user
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     * @param _paused Sale state
     * @param _adminSupplied Whether or not the tokens for the sale will be admin-supplied
     * @param _isERC1155Payment Whether the sale should be paid with erc1155 token
     * @param _erc1155PaymentTokenId erc1155 token with which payment is done in case of erc1155 payment
     */
    struct Sale {
        address token;
        uint256 tokenId;
        uint256 unitSize;
        uint256 totalUnitSupply;
        uint256 unitPrice;
        uint256 unitsPerUser;
        address defaultCurrency;
        bool profitState;
        bool paused;
        bool adminSupplied;
    }

    // Used to classify token types in the ownership rebate struct
    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @notice Used to provide specifics for ownership based discounts
     * @param tokenType The type of token
     * @param tokenAddress The address of the token contract
     * @param tokenId The token id, ignored if ERC721 is provided for the token type
     * @param basisPoints The discount in basis points
     */
    struct OwnershipDiscount {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId; // ignored if ERC721
        uint256 basisPoints;
    }

    /// TODO add natspec
    struct Beneficiaries {
        uint256[] feeBps;
        address[] beneficiary;
    }

    struct BuyTokenInputs {
        address buyer;
        address tokenAddress;
        uint256 tokenId;
        uint256 numPurchases;
        uint256 saleId;
        bool isERC1155Payment;
        uint256 erc1155PaymentTokenId;
    }

    event SaleCreated(
        address _token,
        uint256 _tokenId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState,
        bool _adminSupplied
    );

    event SaleModified(
        uint256 _saleId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState
    );

    event SaleDeleted(uint256 _saleId);

    event SaleStateSet(uint256 _saleId, bool _paused);

    event BulkDiscountAdded(uint256 _saleId, uint256 _breakpoint, uint256 _basisPoints);

    event OwnershipDiscountAdded(uint256 _saleId, OwnershipDiscount _info);

    event CurrenciesWhitelisted(uint256 _saleId, address[] _currencyAddresses);

    event Withdrawal(address _walletAddress, address _currency);

    event PaperCurrencySet(address _paperCurrency);

    event SaleBonusSet(address _saleBonuses);

    event TokenBought(
        uint256 _saleId,
        uint256 _numPurchases,
        uint256 _tokenId,
        address _tokenAddress,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories,
        address _buyer
    );

    event SetERC1155PaymentPrices(uint256 _saleId, uint256[] _erc1155TokenIds, uint256[] _erc1155TokenPrices);

    /**
     * @notice Creates a new sale for a particular token.
     * @param _token The token being sold
     * @param _tokenId The token id being sold
     * @param _unitSize Number of tokens being sold as a single unit
     * @param _totalUnitSupply Total number of units being offered
     * @param _unitPrice Price of a single unit
     * @param _unitsPerUser Max amount of units allowed for a single user
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     * @param _adminSupplied Whether or not the tokens for the sale will be admin-supplied
     */
    function createSale(
        address _token,
        uint256 _tokenId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState,
        bool _adminSupplied
    ) external returns (uint256 _saleId);

    /**
     * @notice Sets ERC1155 prices for the given sale
     * @param _saleId Id of the sale to set ERC1155 prices
     * @param _ERC1155PaymentAddress Address of the ERC1155 payment token
     * @param  _erc1155PaymentTokenIds Ids of the ERC1155 tokens which are enabled for the payment
     * @param  _erc1155PaymentPrices Prices of ERC1155 payments for corresponding token ids
     */
    function setERC1155PaymentPrices(
        uint256 _saleId,
        address _ERC1155PaymentAddress,
        uint256[] calldata _erc1155PaymentTokenIds,
        uint256[] calldata _erc1155PaymentPrices
    ) external;

    /**
     * @notice Modifies a pre-existing sale for a token.
     * @param _saleId Id of the sale to alter
     * @param _unitSize Number of tokens being sold as a single unit
     * @param _totalUnitSupply Total number of units being offered
     * @param _unitPrice Price of a single unit
     * @param _unitsPerUser Max amount of units allowed for a single user
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     */
    function modifySale(
        uint256 _saleId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState
    ) external;

    /**
     * @notice Delete a sale
     * @param _saleId The sale ID to delete
     */
    function deleteSale(uint256 _saleId) external;

    /**
     * @notice Start or pause sales
     * @param _saleId The sale ID to set the status for
     * @param _paused The sale status
     */
    function setSaleState(uint256 _saleId, bool _paused) external;

    /**
     * @notice Whitelists currencies to be used in a particular sale
     * @param _saleId The sale id
     * @param _currencyAddresses The addresses payment currencies to whitelist
     */
    function whitelistCurrencies(uint256 _saleId, address[] calldata _currencyAddresses) external;

    /**
     * @notice Empty the treasury into the owners or an arbitrary wallet
     * @param _walletAddress The withdrawal EOA address
     * @param _currency ERC20 currency to withdraw, ZERO address implies MATIC
     */
    function withdraw(address _walletAddress, address _currency) external;

     /**
     * @notice Empty the treasury of ERC1155 into the owners or an arbitrary wallet
     * @param _walletAddress The withdrawal EOA address
     * @param _tokenAddress Address of the ERC1155 token to withdraw
     * @param _tokenId ID of the ERC1155 token to withdraw
     */    
    function withdrawERC1155token(
        address _walletAddress, 
        address _tokenAddress, 
        uint256 _tokenId
    ) external;

    /**
     * @notice Purchase any active sale in any whitelisted currency
     */
    function buyTokens(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories
    ) external payable;

    /**
     * @notice  Set Fee Wallets and fee percentages from sales
     * @param _walletAddresses The withdrawal EOA addresses
     * @param _feeBps Represented as basis points e.g. 500 == 5 pct
     */
    function setFeeWalletsAndPercentages(
        address[] calldata _walletAddresses,
        uint256[] calldata _feeBps
    ) external;

    /**
     * @notice Set a swap manager to manage the means through which tokens are exchanged
     * @param _swapManager SwapManager address
     */
    function setSwapManager(address _swapManager) external;

    /**
     * @notice Set a oracle manager to manage the means through which token prices are fetched
     * @param _oracleManager OracleManager address
     */
    function setOracleManager(address _oracleManager) external;

    /**
     * @notice Set administrator
     * @param _moderatorAddress The addresse of an allowed admin
     */
    function setModerator(address _moderatorAddress) external;

    /**
     * @notice adaptor to allow purchases via Paper.xyz
     * @dev Price is calculated implicitly from _saleId, _numPurchases
     */
    function onPaper(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId
    ) external;

    /**
     * @notice eligibility function to check if the player can purchase a pack based upon
     *          token ownership discounts and purchase quantity
     * @param _buyer the buyers' EOA address
     * @param _tokenAddressRebate The token address for the tokenId claimed to be owned (for rebates)
     * @param _tokenIdRebate The token id, ignored if ERC721 is provided for the token type
     * @param _numPurchases the number of packs to purchase
     * @param _saleId the sale ID of the pack to purchase
     */
    function tokenClaimable(
        address _buyer,
        address _tokenAddressRebate,
        uint256 _tokenIdRebate,
        uint256 _numPurchases,
        uint256 _saleId
    ) external view returns (string memory);

    /**
     * @notice Set the payment currency token for paper
     * @param _paperCurrency The address of the supported paper currency token
     */
    function setPaperCurrency(address _paperCurrency) external;
}
