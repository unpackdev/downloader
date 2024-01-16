// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Roles.sol";
import "./TokenSaleProxy.sol";

interface IERC20Upgraded {
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;


    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
} 

abstract contract ExchangerRoles is Ownable, AdminRole {
    /**
        @notice add Admin role to `user`
        @dev only for Owner
        @param user role recipient
     */
    function addAdmin(address user) external onlyOwner {
        _addAdmin(user);
    }

    /**
        @notice remove Admin role from `user`
        @dev only for Owner
        @param user address for role revocation
     */
    function removeAdmin(address user) external onlyOwner {
        _removeAdmin(user);
    }
}

abstract contract Blacklist is AdminRole {
    mapping (address => bool) public isBlacklisted;

    modifier notBlacklisted(address account) {
        require(!isBlacklisted[account], "Blacklist: account is blacklisted");
        _;
    }

    /**
        @notice add to blacklist `user`
        @dev only for Admin
        @param user user address
     */
    function addToBlacklist(address user) external onlyAdmin {
        isBlacklisted[user] = true;
    }

    /**
        @notice remove `user` from blacklist
        @dev only for Admin
        @param user user address
     */
    function removeFromBlacklist(address user) external onlyAdmin {
        isBlacklisted[user] = false;
    }
}

contract Exchanger is ExchangerRoles, Blacklist {
    /** @notice address of vesting contract. May be ERC20 token */
    address public vestingProxy;
    /** @notice address of bought tokens collector */
    address public beneficiary;
    uint256 rewardedDecimals;

    uint ratePur = 0.00357142857142816 * 1e18;
    uint rateSel = 1e18;
    
    /** @notice return true if token is purchased */
    mapping (address => bool) public purchasedToken;

    constructor (
        address[] memory purchasedTokens_,
        address vestingProxy_,
        address beneficiary_,
        uint256 rewardedDecimals_
    ) {
        require(vestingProxy_ != address(0), "zero vesting proxy token address");
        require(beneficiary_ != address(0), "zero beneficiary address");
        for (uint i = 0 ; i < purchasedTokens_.length; i++) {
            updatePurchasedToken(purchasedTokens_[i], true);
        }
        vestingProxy = vestingProxy_;
        beneficiary = beneficiary_;
        rewardedDecimals = rewardedDecimals_;
    }

    /**
        @notice take approved `token_` and transfer selled tokens
            Requirements:
            - `token_` should be puchased
            - `fromAmount` and reward more 0
        @dev `to` has to be not blacklisted
        @param token_ token address for which we gonna buy
        @param to recipient of reward
        @param fromAmount amount of purchased token
     */
    function buy(address token_, address to, uint256 fromAmount) external onlyAdmin notBlacklisted(to) {
        require(purchasedToken[token_] == true, "(buy) the token is not purchased");
        require(
            fromAmount > 0,
            "(buy) less than minimal buying limit"
        );
        uint256 selAmount = getRateFromUSDT(token_, fromAmount);
        require(selAmount > 0, "(buy) zero reward");

        IERC20Upgraded(token_).transferFrom(msg.sender, beneficiary, fromAmount);

        address rewardedToken = address(TokenSaleProxy(vestingProxy).token());
        IERC20Upgraded(rewardedToken).transfer(vestingProxy, selAmount);
        TokenSaleProxy(vestingProxy).registerParticipant(to, selAmount);
    }

    /**
        @notice update exchanging rate
        @dev only for Owner
        @param _ratePur how much the contract'll take for `_rateSel`
        @param _rateSel how much user'll get for `_ratePur`
     */
    function updateRate(uint _ratePur, uint _rateSel) external onlyOwner {
        ratePur = _ratePur;
        rateSel = _rateSel;
    }

    /**
        @notice update vesting proxy contract. May be ERC20 token
        @dev only for Owner
        @param proxy contract address for awarding
     */
    function updateProxy(address proxy) external onlyOwner {
        require(proxy != address(0), "zero address of the token");
        vestingProxy = proxy;
    }
    
    /**
        @notice update beneficiary
        @dev only for Owner
        @param _beneficiary new beneficiary
     */
    function updateBeneficiary(address _beneficiary) external onlyOwner {
        beneficiary = _beneficiary;
    }

    /**
        @notice transfer `amount` of `token` from the contract to its owner
        @dev only for Owner
        @param token token for withdrawing
        @param amount withdrawing amount
     */
    function withdrawERC20(address token, uint amount) external onlyOwner {
        require(IERC20Upgraded(token).balanceOf(address(this)) >= amount, "insufficient balance");
        IERC20Upgraded(token).transfer(msg.sender, amount);
    }

    /**
        @notice update info about purchased token
        @dev only for Owner
        @param purchasedToken_ PurchasedToken struct
     */
    function updatePurchasedToken(address purchasedToken_, bool status) public onlyOwner {
        require(purchasedToken_ != address(0), "(addPurchasedToken) zero purchased token address");
        purchasedToken[purchasedToken_] = status;
    }

    // View functions

    /**
        @param token_ ERC20 token address
        @param usdtAmount amount of purchased token
        @return reward which user'll get for `usdtAmount` by actual exchanging rate
     */
    function getRateFromUSDT(address token_, uint usdtAmount) public view returns(uint) {
        uint256 purDecimalsCorrection = 10**ERC20(token_).decimals();
        uint256 selDecimalsCorrection = 10**rewardedDecimals;

        uint _sellingAmount = usdtAmount * selDecimalsCorrection / ratePur * rateSel / purDecimalsCorrection;
        return _sellingAmount;
    }
}