// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./Crowdsale.sol";
import "./SafeMath.sol";
import "./WhitelistAdminRole.sol";

/**
 * Referrals consist of two parts:
 *
 * 1) When user -- referral -- is using someone's -- referrer's -- code,
 *  he receives a bonus of _percent on top of the purchased amounts.
 *  For example, buying 5000 tokens, will result in 500 bonus tokens, if they were bought using a referral code.
 *
 * 2) Referrer has a separate percent which also equals _percent at the start.
 *  When referrer earns more than increaseThreshold (e.g. 20ETH) from referrals, the percent increases.
 *  So, for example, when someone buys 5000 tokens using the referrer code:
 *      - referrer receives 10% of ETH value bonus converted to tokens: 5000 * 10% = 500
 *      - when reached 20ETH earnings, referrer receives 20% of ETH value: 5000 * 20% = 1000
 *
 * When all referral funds (_cap) are spent, further purchases won't earn bonuses for anyone.
 */
contract ReferralsCrowdsale is Crowdsale, WhitelistAdminRole {
    using SafeMath for uint256;

    // How much the referrer and referred receive.
    uint private _percent = 10;
    uint private _increasedPercent = 20;
    // After 20ETH referrer bonus increases
    uint256 private _increaseThreshold = 20 ether;
    uint256 private _cap;
    uint256 private _totalEarned;

    bool public referralsEnabled = true;

    struct Referral {
        address addr; // Who used the referral
        address referrer;
        uint256 earned; // How much tokens earned
        bool isActive;
    }

    struct Referrer {
        address addr; // The referral address, used by others to associate with it
        // How much % a referrer gets from referrals purchases. Referrals always get _percent
        uint percent;
        uint256 earnedTokens; // Total tokens earned
        uint256 earnedEth; // accumulated 10% from all referral purchases
        uint num; // Total referrals
        address[] addresses; // Keys for the map
        mapping(address => ReferrerRef) earnings; // Referral -> earned
    }

    struct ReferrerRef {
        address addr;
        uint256 earned;
        uint256 earnedEth;
        uint timestamp;
    }

    // States of people whose codes were used
    mapping(address => Referrer) private _referrers;
    // States of people who used someone's referral
    mapping(address => Referral) private _referrals;

    event ReferralEarned(address indexed beneficiary, address indexed from, uint256 amount);
    event ReferralActive(address indexed beneficiary, bool isActive);
    event NotEnoughReferralFunds(uint256 tried, uint256 remaining);

    function refTokensRemaining() public view returns (uint256) {
        return _cap.sub(_totalEarned);
    }

    function setReferrerPercent(address referrer, uint percent) public onlyWhitelistAdmin {
        require(percent > 0, "ReferralsCrowdsale: percent is zero");
        _referrers[referrer].percent = percent;
    }

    function setReferralsCap(uint256 cap) public onlyWhitelistAdmin {
        require(cap > 0, "ReferralsCrowdsale: cap is zero");
        require(cap > _totalEarned, "ReferralsCrowdsale: cap is less than already earned");
        _cap = cap;
    }

    function enableReferrals() public onlyWhitelistAdmin {
        referralsEnabled = true;
    }

    function disableReferrals() public onlyWhitelistAdmin {
        referralsEnabled = false;
    }

    /**
     * Referral stats: how much this used earned from using someones referral code.
     */
    function getReferralStats(address addr) public view returns (address, bool, address, uint, uint256) {
        Referral storage ref = _referrals[addr];
        uint percent = ref.isActive ? _percent : 0;

        return (ref.addr, ref.isActive, ref.referrer, percent, ref.earned);
    }

    /**
     * When buying tokens with a specified referral address, associate the buying user with it.
     * Update/init the referrer (whose code was used) stats.
     */
    function buyTokensWithReferral(address beneficiary, address referral) public payable {
        require(referralsEnabled == true, "ReferralsCrowdsale: referrals are disabled");
        require(_cap > 0, "ReferralsCrowdsale: cap is not set");
        require(referral != address(0), "ReferralsCrowdsale: referral is the zero address");
        require(referral != msg.sender, "ReferralsCrowdsale: referral can't be the sender address");

        // Activate a referral or switch the referrer address.
        Referral storage userReferral = _referrals[msg.sender];
        if (!userReferral.isActive || referral != userReferral.referrer) {
            userReferral.addr = msg.sender;
            userReferral.referrer = referral;
            userReferral.isActive = true;

            emit ReferralActive(msg.sender, userReferral.isActive);
        }

        buyTokens(beneficiary);
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        super._updatePurchasingState(beneficiary, weiAmount);

        if (!referralsEnabled) {
            return;
        }

        // User must have an active associated referral.
        Referral storage currentReferral = _referrals[msg.sender];
        if (!currentReferral.isActive) {
            return;
        }

        Referrer storage referrer = _referrers[currentReferral.referrer];
        referrer.percent = referrer.percent > 0 ? referrer.percent : _percent;

        uint256 amount = _getTokenAmount(weiAmount);
        uint256 referralBonus = amount.mul(_percent).div(100);

        uint256 referrerBonusEth = weiAmount.mul(referrer.percent).div(100);
        uint256 referrerBonus = _getTokenAmount(referrerBonusEth);

        uint256 totalBonus = referralBonus.add(referrerBonus);

        // If there's not enough referral funds remaining, proceed without giving referrals
        if (totalBonus > _cap.sub(_totalEarned)) {
            emit NotEnoughReferralFunds(totalBonus, _cap.sub(_totalEarned));
            return;
        }
        _totalEarned = _totalEarned.add(totalBonus);

        // Update referral stats
        currentReferral.earned = currentReferral.earned.add(referralBonus);

        // If current user wasn't previously added in the list of referrer's earnings, count it in
        if (referrer.earnings[msg.sender].addr == address(0)) {
            referrer.addr = currentReferral.referrer;
            referrer.addresses.push(msg.sender);
            referrer.num += 1;
        }

        // Update referrer stats and increase the bonus if user earned more than threshold (e.g. > 20ETH) from referrals
        referrer.earnedTokens = referrer.earnedTokens.add(referrerBonus);
        referrer.earnedEth = referrer.earnedEth.add(referrerBonusEth);
        if (referrer.earnedEth > _increaseThreshold) {
            referrer.percent = _increasedPercent;
        }
        _referrers[currentReferral.referrer] = referrer;

        // Track the specific referral, so referrer knows how much earned per referral
        ReferrerRef storage referrerRef = referrer.earnings[msg.sender];
        referrerRef.addr = msg.sender;
        referrerRef.earned = referrerRef.earned.add(referrerBonus);
        referrerRef.earnedEth = referrerRef.earnedEth.add(referrerBonusEth);
        referrerRef.timestamp = block.timestamp;
        _referrers[currentReferral.referrer].earnings[msg.sender] = referrerRef;

        // Transfer bonus tokens
        _processPurchase(msg.sender, referralBonus);
        emit ReferralEarned(msg.sender, currentReferral.referrer, referralBonus);

        _processPurchase(referrer.addr, referrerBonus);
        emit ReferralEarned(referrer.addr, msg.sender, referrerBonus);
    }

    /**
     * Referrer stats: stats for people who used the code.
     */
    function getReferrerStats(address referrer) public view
    returns (
        uint,
        uint,
        uint256,
        uint256,
        uint[] memory,
        address[] memory,
        uint256[] memory,
        uint256[] memory
    ) {
        Referrer storage state = _referrers[referrer];
        uint percent = state.percent > 0 ? state.percent : _percent;

        address[] memory addrs = new address[](state.num);
        uint256[] memory earnedTokens = new uint256[](state.num);
        uint256[] memory earnedEth = new uint256[](state.num);
        uint[] memory timestamps = new uint[](state.num);

        for (uint i = 0; i < state.num; i++) {
            address refAddr = state.addresses[i];
            ReferrerRef storage ref = state.earnings[refAddr];
            addrs[i] = ref.addr;
            earnedTokens[i] = ref.earned;
            earnedEth[i] = ref.earnedEth;
            timestamps[i] = ref.timestamp;
        }

        return (state.num, percent, state.earnedTokens, state.earnedEth, timestamps, addrs, earnedTokens, earnedEth);
    }
}
