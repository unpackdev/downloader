// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

interface IConvertiblePool {

    enum CollateralType {
        ERC20,
        VESTING_VOUCHER
    }

    /**
     * @notice Params for Convertible Vouchers.
     * totalValue total issue value, decimals = price decimals + underlying token decimals
     * @param currency currency address of the fund
     * @param lowestPrice decimals fixed at 8
     * @param highestPrice decimals fixed at 8
     * @param settlePrice settlement price set after maturity, decimals fixed at 8
     * @param settings uint16 type settings representing 16 boolean settings
     *        bit0: isValid
     *        bit1: isRefunded (if refunded, CV holders will receive currency instead of token)
     *        bit2: isRedeemed
     *        bit3: isClaimed, identify if the CV has been claimed by any holder
     *        bit4 ~ bit15: reserved
     */
    struct SlotDetail {
        address issuer;
        address fundCurrency;
        uint256 totalValue;
        uint128 lowestPrice;
        uint128 highestPrice;
        uint128 settlePrice;
        uint64 effectiveTime;
        uint64 maturity;
        CollateralType collateralType;
        bool isIssuerRefunded;
        bool isIssuerWithdrawn;
        bool isClaimed;
        bool isValid;
    }

    /** ===== Begin of events emited by ConvertiblePool ===== */
    event NewVoucher(address oldVoucher, address newVoucher);

    event SetFundCurrency(address indexed currency, bool enabled);

    event CreateSlot(
        uint256 indexed slot,
        address indexed issuer,
        address fundCurrency,
        uint128 lowestPrice,
        uint128 highestPrice,
        uint64 effectiveTime,
        uint64 maturity,
        CollateralType collateralType
    );

    event Mint(
        address indexed minter,
        uint256 indexed slot,
        uint256 totalValue
    );

    event Refund(uint256 indexed slot, address sender, uint256 refundAmount);

    event Withdraw(
        uint256 indexed slot,
        address sender,
        uint256 redeemCurrencyAmount,
        uint256 redeemUnderlyingTokenAmount
    );

    event SettlePrice(uint256 indexed slot, uint128 settlePrice);

    /** ===== End of events emited by ConvertiblePool ===== */

    function mintWithUnderlyingToken(
        address minter_,
        uint256 slot_,
        uint256 tokenInAmount_
    ) external returns (uint256 totalValue);

    function refund(uint256 slot_) external;

    function withdraw(uint256 slot_) external returns (uint256, uint256);

    function claim(
        uint256 slot_,
        address to_,
        uint256 claimValue_
    ) external returns (uint256, uint256);

    function settleConvertiblePrice(uint256 slot_) external;

    function getSettlePrice(uint256 slot_) external view returns (uint128);
}
