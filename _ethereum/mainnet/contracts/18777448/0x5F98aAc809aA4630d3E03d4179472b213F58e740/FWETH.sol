// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC4626ETH.sol";
import "./ERC20.sol";
import "./FWBase.sol";

/**
 * @title FWETH
 * @dev A contract that makes faster the transfer of assets between Starknet and ETH.
 */
contract FWETH is ERC4626ETH, FWBase {
    constructor(
        string memory name,
        string memory symbol,
        address starknetCore,
        address l1Bridge,
        uint256 l2Bridge,
        uint256 l2FW
    )
        FWBase(starknetCore, l2FW, l2Bridge, l1Bridge)
        ERC20(name, symbol)
        Pausable()
    {}

    /**
     * @dev Allows the contract owner to withdraw excess amount of ERC20 tokens from the contract.
     * @param erc20 The address of the ERC20 token to be withdrawn.
     */
    function harvestErc20(address erc20) external onlyRole(0) {
        IERC20(erc20).transfer(
            msg.sender,
            IERC20(erc20).balanceOf(address(this))
        );
    }

    /**
     * @dev Allows the contract owner to withdraw excess amount of ETH from the contract.
     */
    function harvestEth() external onlyRole(0) {
        payable(msg.sender).transfer(
            address(this).balance - _underlyingBalance
        );
    }

    function deposit(
        address receiver
    ) public payable override onlyRole(LP_ROLE) returns (uint256) {
        uint256 shares = super.deposit(receiver);
        _underlyingBalance += msg.value;
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
        address payable receiver,
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
        user.transfer(amount);
    }
}
