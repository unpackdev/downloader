// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./Initializable.sol";
import "./IXNFTFactory.sol";
import "./IXNFTClone.sol";
import "./IXNFTLiquidityPool.sol";
import "./IERC20.sol";

//
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@(
//    (@@@@@@@@@@@@#,,,,,,,,,,,,,,,,,,,,,,,,.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%.
//    /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(.
//    Created for locksonic.io
//    support@locksonic.io

/// @title XNFT Liquidity Pool Contract
/// @author Wilson A.
/// @notice Used for claiming and redemption of liquidity
contract XNFTLiquidityPool is Initializable, IXNFTLiquidityPool {
    uint256 private redemption;
    uint256 private accountId;
    IXNFTFactory private xnftFactory;
    IXNFTClone private xnftClone;

    uint32 internal constant FEE_DENOMINATOR = 10_000;

    modifier onlyFactory() {
        require(msg.sender == address(xnftFactory), "only factory");
        _;
    }

    function initialize(
        address xnftCloneAddress,
        uint256 _accountId
    ) public initializer {
        accountId = _accountId;
        xnftClone = IXNFTClone(xnftCloneAddress);
        xnftFactory = IXNFTFactory(msg.sender);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // --- Redeem Functions --- //
    /**
     * @dev Redeems a token for the caller, transferring it to their address and paying the redemption fee.
     * @param tokenId The ID of the token to be redeemed.
     * @notice This function allows a user to redeem a token associated with their account, paying the redemption fee.
     * @dev Requirements:
     * - The caller must be the owner of the token.
     * - The caller must be an EOA.
     * - The account must have tokens available for redemption.
     * - The contract must not be paused.
     */
    function redeem(address requestor, uint256 tokenId) external onlyFactory {
        require(xnftFactory.mintCount(accountId) > redemption, "all redeemed");
        require(xnftClone.ownerOf(tokenId) == requestor, "not owner");
        uint256 redemptionPrice = redeemPrice();
        ++redemption;
        _unwrap();
        _redeem(requestor, tokenId, redemptionPrice);
    }

    /**
     * @dev Claims a token, transferring it to the caller's address and paying the required amount.
     * @param tokenId The ID of the token to be claimed.
     * @notice This function allows a user to claim a token associated with their account, paying the claim fee.
     * @dev Requirements:
     * - The token must be eligible for claiming (previously redeemed).
     * - The caller must be an EOA.
     * - The caller must send the correct amount of Ether for claiming.
     * - The contract must not be paused.
     */
    function claim(
        address requestor,
        uint256 tokenId
    ) external payable onlyFactory {
        require(redemption > 0, "all claimed");
        require(xnftClone.ownerOf(tokenId) == address(this), "not claimable");

        (, , , , uint256 mintPrice, address accountFeeAddress, ) = xnftFactory
            .accounts(accountId);

        uint256 redemptionPrice = _calcRedeemPrice(msg.value);
        uint256 royaltyFeeBps = xnftFactory.royaltyFeeBps();
        uint256 marketplaceSecondaryFeeBps = xnftFactory
            .marketplaceSecondaryFeeBps();

        uint256 expectedPrice = mintPrice;
        uint256 basePrice = mintPrice;
        if (redemptionPrice > 0) {
            expectedPrice = (redemptionPrice * FEE_DENOMINATOR) / 9000;
            basePrice = (expectedPrice * 9950) / FEE_DENOMINATOR;
        }
        require(msg.value >= basePrice, "insufficient amount for claim");
        uint256 royaltyFee = (expectedPrice * royaltyFeeBps) / FEE_DENOMINATOR;
        uint256 liquidityPool = (expectedPrice *
            (FEE_DENOMINATOR - marketplaceSecondaryFeeBps - royaltyFeeBps)) /
            FEE_DENOMINATOR;
        uint256 marketplaceFee = msg.value >= expectedPrice
            ? expectedPrice - royaltyFee - liquidityPool
            : msg.value - royaltyFee - liquidityPool;
        --redemption;
        _unwrap();
        _claim(requestor, tokenId);
        _sendFees(xnftFactory.marketplaceFeeAddress(), marketplaceFee);
        _sendFees(accountFeeAddress, royaltyFee);
        if (msg.value > expectedPrice)
            _sendFees(requestor, msg.value - expectedPrice);
    }

    function accountTvl() public view returns (uint256) {
        return
            address(this).balance +
            IERC20(xnftFactory.wethAddress()).balanceOf(address(this));
    }

    function _calcRedeemPrice(
        uint256 msgValue
    ) internal view returns (uint256) {
        if (xnftFactory.mintCount(accountId) == redemption) return 0;
        uint256 assetAmount = accountTvl() - msgValue;
        uint256 redemptionPrice = assetAmount /
            (xnftFactory.mintCount(accountId) - redemption);
        return redemptionPrice;
    }

    /**
     * @dev Calculates the redemption price for this pool.
     * @return uint256 The redemption price.
     * @notice This function calculates the redemption price for an account's tokens based on the available assets.
     * If all tokens have been redeemed, the redemption price is 0.
     */
    function redeemPrice() public view returns (uint256) {
        if (xnftFactory.mintCount(accountId) == redemption) return 0;
        uint256 assetAmount = accountTvl();
        uint256 redemptionPrice = assetAmount /
            (xnftFactory.mintCount(accountId) - redemption);
        return redemptionPrice;
    }

    // -- Internal Functions --//
    function _sendFees(address feeAddress, uint256 amount) internal {
        if (amount == 0) return;
        (bool success, ) = payable(feeAddress).call{value: amount}("");
        require(success, "fee transfer failed");
    }

    function _redeem(
        address user,
        uint256 tokenId,
        uint256 redemptionPrice
    ) internal {
        xnftClone.nftRedemption(user, tokenId);
        _sendFees(user, redemptionPrice);
    }

    function _claim(address user, uint256 tokenId) internal {
        xnftClone.transferFrom(address(this), user, tokenId);
    }

    function _unwrap() internal {
        IERC20 weth = IERC20(xnftFactory.wethAddress());
        weth.withdraw(weth.balanceOf(address(this)));
    }

    receive() external payable {}

    uint256[46] __gap;
}
