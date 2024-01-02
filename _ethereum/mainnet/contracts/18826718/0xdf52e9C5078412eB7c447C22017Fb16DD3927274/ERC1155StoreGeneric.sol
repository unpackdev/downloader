// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ISaleBonuses.sol";
import "./ISwapManager.sol";
import "./IOracleManager.sol";
import "./ITrustedMintable.sol";
import "./IERC1155StoreGeneric.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC1155.sol";
import "./IERC1155.sol";
import "./IPaperKeyManager.sol";
import "./ERC1155Receiver.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";

error SG__ZeroValue();
error SG__ZeroAddress();
error SG__ZeroSaleCap();
error SG__SaleInactive();
error SG__ZeroUnitSize();
error SG__RefundFailed();
error SG__TransferFailed();
error SG__ZeroUserSaleCap();
error SG__WithdrawalFailed();
error SG__NotGov(address _user);
error SG__InvalidSaleParameters();
error SG__PurchaseExceedsTotalMax();
error SG__PurchaseExceedsPlayerMax();
error SG__NotERC1155(address _token);
error SG__TokenNotSet(uint256 _tokenId);
error SG__ValueTooLarge(uint256 _amount);
error SG__InvalidERC1155PaymentTokenId();
error SG__NonExistentSale(uint256 _saleId);
error SG__PaperCurrencyTokenAddressNotSet();
error SG__ERC155PaymentDifferentArrayLength();
error SG__NotBeneficiary(address _walletAddress);
error SG__CurrencyNotWhitelisted(address _currency);
error SG__TokenNotEligibleForRebate(address _token);
error SG__DiscountTooLarge(uint256 _amount, uint256 _target);
error SG__SenderDoesNotOwnToken(address _token, uint256 _tokenId);
error SG__InsufficientEthValue(uint256 _amountSent, uint256 _price);
error SG__CombinedDiscountTooLarge(
    uint256 _saleId,
    uint256 _price,
    uint256 _bulkDsc,
    uint256 _ownershipDsc
);


/**
 * @title ERC1155 Store Generic
 * @author Jourdan
 * @notice This is a reusable token sale contract for PlanetIX
 */
contract ERC1155StoreGeneric is
    IERC1155StoreGeneric,
    ERC1155Receiver,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable
{
    /*------------------- STATE VARIABLES -------------------*/

    uint256 public s_saleId;
    address public s_moderator;
    address public s_tokenDonor;
    address public s_paperCurrency;

    Beneficiaries s_beneficiaries;
    uint256 private s_adminEthPayout; // disabled
    mapping(address => uint256) private s_adminTokenPayout; // disabled
    mapping(address => uint256) private s_beneficiaryBalances;
    mapping(address => mapping(address => uint256)) private s_beneficiaryTokenBalances;

    mapping(uint256 => Sale) public s_sales;
    mapping(uint256 => uint256) public s_sold;
    mapping(uint256 => bool) public s_saleStatus;
    mapping(uint256 => mapping(address => uint256)) public s_perPlayerSold;
    mapping(uint256 => mapping(address => bool)) public s_whitelistedCurrencies;

    mapping(uint256 => uint256[]) public s_bulkDiscountBreakpoints;
    mapping(uint256 => uint256[]) public s_bulkDiscountBasisPoints;
    mapping(uint256 => OwnershipDiscount[]) public s_ownershipDiscounts;

    mapping(address => bool) public s_isBeneficiary;
    mapping(address => bool) public s_trustedAddresses;
    uint256 public constant MAXIMUM_BASIS_POINTS = 10_000;

    IOracleManager public s_oracle;
    ISwapManager public s_swapManager;
    ISaleBonuses public s_saleBonuses;
    IPaperKeyManager public paperKeyManager;

    bool public publicSale;
    address private s_signer;
    bytes32 private constant BUY_MESSAGE =
        keccak256("BuyMessage(uint256 id,address sender,uint256 nonce)");
    mapping(address => mapping(uint256 => uint256)) public nonces;
    mapping(uint256 => bool) public preSale;

    mapping(uint256 => address) public s_ERC1155PaymentTokenAddress;
    mapping(uint256 => mapping(uint256 => uint256)) public s_ERC1155tokenPaymentPrices;

    /*------------------- MODIFIERS -------------------*/

    modifier onlyGov() virtual {
        if (msg.sender != owner() && msg.sender != s_moderator) revert SG__NotGov(msg.sender);
        _;
    }

    modifier onlyBeneficiary() {
        if (!s_isBeneficiary[msg.sender]) revert SG__NotBeneficiary(msg.sender);
        _;
    }

    modifier onlyPaper(
        bytes32 _hash,
        bytes32 _nonce,
        bytes calldata _signature
    ) {
        bool success = paperKeyManager.verify(_hash, _nonce, _signature);
        require(success, "Failed to verify signature");
        _;
    }

    modifier onlyPresale(uint256 _id) {
        require(preSale[_id], "Sale not currently in presale status");
        _;
    }

    modifier onlyPublicSale(uint256 _id) {
        require(!preSale[_id], "Sale not currently in public sale status");
        _;
    }

    /*------------------- INITIALIZER -------------------*/

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __EIP712_init("Generic__Store", "1");
    }

    /*------------------- ADMIN - ONLY FUNCTIONS -------------------*/

    /// @inheritdoc IERC1155StoreGeneric
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
    ) public override onlyGov returns (uint256 _saleId) {
        // if (!ERC165CheckerUpgradeable.supportsInterface(_token, type(ITrustedMintable).interfaceId)) revert SG__NotERC1155(_token);
        if (_unitSize == 0) revert SG__ZeroUnitSize();
        if (_totalUnitSupply == 0) revert SG__ZeroSaleCap();
        if (_unitsPerUser == 0) revert SG__ZeroUserSaleCap();
        // if (bytes(ERC1155(_token).uri(_tokenId)).length == 0) revert SG__TokenNotSet(_tokenId);

        unchecked {
            _saleId = ++s_saleId;
        }

        s_sales[s_saleId] = Sale({
            token: _token,
            tokenId: _tokenId,
            unitSize: _unitSize,
            totalUnitSupply: _totalUnitSupply,
            unitPrice: _unitPrice,
            unitsPerUser: _unitsPerUser,
            defaultCurrency: _defaultCurrency,
            profitState: _profitState,
            paused: true,
            adminSupplied: _adminSupplied
        });

        s_whitelistedCurrencies[s_saleId][_defaultCurrency] = true;

        if (_adminSupplied) {
            IERC1155Upgradeable(_token).safeTransferFrom(
                s_tokenDonor,
                address(this),
                _tokenId,
                _totalUnitSupply * _unitSize,
                ""
            );
        }

        emit SaleCreated(
            _token,
            _tokenId,
            _unitSize,
            _totalUnitSupply,
            _unitPrice,
            _unitsPerUser,
            _defaultCurrency,
            _profitState,
            _adminSupplied
        );
    }

    /// @inheritdoc IERC1155StoreGeneric
    function modifySale(
        uint256 _saleId,
        uint256 _unitSize,
        uint256 _totalUnitSupply,
        uint256 _unitPrice,
        uint256 _unitsPerUser,
        address _defaultCurrency,
        bool _profitState
    ) external onlyGov {
        if (s_sales[_saleId].tokenId == 0) revert SG__NonExistentSale(_saleId);
        if (_unitSize == 0) revert SG__ZeroUnitSize();
        if (_totalUnitSupply == 0) revert SG__ZeroSaleCap();
        if (_unitsPerUser == 0) revert SG__ZeroUserSaleCap();

        uint256 totalTokensBefore = s_sales[_saleId].unitSize *
            (s_sales[_saleId].totalUnitSupply - s_sold[_saleId]);
        uint256 totalTokensAfter = _unitSize * _totalUnitSupply;

        s_sales[_saleId].unitSize = _unitSize;
        s_sales[_saleId].totalUnitSupply = _totalUnitSupply;
        s_sales[_saleId].unitPrice = _unitPrice;
        s_sales[_saleId].unitsPerUser = _unitsPerUser;
        s_sales[_saleId].defaultCurrency = _defaultCurrency;
        s_sales[_saleId].profitState = _profitState;

        if (s_sales[_saleId].adminSupplied) {
            if (totalTokensAfter > totalTokensBefore) {
                IERC1155Upgradeable(s_sales[_saleId].token).safeTransferFrom(
                    s_tokenDonor,
                    address(this),
                    s_sales[_saleId].tokenId,
                    (totalTokensAfter - totalTokensBefore),
                    ""
                );
            }
            if (totalTokensAfter < totalTokensBefore) {
                IERC1155Upgradeable(s_sales[_saleId].token).safeTransferFrom(
                    address(this),
                    s_tokenDonor,
                    s_sales[_saleId].tokenId,
                    (totalTokensBefore - totalTokensAfter),
                    ""
                );
            }
        }

        emit SaleModified(
            _saleId,
            _unitSize,
            _totalUnitSupply,
            _unitPrice,
            _unitsPerUser,
            _defaultCurrency,
            _profitState
        );
    }

    /// @inheritdoc IERC1155StoreGeneric
    function deleteSale(uint256 _saleId) external onlyGov {
        if (s_sales[_saleId].tokenId == 0) revert SG__NonExistentSale(_saleId);

        bool adminSupplied = s_sales[_saleId].adminSupplied;
        address token = s_sales[_saleId].token;
        uint256 tokenId = s_sales[_saleId].tokenId;
        uint256 tokensRemaining = s_sales[_saleId].unitSize *
            (s_sales[_saleId].totalUnitSupply - s_sold[_saleId]);

        delete s_sales[_saleId];
        delete s_sold[_saleId];
        if (s_ownershipDiscounts[_saleId].length > 0) {
            delete s_ownershipDiscounts[_saleId];
        }
        if (s_bulkDiscountBasisPoints[_saleId].length > 0) {
            delete s_bulkDiscountBasisPoints[_saleId];
            delete s_bulkDiscountBreakpoints[_saleId];
        }

        if (adminSupplied) {
            IERC1155Upgradeable(token).safeTransferFrom(
                address(this),
                s_tokenDonor,
                tokenId,
                tokensRemaining,
                ""
            );
        }

        emit SaleDeleted(_saleId);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setSaleState(uint256 _saleId, bool _paused) external onlyGov {
        if (s_sales[_saleId].tokenId == 0) revert SG__NonExistentSale(_saleId);
        s_sales[_saleId].paused = _paused;

        emit SaleStateSet(_saleId, _paused);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setERC1155PaymentPrices(
        uint256 _saleId,
        address _ERC1155PaymentAddress,
        uint256[] calldata _erc1155PaymentTokenIds,
        uint256[] calldata _erc1155PaymentPrices
    ) public override onlyGov {
        if (_erc1155PaymentTokenIds.length != _erc1155PaymentPrices.length) revert SG__ERC155PaymentDifferentArrayLength();

        s_whitelistedCurrencies[_saleId][_ERC1155PaymentAddress] = true;

        s_ERC1155PaymentTokenAddress[_saleId] = _ERC1155PaymentAddress;

        for(uint i=0; i<_erc1155PaymentTokenIds.length; i++) {
            s_ERC1155tokenPaymentPrices[_saleId][ _erc1155PaymentTokenIds[i] ] = _erc1155PaymentPrices[i];
        } 

        emit SetERC1155PaymentPrices(_saleId, _erc1155PaymentTokenIds, _erc1155PaymentPrices);
    } 

    /// @inheritdoc IERC1155StoreGeneric
    function whitelistCurrencies(uint256 _saleId, address[] calldata _currencyAddresses)
        external
        onlyGov
    {
        for (uint256 i; i < _currencyAddresses.length; i++) {
            s_whitelistedCurrencies[_saleId][_currencyAddresses[i]] = true;
        }

        emit CurrenciesWhitelisted(_saleId, _currencyAddresses);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function withdraw(address _walletAddress, address _currency) external nonReentrant onlyGov {
        if (_currency == address(0)) {
            (bool success, ) = payable(_walletAddress).call{value: address(this).balance}("");
            if (!success) revert SG__WithdrawalFailed();
        } else {
            uint256 amount = IERC20(_currency).balanceOf(address(this));
            bool success = IERC20(_currency).transfer(_walletAddress, amount);
            if (!success) revert SG__WithdrawalFailed();
        }

        emit Withdrawal(_walletAddress, _currency);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function withdrawERC1155token(
        address _walletAddress, 
        address _tokenAddress, 
        uint256 _tokenId
    ) external nonReentrant onlyGov {
        uint256 balance = IERC1155(_tokenAddress).balanceOf(address(this), _tokenId);
        IERC1155(_tokenAddress).safeTransferFrom(address(this), _walletAddress, _tokenId, balance, "");
    }

    function beneficiaryWithdraw(address _currency) external nonReentrant onlyBeneficiary {
        if (_currency == address(0)) {
            if (s_beneficiaryBalances[msg.sender] == 0) revert SG__ZeroValue();
            uint256 amount = s_beneficiaryBalances[msg.sender];
            s_beneficiaryBalances[msg.sender] = 0;
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            if (!success) revert SG__WithdrawalFailed();
        } else {
            if (s_beneficiaryTokenBalances[msg.sender][_currency] == 0) revert SG__ZeroValue();
            uint256 amount = s_beneficiaryTokenBalances[msg.sender][_currency];
            s_beneficiaryTokenBalances[msg.sender][_currency] = 0;
            IERC20(_currency).approve(address(this), amount);
            bool success = IERC20(_currency).transferFrom(address(this), msg.sender, amount);
            if (!success) revert SG__WithdrawalFailed();
        }

        emit Withdrawal(msg.sender, _currency);
    }

    function setPaperCurrency(address _paperCurrency) external onlyGov {
        if (_paperCurrency == address(0)) revert SG__ZeroAddress();
        s_paperCurrency = _paperCurrency;

        emit PaperCurrencySet(_paperCurrency);
    }

    function setSaleBonuses(address _saleBonuses) external onlyGov {
        if (_saleBonuses == address(0)) revert SG__ZeroAddress();
        s_saleBonuses = ISaleBonuses(_saleBonuses);

        emit SaleBonusSet(_saleBonuses);
    }

    function setPaperKeyManager(IPaperKeyManager _paperKey) external onlyOwner {
        paperKeyManager = _paperKey;
    }

    function registerPaperKey(address _paperKey) external onlyOwner {
        require(paperKeyManager.register(_paperKey), "Error registering key");
    }

    function toggleState(uint256 _saleId) external onlyGov {
        preSale[_saleId] = !preSale[_saleId];
    }

    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "ADDRESS_ZERO");
        s_signer = _signer;
    }

    /*------------------- EXTERNAL FUNCTIONS -------------------*/

    /// @inheritdoc IERC1155StoreGeneric
    function buyTokens(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories
    ) external payable onlyPublicSale(saleId) {
        BuyTokenInputs memory saleInputs = BuyTokenInputs({
            buyer: buyer,
            tokenAddress: tokenAddressRebate,
            tokenId: tokenIdRebate,
            numPurchases: numPurchases,
            saleId: saleId,
            isERC1155Payment: false,
            erc1155PaymentTokenId: 0
        });

       _buyTokens(saleInputs, _currency, _optInBonuses, _optInCategories);
    }

    function buyTokensWithERC1155(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories,
        uint256 _erc1155PaymentTokenId
    ) external onlyPublicSale(saleId) {
        BuyTokenInputs memory saleInputs = BuyTokenInputs({
            buyer: buyer,
            tokenAddress: tokenAddressRebate,
            tokenId: tokenIdRebate,
            numPurchases: numPurchases,
            saleId: saleId,
            isERC1155Payment: true,
            erc1155PaymentTokenId: _erc1155PaymentTokenId
        });

        _buyTokens(saleInputs, _currency, _optInBonuses, _optInCategories);
    }

    function buyTokensWithSignature(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable onlyPresale(saleId) {
        BuyTokenInputs memory saleInputs = BuyTokenInputs({
            buyer: buyer,
            tokenAddress: tokenAddressRebate,
            tokenId: tokenIdRebate,
            numPurchases: numPurchases,
            saleId: saleId,
            isERC1155Payment: false,
            erc1155PaymentTokenId: 0
        });

        uint256 nonce = nonces[msg.sender][saleInputs.saleId]++;

        bytes32 structHash = keccak256(
            abi.encode(BUY_MESSAGE, saleInputs.saleId, msg.sender, nonce)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == s_signer, "INVALID__SIGNATURE");

        _buyTokens(saleInputs, _currency, _optInBonuses, _optInCategories);
    }

    function onPaper(
        address buyer,
        address tokenAddressRebate,
        uint256 tokenIdRebate,
        uint256 numPurchases,
        uint256 saleId
    ) external onlyPublicSale(saleId) {
        BuyTokenInputs memory saleInputs = BuyTokenInputs({
            buyer: buyer,
            tokenAddress: tokenAddressRebate,
            tokenId: tokenIdRebate,
            numPurchases: numPurchases,
            saleId: saleId,
            isERC1155Payment: false,
            erc1155PaymentTokenId: 0
        });
        if (s_paperCurrency == address(0)) revert SG__PaperCurrencyTokenAddressNotSet();
        _buyTokens(saleInputs, s_paperCurrency, false, false);
    }

    function tokenClaimable(
        address _buyer,
        address _tokenAddressRebate,
        uint256 _tokenIdRebate,
        uint256 _numPurchases,
        uint256 _saleId
    ) external view returns (string memory) {
        uint256 discountAmount;
        uint256 tokenType;
        Sale memory info = s_sales[_saleId];

        if (s_sales[_saleId].paused == true) return "SALE_INACTIVE";

        if (_tokenAddressRebate != address(0)) {
            OwnershipDiscount[] memory discounts = s_ownershipDiscounts[_saleId];
            for (uint256 i; i < discounts.length; ++i) {
                if (
                    discounts[i].tokenAddress == _tokenAddressRebate &&
                    (discounts[i].tokenType == TokenType.ERC721 ||
                        (discounts[i].tokenType == TokenType.ERC1155 &&
                            discounts[i].tokenId == _tokenIdRebate))
                ) {
                    discountAmount = discounts[i].basisPoints;
                    tokenType = uint256(discounts[i].tokenType);
                }
            }
            if (discountAmount > 0) {
                if (tokenType == 0) {
                    if (IERC721Upgradeable(_tokenAddressRebate).ownerOf(_tokenIdRebate) != _buyer) {
                        return "ERC721_NOT_OWNED";
                    }
                }
                if (tokenType == 1) {
                    if (
                        IERC1155Upgradeable(_tokenAddressRebate).balanceOf(
                            _buyer,
                            _tokenIdRebate
                        ) == 0
                    ) {
                        return "ERC1155_NOT_OWNED";
                    }
                }
            } else {
                return "DISCOUNT_NONEXISTENT";
            }
        }

        if (s_perPlayerSold[_saleId][_buyer] + _numPurchases > info.unitsPerUser) {
            return "BUYER_LIMIT_EXCEEDED";
        }
        if (s_sold[_saleId] + _numPurchases > info.totalUnitSupply) {
            return "TOTAL_LIMIT_EXCEEDED";
        }
        return "";
    }

    /*------------------- INTERNAL FUNCTIONS -------------------*/

    function _buyTokens(
        BuyTokenInputs memory saleInputs,
        address _currency,
        bool _optInBonuses,
        bool _optInCategories
    ) internal {
        if (s_sales[saleInputs.saleId].tokenId == 0) revert SG__NonExistentSale(saleInputs.saleId);
        if (s_sales[saleInputs.saleId].paused == true) revert SG__SaleInactive();
        if (s_whitelistedCurrencies[saleInputs.saleId][_currency] == false)
            revert SG__CurrencyNotWhitelisted(_currency);
        if (
            s_perPlayerSold[saleInputs.saleId][saleInputs.buyer] + saleInputs.numPurchases >
            s_sales[saleInputs.saleId].unitsPerUser
        ) revert SG__PurchaseExceedsPlayerMax();
        if (
            s_sold[saleInputs.saleId] + saleInputs.numPurchases >
            s_sales[saleInputs.saleId].totalUnitSupply
        ) revert SG__PurchaseExceedsTotalMax();

        unchecked {
            s_perPlayerSold[saleInputs.saleId][saleInputs.buyer] += saleInputs.numPurchases;
            s_sold[saleInputs.saleId] += saleInputs.numPurchases;
        }

        Sale memory sale = s_sales[saleInputs.saleId];

        if (saleInputs.isERC1155Payment) {
            uint256 price = 
                saleInputs.numPurchases * s_ERC1155tokenPaymentPrices[saleInputs.saleId][saleInputs.erc1155PaymentTokenId];

            if (price == 0) revert SG__InvalidERC1155PaymentTokenId();

            _erc1155Payment(
                msg.sender, 
                s_ERC1155PaymentTokenAddress[saleInputs.saleId],
                saleInputs.erc1155PaymentTokenId, 
                price
            );
        } else {
            uint256 balance = _applyBulkDiscount(saleInputs.saleId, saleInputs.numPurchases);
            if (saleInputs.tokenAddress != address(0))
                balance = _applyOwnershipDiscount(
                    saleInputs.saleId,
                    balance,
                    saleInputs.tokenAddress,
                    saleInputs.tokenId,
                    saleInputs.buyer
                );

            if (_currency == address(0)) {
                _ethPayment(msg.sender, sale.defaultCurrency, _currency, balance);
            } else {
                _erc20Payment(msg.sender, sale.defaultCurrency, _currency, balance, sale.profitState);
            }
        }

        if (_optInBonuses) {
            s_saleBonuses.claimBonusReward(
                saleInputs.saleId,
                uint32(saleInputs.numPurchases),
                _optInCategories,
                saleInputs.buyer
            );
        }

        if (!sale.adminSupplied) {
            ITrustedMintable(sale.token).trustedMint(
                saleInputs.buyer,
                sale.tokenId,
                sale.unitSize * saleInputs.numPurchases
            );
        } else {
            IERC1155Upgradeable(sale.token).safeTransferFrom(
                address(this),
                saleInputs.buyer,
                sale.tokenId,
                sale.unitSize * saleInputs.numPurchases,
                ""
            );
        }

        emit TokenBought(
            saleInputs.saleId,
            saleInputs.numPurchases,
            saleInputs.tokenId,
            saleInputs.tokenAddress,
            _currency,
            _optInBonuses,
            _optInCategories,
            saleInputs.buyer
        );
    }

    function _applyBulkDiscount(uint256 _saleId, uint256 _numPurchases)
        internal
        view
        returns (uint256 _finalPrice)
    {
        uint256 mod = MAXIMUM_BASIS_POINTS;
        uint256[] memory breakpoints = s_bulkDiscountBreakpoints[_saleId];
        uint256[] memory discounts = s_bulkDiscountBasisPoints[_saleId];
        for (uint256 i; i < breakpoints.length; i++) {
            if (_numPurchases >= breakpoints[i]) {
                mod -= discounts[i];
            }
        }
        _finalPrice = (mod * s_sales[_saleId].unitPrice * _numPurchases) / MAXIMUM_BASIS_POINTS;
    }

    function _applyOwnershipDiscount(
        uint256 _saleId,
        uint256 _balance,
        address _tokenAddress,
        uint256 _tokenId,
        address _buyer
    ) internal view returns (uint256 _finalPrice) {
        uint256 discountBps;
        uint256 tokenType;
        OwnershipDiscount[] memory discounts = s_ownershipDiscounts[_saleId];

        for (uint256 i; i < discounts.length; ++i) {
            if (
                discounts[i].tokenAddress == _tokenAddress &&
                (discounts[i].tokenType == TokenType.ERC721 ||
                    (discounts[i].tokenType == TokenType.ERC1155 &&
                        discounts[i].tokenId == _tokenId))
            ) {
                discountBps = discounts[i].basisPoints;
                tokenType = uint256(discounts[i].tokenType);
            }
        }
        if (discountBps > 0) {
            bool applyRebate;
            if (tokenType == 0) {
                if (IERC721Upgradeable(_tokenAddress).balanceOf(_buyer) > 0) {
                    applyRebate = true;
                } else {
                    revert SG__SenderDoesNotOwnToken(_tokenAddress, 0);
                }
            }
            if (tokenType == 1) {
                if (IERC1155Upgradeable(_tokenAddress).balanceOf(_buyer, _tokenId) > 0) {
                    applyRebate = true;
                } else {
                    revert SG__SenderDoesNotOwnToken(_tokenAddress, _tokenId);
                }
            }
            if (applyRebate) _finalPrice = _calculateDiscountedPrice(discountBps, _balance);
        } else {
            revert SG__TokenNotEligibleForRebate(_tokenAddress);
        }
    }

    function _ethPayment(
        address _recipient,
        address _defaultCurrency,
        address _currency,
        uint256 _balance
    ) internal {
        uint256 ethPrice;
        if (_currency == _defaultCurrency) {
            ethPrice = _balance;
        } else {
            ethPrice = s_oracle.getAmountOut(_defaultCurrency, _currency, _balance);
        }
        if (ethPrice > msg.value) {
            revert SG__InsufficientEthValue(msg.value, ethPrice);
        } else {
            Beneficiaries memory beneficiaries = s_beneficiaries;
            uint256 beneficiariesSize = beneficiaries.feeBps.length;
            for (uint256 i; i < beneficiariesSize; ++i) {
                uint256 amount = (beneficiaries.feeBps[i] * ethPrice) / MAXIMUM_BASIS_POINTS;
                s_beneficiaryBalances[beneficiaries.beneficiary[i]] += amount;
            }

            if (msg.value - ethPrice > 0) {
                (bool callSuccess, ) = payable(_recipient).call{value: msg.value - ethPrice}("");
                if (!callSuccess) revert SG__RefundFailed();
            }
        }
    }

    function _erc20Payment(
        address _recipient,
        address _defaultCurrency,
        address _currency,
        uint256 _balance,
        bool _profitState
    ) internal {
        uint256 erc20Price;
        if (_currency == _defaultCurrency) {
            erc20Price = _balance;
        } else {
            erc20Price = s_oracle.getAmountOut(_defaultCurrency, _currency, _balance);
        }
        if (!IERC20(_currency).transferFrom(_recipient, address(this), erc20Price))
            revert SG__TransferFailed();
        if (!_profitState && (_currency != _defaultCurrency)) {
            IERC20(_currency).approve(address(s_swapManager), erc20Price);
            s_swapManager.swap(_currency, _defaultCurrency, erc20Price, address(this));
            _distributeBeneficiaryTokens(_defaultCurrency, _balance);
        } else {
            _distributeBeneficiaryTokens(_currency, erc20Price);
        }
    }

    function _erc1155Payment(
        address _recipient,
        address _paymentTokenAddress,
        uint256 _paymentTokenId,
        uint256 _balance
    ) internal {
        IERC1155(_paymentTokenAddress).safeTransferFrom(_recipient, address(this), _paymentTokenId, _balance, "");
    }

    function _calculateDiscountedPrice(uint256 _bps, uint256 _salePrice)
        public
        pure
        returns (uint256)
    {
        return ((MAXIMUM_BASIS_POINTS - _bps) * _salePrice) / MAXIMUM_BASIS_POINTS;
    }

    function _distributeBeneficiaryTokens(address _currency, uint256 _price) internal {
        Beneficiaries memory beneficiaries = s_beneficiaries;
        uint256 beneficiariesSize = beneficiaries.feeBps.length;
        for (uint256 i; i < beneficiariesSize; ++i) {
            uint256 amount = (beneficiaries.feeBps[i] * _price) / MAXIMUM_BASIS_POINTS;
            s_beneficiaryTokenBalances[beneficiaries.beneficiary[i]][_currency] += amount;
        }
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setFeeWalletsAndPercentages(
        address[] calldata _walletAddresses,
        uint256[] calldata _feeBps
    ) external onlyGov {
        uint256 sum;
        for (uint256 i; i < _feeBps.length; ++i) {
            sum += _feeBps[i];
            s_isBeneficiary[_walletAddresses[i]] = true;
        }
        if (sum > 10000) revert SG__ValueTooLarge(sum);
        s_beneficiaries = Beneficiaries(_feeBps, _walletAddresses);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setSwapManager(address _swapManager) external onlyGov {
        s_swapManager = ISwapManager(_swapManager);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setOracleManager(address _oracleManager) external onlyGov {
        s_oracle = IOracleManager(_oracleManager);
    }

    /// @inheritdoc IERC1155StoreGeneric
    function setModerator(address _moderatorAddress) external onlyGov {
        if (_moderatorAddress == address(0)) revert SG__ZeroAddress();
        s_moderator = _moderatorAddress;
    }

    function setDonor(address _donor) external onlyGov {
        if (_donor == address(0)) revert SG__ZeroAddress();
        s_tokenDonor = _donor;
    }

    function getBeneficiaries() external view returns (IERC1155StoreGeneric.Beneficiaries memory) {
        return s_beneficiaries;
    }

    function getSaleInfo(uint256 _id) external view returns (IERC1155StoreGeneric.Sale memory) {
        return s_sales[_id];
    }

    function getOwnershipDiscounts(uint256 _saleId) public view returns(OwnershipDiscount[] memory) { 
        return s_ownershipDiscounts[_saleId];
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view override returns (bytes4) {
        require(from != address(0), "GENERIC STORE: Address Zero");
        require(operator == address(this), "GENERIC STORE: Invalid Operator");

        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external view override returns (bytes4) {
        require(from != address(0), "GENERIC STORE: Address Zero");
        require(operator == address(this), "GENERIC STORE: Invalid Operator");

        return
            bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}
