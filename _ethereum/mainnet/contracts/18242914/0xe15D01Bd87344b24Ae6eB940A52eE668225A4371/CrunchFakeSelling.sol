// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";

import "./IERC677Receiver.sol";
import "./CrunchSelling.sol";

contract CrunchSeIIing is Ownable, IERC677Receiver {
    /** @dev Emitted when the delegate contract is changed. */
    event DelegateChanged(address indexed previousDelegate, address indexed newDelegate);

    /** @dev Emitted when `addr` sold $CRUNCHs for $USDCs. */
    event Sell(address indexed addr, uint256 inputAmount, uint256 outputAmount, uint256 price);

    CrunchSelling public delegate;
    bool private unused;

    constructor(address _delegate) {
        _setDelegate(_delegate);
    }

    /** @dev CRUNCH erc20 address. */
    function crunch() public view returns (IERC20Metadata) {
        return delegate.crunch();
    }

    /** @dev USDC erc20 address. */
    function usdc() public view returns (IERC20) {
        return delegate.usdc();
    }

    /** @dev How much USDC must be exchanged for 1 CRUNCH. */
    function price() public view returns (uint256) {
        return delegate.price();
    }

    /** @dev Cached value of 1 CRUNCH (1**18). */
    function oneCrunch() public view returns (uint256) {
        return delegate.oneCrunch();
    }

    /**
     * Sell `amount` CRUNCH to USDC.
     *
     * Emits a {Sell} event.
     *
     * Requirements:
     * - caller's CRUNCH allowance is greater or equal to `amount`.
     * - caller's CRUNCH balance is greater or equal to `amount`.
     * - caller is not the owner.
     * - `amount` is not zero.
     * - the reserve has enough USDC after conversion.
     *
     * @dev the implementation use a {IERC20-transferFrom(address, address, uint256)} call to transfer the CRUNCH from the caller to the owner.
     *
     * @param amount CRUNCH amount to sell.
     */
    function sell(uint256 amount) public {
        address seller = _msgSender();

        require(crunch().allowance(seller, address(this)) >= amount, "Selling: user's allowance is not enough");
        require(crunch().balanceOf(seller) >= amount, "Selling: user's balance is not enough");

        crunch().transferFrom(seller, owner(), amount);

        _sell(seller, amount);
    }

    /**
     * Sell `amount` CRUNCH to USDC from a `transferAndCall`, avoiding the usage of an `approve` call.
     *
     * Emits a {Sell} event.
     *
     * Requirements:
     * - caller must be the crunch token.
     * - `sender` is not the owner.
     * - `amount` is not zero.
     * - the reserve has enough USDC after conversion.
     *
     * @dev the implementation use a {IERC20-transfer(address, uint256)} call to transfer the received CRUNCH to the owner.
     */
    function onTokenTransfer(address sender, uint256 value, bytes memory data) external override {
        require(address(crunch()) == _msgSender(), "Selling: caller must be the crunch token");

        crunch().transfer(owner(), value);

        _sell(sender, value);

        data; /* silence unused */
    }

    /**
     * Internal selling function.
     *
     * Emits a {Sell} event.
     *
     * Requirements:
     * - `seller` is not the owner.
     * - `amount` is not zero.
     * - the reserve has enough USDC after conversion.
     *
     * @param seller seller address.
     * @param amount CRUNCH amount to sell.
     */
    function _sell(address seller, uint256 amount) internal {
        require(seller != owner(), "Selling: owner cannot sell");
        require(amount != 0, "Selling: cannot sell 0 unit");

        uint256 tokens = conversion(amount);
        require(tokens != 0, "Selling: selling will result in getting nothing");
        require(reserve() >= tokens, "Selling: reserve is not big enough");

        emit Sell(seller, amount, tokens, price());
    }

    /**
     * @dev convert a value in CRUNCH to USDC using the current price.
     *
     * @param inputAmount input value to convert.
     * @return outputAmount the converted amount.
     */
    function conversion(uint256 inputAmount) public view returns (uint256 outputAmount) {
        return delegate.conversion(inputAmount);
    }

    /** @return the USDC balance of the delegate contract. */
    function reserve() public view returns (uint256) {
        return delegate.reserve();
    }

    /** @return the USDC balance of the contract. */
    function selfReserve() public view returns (uint256) {
        return usdc().balanceOf(address(this));
    }

    /**
     * Empty the USDC reserve.
     *
     * Requirements:
     * - caller must be the owner.
     */
    function emptyReserve() public onlyOwner {
        bool success = _emptyReserve();

        /* prevent useless call */
        require(success, "Selling: reserve already empty");
    }

    /**
     * Empty the CRUNCH of the smart-contract.
     * Must never be called because there is no need to send CRUNCH to this contract.
     *
     * Requirements:
     * - caller must be the owner.
     */
    function returnCrunchs() public onlyOwner {
        bool success = _returnCrunchs();

        /* prevent useless call */
        require(success, "Selling: no crunch");
    }

    /**
     * Update the delegate contract address.
     *
     * Emits a {DelegateChanged} event.
     *
     * Requirements:
     * - caller must be the owner.
     *
     * @param newDelegate new delete address.
     */
    function setDelegate(address newDelegate) external onlyOwner {
        _setDelegate(newDelegate);
    }

    /**
     * Update the CRUNCH token address.
     *
     * Emits a {CrunchChanged} event.
     *
     * Requirements:
     * - caller must be the owner.
     *
     * @param newCrunch new CRUNCH address.
     */
    function setCrunch(address newCrunch) external onlyOwner {
        newCrunch; /* silence */
        unused = true;

        revert("Selling: use delegate");
    }

    /**
     * Update the USDC token address.
     *
     * Emits a {UsdcChanged} event.
     *
     * Requirements:
     * - caller must be the owner.
     *
     * @param newUsdc new USDC address.
     */
    function setUsdc(address newUsdc) external onlyOwner {
        newUsdc; /* silence */
        unused = true;

        revert("Selling: use delegate");
    }

    /**
     * Update the price.
     *
     * Emits a {PriceChanged} event.
     *
     * Requirements:
     * - caller must be the owner.
     *
     * @param newPrice new price value.
     */
    function setPrice(uint256 newPrice) external onlyOwner {
        newPrice; /* silence */
        unused = true;

        revert("Selling: use delegate");
    }

    /**
     * Destroy the contract.
     * This will send the tokens (CRUNCH and USDC) back to the owner.
     *
     * Requirements:
     * - caller must be the owner.
     */
    function destroy() external onlyOwner {
        _emptyReserve();
        _returnCrunchs();

        selfdestruct(payable(owner()));
    }

    /**
     * Update the delegate contract address.
     *
     * Emits a {DelegateChanged} event.
     *
     * @param newDelegate new delegate contract address.
     */
    function _setDelegate(address newDelegate) internal {
        address previous = address(delegate);

        delegate = CrunchSelling(newDelegate);

        emit DelegateChanged(previous, newDelegate);
    }

    /**
     * Empty the reserve.
     *
     * @return true if at least 1 USDC has been transfered, false otherwise.
     */
    function _emptyReserve() internal returns (bool) {
        uint256 amount = selfReserve();

        if (amount != 0) {
            usdc().transfer(owner(), amount);
            return true;
        }

        return false;
    }

    /**
     * Return the CRUNCHs.
     *
     * @return true if at least 1 CRUNCH has been transfered, false otherwise.
     */
    function _returnCrunchs() internal returns (bool) {
        uint256 amount = crunch().balanceOf(address(this));

        if (amount != 0) {
            crunch().transfer(owner(), amount);
            return true;
        }

        return false;
    }
}
