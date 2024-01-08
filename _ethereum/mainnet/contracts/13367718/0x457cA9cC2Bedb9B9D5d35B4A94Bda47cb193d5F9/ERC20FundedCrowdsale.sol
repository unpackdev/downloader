// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.5.5;

import "./Crowdsale.sol";
import "./AllowanceCrowdsale.sol";
import "./WhitelistCrowdsale.sol";

/**
 * @title ERC20FundedCrowdsale
 * @dev Crowdsale that raises funds in an ERC20 token (instead of Ether).
 * IMPORTANT: `fundsRaised` indicates the number of `fundingToken`s raised (not Ether)
 */
contract ERC20FundedCrowdsale is Crowdsale, AllowanceCrowdsale, WhitelistCrowdsale {
    IERC20 private _fundingToken; // ERC20 token funds will be raised in
    mapping(address => uint256) private _balances; // Tracking addresses and their purchases
    address[] private _balancesList;
    uint256 private _fundsRaised; // How many FundingTokens have been raised
    uint256 private _tokensAvailible; // How many Tokens are availible

//    event USDCReceived(address indexed purchaser, uint256 fundingAmount);
//    event TokensIssued(address indexed beneficiary, uint256 tokenAmount);

    constructor (
        uint256 rate, // rate = 20 // 20 ECHO for 1 USDC // (1 / 0.05)
        address payable wallet, // Address where funds are collected - Echo's Multisig
        IERC20 token, // <- Echo Token
        address tokenWallet, // <- Echo's Multisig
        IERC20 fundingToken // <- USDC Token
    )
        public
        Crowdsale(rate, wallet, token)
        AllowanceCrowdsale(tokenWallet)
        WhitelistCrowdsale()
    {
        require(address(fundingToken) != address(0), "Crowdsale: funding token is the zero address");

        _fundingToken = fundingToken;
    }

    function fundingToken() public view returns (IERC20) {
        return _fundingToken;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function getBalancesListCount() public view returns (uint256) {
        return _balancesList.length;
    }

    function getBalancesListIndex(uint256 index) public view returns (address) {
        return _balancesList[index];
    }

    function tokensAvailible() public view returns (uint256) {
        return _tokensAvailible;
    }

    /**
     * @dev Determines the value (in `fundingToken` (USDC)) included with a purchase.
     */
    function _fundingAmount(uint256 fundingTokenAmount) internal returns (uint256) {
//        emit SetFundingAmount(_msgSender(), fundingTokenAmount);
        return fundingTokenAmount;
    }

    /**
     * @dev Forwards `fundingToken`s to `wallet`.
     */
    function _forwardFunds(uint256 fundingTokenAmount) internal {
        fundingToken().safeTransferFrom(msg.sender, wallet(), _fundingAmount(fundingTokenAmount));
//        emit USDCReceived(msg.sender, _fundingAmount(fundingTokenAmount));
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        require(remainingTokens() - tokenAmount > 0, "Crowdsale: Not enough tokens remaining");

        _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
        _balancesList.push(beneficiary);
        _tokensAvailible = remainingTokens() - tokenAmount;
//        emit TokensIssued(beneficiary, tokenAmount);
    }

    function _preValidatePurchase(address beneficiary, uint256 fundingAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(fundingAmount > 4999000000, "Crowdsale: minimum investment is 5000 USDC"); // USDC uses 6 decimal places
        require(isWhitelisted(beneficiary), "WhitelistCrowdsale: beneficiary doesn't have the Whitelisted role");
        super._preValidatePurchase(beneficiary, fundingAmount);
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }
}

