// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./SafeMath.sol";
import "./EController.sol";
import "./IAssetToken.sol";
import "./AssetTokenBase.sol";

contract AssetTokenEth is IAssetTokenEth, AssetTokenBase {
    using SafeMath for uint256;
    using AssetTokenLibrary for SpentLocalVars;
    using AssetTokenLibrary for AmountLocalVars;

    /// @notice Emitted when an user claimed reward
    event RewardClaimed(address account, uint256 reward);

    constructor(
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
    {}

    /**
     * @dev purchase asset token with eth.
     *
     * This can be used to purchase asset token with ether.
     *
     * Requirements:
     * - `msg.value` msg.sender should have more eth than msg.value.
     */
    function purchase()
        external
        payable
        override
        whenNotPaused
    {
        require(
            msg.value > 0,
            "Not enough msg.value"
        );

        AmountLocalVars memory vars =
            AmountLocalVars({
                spent: msg.value,
                currencyPrice: eController.getPrice(payment),
                assetTokenPrice: price
            });

        uint256 amount = vars.getAmount();

        _checkBalance(address(this), amount);
        _transfer(address(this), msg.sender, amount);
    }

    /**
     * @dev refund asset token.
     *
     * This can be used to refund asset token with ether (Eth).
     *
     * Requirements:
     * - `amount` msg.sender should have more asset token than the amount.
     * - `amount` this contract should have more eth than ether converted from the amount.
     */
    function refund(uint256 amount)
        external
        override
        whenNotPaused
    {
        _checkBalance(msg.sender, amount);

        SpentLocalVars memory vars =
            SpentLocalVars({
                amount: amount,
                currencyPrice: eController.getPrice(payment),
                assetTokenPrice: price
            });

        uint256 spent = vars.getSpent();

        require(
            address(this).balance >= spent,
            "AssetToken: Insufficient buyer balance."
        );

        _transfer(msg.sender, address(this), amount);

        require(
            msg.sender.send(spent),
            "Eth : send failed"
        );
    }

    /**
     * @dev Claim account reward.
     *
     * This can be used to claim account accumulated rewrard with ether (Eth).
     *
     * Emits a {RewardClaimed} event.
     *
     * Requirements:
     * - `getPrice` cannot be the zero.
     */
    function claimReward()
        external
        override
        whenNotPaused
    {
        uint256 reward =
            getReward(msg.sender).mul(1e18).div(eController.getPrice(payment));

        require(
            reward <= address(this).balance,
            "AssetToken: Insufficient contract balance."
        );

        _clearReward(msg.sender);
        if (!payable(msg.sender).send(reward)) {
            _saveReward(msg.sender);
        }

        emit RewardClaimed(msg.sender, reward);
    }

    /**
     * @dev Withdraw all eth from this contract to admin
     */
    function withdrawToAdmin() public onlyAdmin(msg.sender) {
        require(payable(msg.sender).send(address(this).balance), "Admin withdraw failed");
    }

    /**
     * @dev check if buyer and seller have sufficient balance.
     *
     * This can be used to check balance of buyer and seller before swap.
     *
     * Requirements:
     * - `amount` buyer should have more asset token than the amount.
     */
    function _checkBalance(
        address seller,
        uint256 amount
    ) internal view {
        require(
            balanceOf(seller) >= amount,
            "AssetToken: Insufficient seller balance."
        );
    }

    /**
     * @dev allow asset token to receive eth from other accounts.
     * Monthly rent profit (eth) is acummulated in asset token from elysia admin account
     */
    receive() external payable {
    }
}
