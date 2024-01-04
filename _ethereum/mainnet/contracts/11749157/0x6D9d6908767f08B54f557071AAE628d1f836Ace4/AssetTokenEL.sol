// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./SafeMath.sol";
import "./EController.sol";
import "./IAssetToken.sol";
import "./AssetTokenBase.sol";

contract AssetTokenEL is IAssetTokenERC20, AssetTokenBase {
    using SafeMath for uint256;
    using AssetTokenLibrary for ExchangeLocalVars;

    IERC20 private _el;

    /// @notice Emitted when an user claimed reward
    event RewardClaimed(address account, uint256 reward);

    constructor(
        IERC20 el_,
        IEController eController_,
        uint256 amount_,
        uint256 price_,
        uint256 rewardPerBlock_,
        uint256 payment_,
        uint256 latitude_,
        uint256 longitude_,
        uint256 assetPrice_,
        uint256 interestRate_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    )
        AssetTokenBase(
            eController_,
            amount_,
            price_,
            rewardPerBlock_,
            payment_,
            latitude_,
            longitude_,
            assetPrice_,
            interestRate_,
            name_,
            symbol_,
            decimals_
        )
    {
        _el = el_;
    }

    /**
     * @dev purchase asset token with el.
     *
     * This can be used to purchase asset token with Elysia Token (EL).
     *
     * Requirements:
     * - `amount` this contract should have more asset tokens than the amount.
     * - `amount` msg.sender should have more el than elAmount converted from the amount.
     */
    function purchase(uint256 amount)
        external
        override
        whenNotPaused
    {
        _checkBalance(msg.sender, address(this), amount);

        ExchangeLocalVars memory vars =
            ExchangeLocalVars({
                currencyPrice: eController.getPrice(payment),
                assetTokenPrice: price
            });

        require(
            _el.transferFrom(
                msg.sender,
                address(this),
                amount.mul(vars.mulPrice())
            ),
            "EL : transferFrom failed"
        );
        _transfer(address(this), msg.sender, amount);
    }

    /**
     * @dev refund asset token.
     *
     * This can be used to refund asset token with Elysia Token (EL).
     *
     * Requirements:
     * - `amount` msg.sender should have more asset token than the amount.
     * - `amount` this contract should have more el than elAmount converted from the amount.
     */
    function refund(uint256 amount)
        external
        override
        whenNotPaused
    {
        _checkBalance(address(this), msg.sender, amount);

        ExchangeLocalVars memory vars =
            ExchangeLocalVars({
                currencyPrice: eController.getPrice(payment),
                assetTokenPrice: price
            });

        require(
            _el.transfer(msg.sender, amount.mul(vars.mulPrice())),
            "EL : transfer failed"
        );
        _transfer(msg.sender, address(this), amount);
    }

    /**
     * @dev Claim account reward.
     *
     * This can be used to claim account accumulated rewrard with Elysia Token (EL).
     *
     * Emits a {RewardClaimed} event.
     *
     * Requirements:
     * - `elPrice` cannot be the zero.
     */
    function claimReward()
        external
        override
        whenNotPaused
        onlyWhitelisted(msg.sender)
    {
        uint256 reward =
            getReward(msg.sender).mul(1e18).div(eController.getPrice(payment));

        require(
            reward < _el.balanceOf(address(this)),
            "AssetToken: Insufficient seller balance."
        );
        _el.transfer(msg.sender, reward);
        _clearReward(msg.sender);

        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @dev check if buyer and seller have sufficient balance.
     *
     * This can be used to check balance of buyer and seller before swap.
     *
     * Requirements:
     * - `amount` buyer should have more asset token than the amount.
     * - `amount` seller should have more el than elAmount converted from the amount.
     */
    function _checkBalance(
        address buyer,
        address seller,
        uint256 amount
    ) internal view {

        ExchangeLocalVars memory vars =
            ExchangeLocalVars({
                currencyPrice: eController.getPrice(payment),
                assetTokenPrice: price
            });

        require(
            _el.balanceOf(buyer) >= amount.mul(vars.mulPrice()),
            "AssetToken: Insufficient buyer el balance."
        );
        require(
            balanceOf(seller) >= amount,
            "AssetToken: Insufficient seller balance."
        );
    }

    /**
     * @dev Withdraw all El from this contract to admin
     */
    function withdrawToAdmin() public onlyAdmin(msg.sender) {
        _el.transfer(msg.sender, _el.balanceOf(address(this)));
    }
}
