// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC4626.sol";
import "./ERC20.sol";
import "./FWBase.sol";

contract FWERC20 is ERC4626, FWBase {
    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol,
        address starknetCore,
        address l1Bridge,
        uint256 l2Bridge,
        uint256 l2FW
    )
        FWBase(starknetCore, l2FW, l2Bridge, l1Bridge)
        ERC4626(asset)
        ERC20(name, symbol)
        Pausable()
    {}

    /**
     * @dev Allows the contract admin to withdraw excess amount of ERC20 tokens from the contract.
     * @param erc20 The address of the ERC20 token to be withdrawn.
     */
    function harvestErc20(address erc20) external onlyRole(0) {
        if (erc20 == super.asset()) {
            IERC20(erc20).transfer(
                msg.sender,
                IERC20(erc20).balanceOf(address(this)) - _underlyingBalance
            );
        } else {
            IERC20(erc20).transfer(
                msg.sender,
                IERC20(erc20).balanceOf(address(this))
            );
        }
    }

    /**
     * @dev Allows the contract admin to withdraw excess amount of ETH from the contract.
     */
    function harvestEth() external onlyRole(0) {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Overrides the deposit function from ERC4626. Allows liquidity providers to deposit assets.
     * Increases the underlying balance by the deposited assets.
     * @param assets The amount of assets to be deposited.
     * @param receiver The receiver of the deposited shares.
     * @return shares The amount of shares received.
     */
    function deposit(
        uint256 assets,
        address receiver
    ) public override onlyRole(LP_ROLE) returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        _underlyingBalance += assets;
        return shares;
    }

    /**
     * @dev Overrides the mint function from ERC4626. Allows liquidity providers to mint shares.
     * Increases the underlying balance by the minted assets.
     * @param shares The amount of shares to be minted.
     * @param receiver The receiver of the minted shares.
     * @return assets The amount of assets minted.
     */
    function mint(
        uint256 shares,
        address receiver
    ) public override onlyRole(LP_ROLE) returns (uint256) {
        uint256 assets = super.mint(shares, receiver);
        _underlyingBalance += assets;
        return assets;
    }

    /**
     * @dev Overrides the withdraw function from ERC4626. Allows liquidity providers to withdraw assets.
     * Decreases the underlying balance by the withdrawn assets.
     * @param assets The amount of assets to be withdrawn.
     * @param receiver The receiver of the withdrawn assets.
     * @param owner The owner of the shares being withdrawn.
     * @return shares The amount of shares burned.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override onlyRole(LP_ROLE) returns (uint256) {
        _checkEnoughBalance(assets);
        uint256 shares = super.withdraw(assets, receiver, owner);
        _underlyingBalance -= assets;
        return shares;
    }

    /**
     * @dev Overrides the redeem function from ERC4626. Allows liquidity providers to redeem shares.
     * Decreases the underlying balance by the redeemed assets.
     * @param shares The amount of shares to be redeemed.
     * @param receiver The receiver of the redeemed assets.
     * @param owner The owner of the shares being redeemed.
     * @return assets The amount of assets redeemed.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override onlyRole(LP_ROLE) returns (uint256) {
        uint256 assets = super.redeem(shares, receiver, owner);
        _checkEnoughBalance(assets);
        _underlyingBalance -= assets;
        return assets;
    }

    /**
     * @dev Overrides the totalAssets function from ERC4626. Returns the total balance of underlying assets.
     * @return The sum of underlying balance and due amount.
     */
    function totalAssets() public view virtual override returns (uint256) {
        return uint256(int256(_underlyingBalance) + _dueAmount);
    }

    function _transfer_underlying(
        address payable user,
        uint256 amount
    ) internal override {
        IERC20(super.asset()).transfer(user, amount);
    }
}
