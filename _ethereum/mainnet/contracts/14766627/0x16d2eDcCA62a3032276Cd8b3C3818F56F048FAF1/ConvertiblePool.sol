// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./AdminControl.sol";
import "./Constants.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC20TransferHelper.sol";
import "./VNFTTransferHelper.sol";
import "./IUnderlyingContainer.sol";
import "./ERC20Upgradeable.sol";
import "./IConvertiblePool.sol";
import "./IPriceOracleManager.sol";
import "./IICToken.sol";
import "./console.sol";

contract ConvertiblePool is
    IConvertiblePool,
    AdminControl,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    mapping(uint256 => SlotDetail) internal _slotDetails;

    mapping(address => EnumerableSetUpgradeable.UintSet) internal _issuerSlots;

    mapping(address => bool) public fundCurrencies;

    /// @notice slot => currency => balance
    mapping(uint256 => mapping(address => uint256)) public slotBalances;

    IPriceOracleManager public oracle;
    address public underlyingVestingVoucher;
    address public underlyingToken;

    uint8 public priceDecimals;
    uint8 public valueDecimals;

    address public voucher;

    modifier onlyVoucher() {
        require(_msgSender() == voucher, "only voucher");
        _;
    }

    function initialize(
        address underlyingToken_,
        address oracle_,
        uint8 priceDecimals_,
        uint8 valueDecimals_
    ) external initializer {
        AdminControl.__AdminControl_init(_msgSender());
        oracle = IPriceOracleManager(oracle_);
        underlyingToken = underlyingToken_;
        priceDecimals = priceDecimals_;
        valueDecimals = valueDecimals_;
    }

    function createSlot(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint8 collateralType_
    ) external onlyVoucher returns (uint256 slot) {
        validateSlotParams(
            issuer_,
            fundCurrency_,
            lowestPrice_,
            highestPrice_,
            effectiveTime_,
            maturity_,
            collateralType_
        );

        slot = getSlot(
            issuer_,
            fundCurrency_,
            lowestPrice_,
            highestPrice_,
            effectiveTime_,
            maturity_,
            collateralType_
        );
        require(!_slotDetails[slot].isValid, "slot already existed");

        SlotDetail storage slotDetail = _slotDetails[slot];
        slotDetail.issuer = issuer_;
        slotDetail.fundCurrency = fundCurrency_;
        slotDetail.lowestPrice = lowestPrice_;
        slotDetail.highestPrice = highestPrice_;
        slotDetail.effectiveTime = effectiveTime_;
        slotDetail.maturity = maturity_;
        slotDetail.collateralType = CollateralType(collateralType_);
        slotDetail.isValid = true;

        _issuerSlots[issuer_].add(slot);

        emit CreateSlot(
            slot,
            issuer_,
            fundCurrency_,
            lowestPrice_,
            highestPrice_,
            effectiveTime_,
            maturity_,
            CollateralType(collateralType_)
        );
    }

    function validateSlotParams(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint8 collateralType_
    ) public view {
        require(issuer_ != address(0), "issuer cannot be 0 address");
        require(fundCurrencies[fundCurrency_], "unsupported fund currency");
        require(collateralType_ < 2, "invalid collateral type");
        require(
            lowestPrice_ > 0 && lowestPrice_ < highestPrice_,
            "invalid price bounds"
        );
        require(
            effectiveTime_ > 0 && effectiveTime_ < maturity_, 
            "invalid time setting"
        );
    }

    function mintWithUnderlyingToken(
        address minter_,
        uint256 slot_,
        uint256 tokenInAmount_
    ) external override nonReentrant onlyVoucher returns (uint256 totalValue) {
        require(minter_ != address(0), "minter cannot be 0 address");
        require(tokenInAmount_ != 0, "tokenInAmount cannot be 0");
        SlotDetail storage slotDetail = _slotDetails[slot_];
        require(slotDetail.isValid, "invalid slot");
        require(
            !slotDetail.isIssuerRefunded && block.timestamp < slotDetail.maturity, 
            "non-mintable slot"
        );

        totalValue = tokenInAmount_.mul(slotDetail.lowestPrice);
        slotDetail.totalValue = slotDetail.totalValue.add(totalValue);
        slotBalances[slot_][underlyingToken] = slotBalances[slot_][
            underlyingToken
        ].add(tokenInAmount_);
        ERC20TransferHelper.doTransferIn(
            underlyingToken,
            minter_,
            tokenInAmount_
        );

        emit Mint(minter_, slot_, totalValue);
    }

    /**
     * @dev Allow issuers to refund convertible vouchers with fund currency. 
     * Refunding is only allowed before the first holder claiming. Once refunded,
     * holders will claim in terms of 
     */
    function refund(uint256 slot_) external override nonReentrant {
        require(_issuerSlots[_msgSender()].contains(slot_), "only issuer");

        SlotDetail storage slotDetail = _slotDetails[slot_];
        require(slotDetail.isValid, "invalid slot");
        require(!slotDetail.isIssuerRefunded, "already refunded");
        require(slotDetail.settlePrice == 0, "already settled");

        slotDetail.isIssuerRefunded = true;

        // Calculation of currencyAmount only supports ERC20 stable coins (USDT/USDC/DAI/...)
        uint8 currencyDecimals = ERC20Upgradeable(slotDetail.fundCurrency)
            .decimals();
        uint256 currencyAmount = slotDetail
            .totalValue
            .mul(10**currencyDecimals)
            .div(10**valueDecimals);
        slotBalances[slot_][slotDetail.fundCurrency] = slotBalances[slot_][
            slotDetail.fundCurrency
        ].add(currencyAmount);
        ERC20TransferHelper.doTransferIn(
            slotDetail.fundCurrency,
            _msgSender(),
            currencyAmount
        );

        emit Refund(slot_, _msgSender(), currencyAmount);
    }

    function getWithdrawableAmount(uint256 slot_)
        public
        view
        returns (uint256 withdrawCurrencyAmount, uint256 withdrawTokenAmount)
    {
        SlotDetail storage slotDetail = _slotDetails[slot_];

        if (
            block.timestamp >= slotDetail.maturity &&
            !slotDetail.isIssuerWithdrawn
        ) {
            uint128 settlePrice = slotDetail.settlePrice;

            if (settlePrice == 0) {
                settlePrice = getSettlePrice(slot_);
                if (settlePrice == 0) {
                    return (0, 0);
                }
            }

            if (slotDetail.isIssuerRefunded && settlePrice > slotDetail.highestPrice) {
                // Calculation of currencyAmount only supports ERC20 stable coins (USDT/USDC/DAI/...)
                uint8 currencyDecimals = ERC20Upgradeable(
                    slotDetail.fundCurrency
                ).decimals();
                uint256 reservedCurrencyAmount = slotBalances[slot_][
                    slotDetail.fundCurrency
                ];
                withdrawCurrencyAmount = slotDetail
                    .totalValue
                    .mul(10**currencyDecimals)
                    .div(10**valueDecimals);
                if (withdrawCurrencyAmount > reservedCurrencyAmount) {
                    withdrawCurrencyAmount = reservedCurrencyAmount;
                }
            }

            if (slotDetail.isIssuerRefunded && settlePrice <= slotDetail.highestPrice) {
                withdrawTokenAmount = slotDetail.totalValue.div(slotDetail.lowestPrice);
            } else if (settlePrice > slotDetail.lowestPrice) {
                if (settlePrice > slotDetail.highestPrice) {
                    settlePrice = slotDetail.highestPrice;
                }
                withdrawTokenAmount = slotDetail
                    .totalValue
                    .div(slotDetail.lowestPrice)
                    .sub(slotDetail.totalValue.div(settlePrice));
            }
            uint256 reservedTokenAmount = slotBalances[slot_][underlyingToken];
            if (withdrawTokenAmount > reservedTokenAmount) {
                withdrawTokenAmount = reservedTokenAmount;
            }
        }
    }

    /**
     * @notice Allow issuers to withdraw fund currency (if refunded) and remaining underlying token after maturity.
     */
    function withdraw(uint256 slot_)
        external
        override
        nonReentrant
        returns (uint256 withdrawCurrencyAmount, uint256 withdrawTokenAmount)
    {
        require(_issuerSlots[_msgSender()].contains(slot_), "only issuer");

        SlotDetail storage slotDetail = _slotDetails[slot_];
        require(!slotDetail.isIssuerWithdrawn, "already withdrawn");

        uint128 settlePrice = slotDetail.settlePrice;
        if (settlePrice == 0) {
            settleConvertiblePrice(slot_);
            settlePrice = slotDetail.settlePrice;
            if (settlePrice == 0) {
                revert("price not settled");
            }
        }

        (withdrawCurrencyAmount, withdrawTokenAmount) = getWithdrawableAmount(
            slot_
        );

        slotDetail.isIssuerWithdrawn = true;

        if (withdrawCurrencyAmount > 0) {
            slotBalances[slot_][slotDetail.fundCurrency] = slotBalances[slot_][
                slotDetail.fundCurrency
            ].sub(withdrawCurrencyAmount);
            ERC20TransferHelper.doTransferOut(
                slotDetail.fundCurrency,
                _msgSender(),
                withdrawCurrencyAmount
            );
        }
        if (withdrawTokenAmount > 0) {
            slotBalances[slot_][underlyingToken] = slotBalances[slot_][
                underlyingToken
            ].sub(withdrawTokenAmount);
            ERC20TransferHelper.doTransferOut(
                underlyingToken,
                _msgSender(),
                withdrawTokenAmount
            );
        }

        emit Withdraw(
            slot_,
            _msgSender(),
            withdrawCurrencyAmount,
            withdrawTokenAmount
        );
    }

    /**
     * @notice Allow CV holders to claim fund currency or underlying token after maturity.
     */
    function claim(
        uint256 slot_,
        address to_,
        uint256 claimValue_
    )
        external
        override
        onlyVoucher
        nonReentrant
        returns (uint256 claimCurrencyAmount, uint256 claimTokenAmount)
    {
        SlotDetail storage slotDetail = _slotDetails[slot_];
        require(slotDetail.isValid, "invalid slot");

        uint128 settlePrice = slotDetail.settlePrice;
        if (settlePrice == 0) {
            settleConvertiblePrice(slot_);
            settlePrice = slotDetail.settlePrice;
            if (settlePrice == 0) {
                revert("price not settled");
            }
        }

        if (!slotDetail.isClaimed) {
            slotDetail.isClaimed = true;
        }

        if (
            settlePrice <= slotDetail.highestPrice && slotDetail.isIssuerRefunded
        ) {
            uint256 reservedCurrencyAmount = slotBalances[slot_][
                slotDetail.fundCurrency
            ];
            claimCurrencyAmount = claimValue_
                .mul(10 ** ERC20Upgradeable(slotDetail.fundCurrency).decimals())
                .div(10 ** valueDecimals);

            if (claimCurrencyAmount > reservedCurrencyAmount) {
                claimCurrencyAmount = reservedCurrencyAmount;
            }
            slotBalances[slot_][
                slotDetail.fundCurrency
            ] = reservedCurrencyAmount.sub(claimCurrencyAmount);

            ERC20TransferHelper.doTransferOut(
                slotDetail.fundCurrency,
                payable(to_),
                claimCurrencyAmount
            );
        } else {
            if (settlePrice < slotDetail.lowestPrice) {
                settlePrice = slotDetail.lowestPrice;
            } else if (settlePrice > slotDetail.highestPrice) {
                settlePrice = slotDetail.highestPrice;
            }

            uint256 reservedTokenAmount = slotBalances[slot_][underlyingToken];
            claimTokenAmount = claimValue_.div(settlePrice);
            if (claimTokenAmount > reservedTokenAmount) {
                claimTokenAmount = reservedTokenAmount;
            }
            slotBalances[slot_][underlyingToken] = reservedTokenAmount.sub(
                claimTokenAmount
            );
            ERC20TransferHelper.doTransferOut(
                underlyingToken,
                payable(to_),
                claimTokenAmount
            );
        }
    }

    function settleConvertiblePrice(uint256 slot_) public override {
        SlotDetail storage slotDetail = _slotDetails[slot_];

        uint128 price = getSettlePrice(slot_);
        if (price > 0) {
            slotDetail.settlePrice = price;
            emit SettlePrice(slot_, slotDetail.settlePrice);
        }
    }

    function getSettlePrice(uint256 slot_)
        public
        view
        override
        returns (uint128)
    {
        SlotDetail storage slotDetail = _slotDetails[slot_];
        require(block.timestamp >= slotDetail.maturity, "premature");

        int256 iPrice = oracle.getPriceOfMaturity(
            voucher,
            slotDetail.maturity
        );
        if (iPrice < 0) {
            revert("negative price");
        }
        return uint128(iPrice);
    }

    function getSlot(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint8 collateralType_
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        underlyingToken,
                        underlyingVestingVoucher,
                        issuer_,
                        fundCurrency_,
                        lowestPrice_,
                        highestPrice_,
                        effectiveTime_,
                        maturity_,
                        collateralType_
                    )
                )
            );
    }

    function getSlotDetail(uint256 slot_)
        external
        view
        returns (SlotDetail memory)
    {
        return _slotDetails[slot_];
    }

    function getIssuerSlots(address issuer_)
        external
        view
        returns (uint256[] memory slots)
    {
        slots = new uint256[](_issuerSlots[issuer_].length());
        for (uint256 i = 0; i < slots.length; i++) {
            slots[i] = _issuerSlots[issuer_].at(i);
        }
    }

    function getIssuerSlotDetails(address issuer_)
        external
        view
        returns (SlotDetail[] memory slotDetails)
    {
        slotDetails = new SlotDetail[](_issuerSlots[issuer_].length());
        for (uint256 i = 0; i < slotDetails.length; i++) {
            slotDetails[i] = _slotDetails[_issuerSlots[issuer_].at(i)];
        }
    }

    function setUnderlyingVestingVoucher(address underlyingVestingVoucher_) 
        external 
        onlyAdmin 
    {
        underlyingVestingVoucher = underlyingVestingVoucher_;
    }

    function setFundCurrency(address fundCurrency_, bool enable_)
        external
        onlyAdmin
    {
        fundCurrencies[fundCurrency_] = enable_;
        emit SetFundCurrency(fundCurrency_, enable_);
    }

    function setVoucher(address newVoucher_) external onlyAdmin {
        require(newVoucher_ != address(0), "new voucher cannot be 0 address");
        emit NewVoucher(voucher, newVoucher_);
        voucher = newVoucher_;
    }
    
}
