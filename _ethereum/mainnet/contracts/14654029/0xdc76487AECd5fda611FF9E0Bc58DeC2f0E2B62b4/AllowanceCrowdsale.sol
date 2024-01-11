// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Crowdsale.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Math.sol";

/**
 * @title AllowanceCrowdsale
 * @dev Extension of Crowdsale where tokens are held by a wallet, which approves an allowance to the crowdsale.
 *
 * Upgraded to support Solidity 0.8 and OZ 4.5
 */
abstract contract AllowanceCrowdsale is Crowdsale {
    using SafeERC20 for IERC20;

    address private _tokenWallet;

    /**
     * @dev Constructor, takes token wallet address.
     * @param tokenWallet_ Address holding the tokens, which has approved allowance to the crowdsale.
     */
    constructor (
        uint256 rate_,
        address payable wallet_,
        IERC20 token_,
        address tokenWallet_
    ) Crowdsale(rate_, wallet_, token_) {
        require(tokenWallet_ != address(0), "AllowanceCrowdsale: token wallet is the zero address");
        _tokenWallet = tokenWallet_;
    }

    /**
     * @return the address of the wallet that will hold the tokens.
     */
    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

    /**
     * @dev Checks the amount of tokens left in the allowance.
     * @return Amount of tokens left in the allowance
     */
    function remainingTokens() public view returns (uint256) {
        return Math.min(token().balanceOf(_tokenWallet), token().allowance(_tokenWallet, address(this)));
    }

    /**
     * @dev Overrides parent behavior by transferring tokens from wallet.
     * @param beneficiary Token purchaser
     * @param tokenAmount Amount of tokens purchased
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal override {
        token().safeTransferFrom(_tokenWallet, beneficiary, tokenAmount);
    }
}