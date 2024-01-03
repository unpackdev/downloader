// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";
import "./Ownable.sol";
import "./WhitelistCrowdsale.sol";
import "./WhitelistAdminRole.sol";

contract RoundsCrowdsale is Crowdsale, WhitelistAdminRole, TimedCrowdsale, WhitelistCrowdsale {
    using SafeMath for uint256;

    struct Round {
        bool isOpen;
        uint n;
        uint256 rate;
        uint bonusPercent;
        uint contributors;
        uint256 raised;
        uint256 tokensLeft;
    }

    uint256 public contributionCap = 20 ether;
    uint public currentRound;

    // Min amount to buy with 550 rate per min 0.1ETH = 55 tokens, + bonus of 10%.
    uint256 constant _roundTokensLeftThreshold = 80 ether;

    uint private _roundsCount;
    mapping(uint => Round) private _rounds;
    // User -> [round -> value]
    mapping(address => mapping(uint => uint256)) private _contributions;

    event RoundOpened(uint n);
    event RoundBonusEarned(address beneficiary, uint256 amount);

    constructor(uint roundsCount, uint256 cap, uint256 initRate, uint256 rateDecrement) public {
        require(roundsCount > 0, "RoundsCrowdsale: roundsCount is 0");
        require(cap > 0, "RoundsCrowdsale: cap is 0");

        _roundsCount = roundsCount;

        uint[2] memory bonuses = [uint(10), 5];

        for (uint i = 0; i < _roundsCount; i++) {
            _rounds[i].tokensLeft = cap;
            _rounds[i].rate = initRate.sub(rateDecrement.mul(i));
            _rounds[i].bonusPercent = bonuses[i];
        }

        currentRound = 0;
        _rounds[currentRound].isOpen = super.isOpen();
    }

    function isOpen() public view returns (bool) {
        bool crowdsaleIsOpen = super.isOpen();
        // Open a previously closed first round when the crowdsale starts.
        bool roundIsOpen = _rounds[currentRound].isOpen || (crowdsaleIsOpen && currentRound == 0);
        return crowdsaleIsOpen && roundIsOpen;
    }

    function closeRound() public onlyWhitelistAdmin {
        _rounds[currentRound].isOpen = false;
        if (currentRound < _roundsCount - 1) {
            currentRound += 1;
            _rounds[currentRound].isOpen = true;
            emit RoundOpened(currentRound);
        }
    }

    function openRound(uint n) public onlyWhitelistAdmin {
        _rounds[currentRound].isOpen = false;
        _rounds[n].isOpen = true;
    }

    function rate() public view returns (uint256) {
        revert("IncreasingPriceCrowdsale: rate() called");
    }

    function getRoundsContributions(address beneficiary) public view returns (uint256[] memory) {
        uint256[] memory contributions = new uint256[](_roundsCount);
        for (uint i = 0; i < _roundsCount; i++) {
            contributions[i] = _contributions[beneficiary][i];
        }

        return contributions;
    }

    /**
     * @dev Returns the rate of tokens per wei at the present time.
     * Note that, as price _increases_ with time, the rate _decreases_.
     * @return The number of tokens a buyer gets per wei at a given time
     */
    function getCurrentRate() public view returns (uint256) {
        if (!isOpen()) {
            return 0;
        }

        return _rounds[currentRound].rate;
    }

    /**
     * @dev Overrides parent method taking into account variable rate.
     * @param weiAmount The value in wei to be converted into tokens
     * @return The number of tokens _weiAmount wei will buy at present time
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        return currentRate.mul(weiAmount);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);

        // First round is available only for whitelisted addresses
        if (currentRound == 0) {
            require(validateWhitelisted(beneficiary) == true, 'RoundsCrowdsale: first round is only for whitelisted addresses');
        }

        Round storage round = _rounds[currentRound];
        uint256 tokens = _getTokenAmount(weiAmount);
        uint256 bonusTokens = round.bonusPercent > 0 ? tokens.mul(round.bonusPercent).div(100) : 0;

        require(tokens.add(bonusTokens) <= round.tokensLeft, "RoundsCrowdsale: round cap exceeded");
    }

    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        super._updatePurchasingState(beneficiary, weiAmount);

        // Open the first round if the timed crowdsale started
        if (currentRound == 0 && !_rounds[currentRound].isOpen && super.isOpen()) {
            _rounds[currentRound].isOpen = true;
        }

        // Update round stats
        Round storage round = _rounds[currentRound];
        round.raised = round.raised.add(weiAmount);

        uint256 tokens = _getTokenAmount(weiAmount);

        // If current contributor wasn't in the list, count it
        if (_contributions[msg.sender][currentRound] == 0) {
            round.contributors += 1;
        }

        // Update individual stats
        _contributions[msg.sender][currentRound] = _contributions[msg.sender][currentRound].add(weiAmount);
        require(_contributions[msg.sender][currentRound] < contributionCap, "RoundsCrowdsale: individual contributions cap exceeded");

        // Send round bonus to purchaser
        uint256 bonusTokens = 0;
        if (round.bonusPercent > 0) {
            bonusTokens = tokens.mul(round.bonusPercent).div(100);
            _processPurchase(msg.sender, bonusTokens);
            emit RoundBonusEarned(msg.sender, bonusTokens);
        }

        // Close depleted round
        round.tokensLeft = round.tokensLeft.sub(tokens).sub(bonusTokens);
        if (round.tokensLeft <= _roundTokensLeftThreshold) {
            round.isOpen = false;
        }

        // If the current round is closed, open the next round (if there are any remaining)
        if (!round.isOpen && currentRound < _roundsCount - 1) {
            currentRound += 1;
            _rounds[currentRound].isOpen = true;

            emit RoundOpened(currentRound);
        }
    }

    /**
     * Rounds getter.
     */
    function getRounds() public view
    returns (
        uint[] memory,
        bool[] memory,
        uint256[] memory,
        uint[] memory,
        uint[] memory,
        uint256[] memory,
        uint256[] memory
    ) {
        uint[] memory n = new uint[](_roundsCount);
        bool[] memory openings = new bool[](_roundsCount);
        uint256[] memory rates = new uint256[](_roundsCount);
        uint[] memory bonuses = new uint[](_roundsCount);
        uint[] memory contributors = new uint[](_roundsCount);
        uint256[] memory raised = new uint256[](_roundsCount);
        uint256[] memory tokensLeft = new uint256[](_roundsCount);

        for (uint i = 0; i < _roundsCount; i++) {
            Round storage round = _rounds[i];
            n[i] = i;
            openings[i] = super.isOpen() && round.isOpen;
            rates[i] = round.rate;
            bonuses[i] = round.bonusPercent;
            contributors[i] = round.contributors;
            raised[i] = round.raised;
            tokensLeft[i] = round.tokensLeft;
        }

        return (n, openings, rates, bonuses, contributors, raised, tokensLeft);
    }
}
