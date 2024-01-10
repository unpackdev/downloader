// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./NfpsToken.sol";
import "./PriceFeed.sol";

/// @title NFP Limit Sale
/// @author NFP Swap
/// @notice Contract for limited sale of NFPS tokens
contract NfpsTrader is Ownable, ReentrancyGuard, PriceFeed {
    using SafeMath for uint256;

    NfpsToken private _nfpsToken;

    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

    constructor(address nfpsTokenAddress) {
        _nfpsToken = NfpsToken(nfpsTokenAddress);
    }

    /// @notice Allow account to purchase NFPS tokens for ETH, which is paid to contract owner
    function buy() public payable nonReentrant {
        require(msg.value > 0, "Send ETH to buy some tokens");

        int nfpPerWei = getExchangeRatePerWei();
        uint256 amountToBuy = msg.value.mul(uint256(nfpPerWei));

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = _nfpsToken.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        payable(owner()).transfer(msg.value);
        // Transfer token to the msg.sender
        bool sent = _nfpsToken.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    /// @notice Get the current balance of NFPS tokens in the contract
    function getBalance() public view returns (uint256) {
        return _nfpsToken.balanceOf(address(this));
    }

    /// @notice Get current exchange rate of NFPS/ETH
    function getExchangeRatePerWei() public view returns (int) {
        int price = getLatestPrice();
        int pricePerNfp = 10**6;
        int nfpsPerEth = price / pricePerNfp;
        return nfpsPerEth;
    }
}
