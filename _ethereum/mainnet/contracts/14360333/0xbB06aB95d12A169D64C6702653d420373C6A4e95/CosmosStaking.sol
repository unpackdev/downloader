//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./Initializable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ICosmos.sol";

contract CosmosStaking is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    uint256 public startTimestamp;
    ICosmos public token;
    IERC721EnumerableUpgradeable public nft;
    uint256 public rate;
    uint256 public period;
    uint256 public bonusPeriod;
    uint256 public totalBonusIntervals;
    uint256 public bonusIncrements;
    uint256 public bonusCap;

    struct Claim {
        uint256 bonus;
        uint256 lastBonusTimestamp;
        uint256 timestamp;
        address lastOwner;
    }

    mapping(uint256 => Claim) private claimed;

    function initialize(uint256 _start, ICosmos _token, IERC721EnumerableUpgradeable _nft) initializer public {
        startTimestamp = _start;
        token = _token;
        nft = _nft;
        rate = 20;
        totalBonusIntervals = 5;
        bonusIncrements = 1;
        bonusPeriod = 7 days;
        bonusCap = totalBonusIntervals * bonusIncrements;
        period = 1 days;
        __AccessControl_init();
        __Pausable_init_unchained();
        __ReentrancyGuard_init();
        _pause();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        @dev get owed for each token and mint for the sender
        - check if they are the owner
        - update claim object
            - if they meet conditions for bonus:
                * new user claiming for first time
                * applicable for bonus (new bonus value) - update bonus and bonus timestamp
     */

    function claim(uint256[] memory ids) external nonReentrant whenNotPaused {
        uint256 total;
        for(uint256 i; i < ids.length; i++) {
            uint256 current = ids[i];
            require(nft.ownerOf(current) == msg.sender, "not authorized");
            (uint256 accrued, uint256 bonus, bool newBonusTimestamp) = owed(current, msg.sender);
            total += accrued;

            Claim memory _claimed = claimed[current];
            _claimed.timestamp = block.timestamp;
            _claimed.lastOwner = msg.sender;
            if(newBonusTimestamp) {
                _claimed.bonus = bonus;
                _claimed.lastBonusTimestamp = block.timestamp;
            }

            claimed[current] = _claimed;
        }

        require(total > 0, "Cannot claim zero tokens");

        token.mint(
            msg.sender,
            total * 1 ether
        );
    }

    function getClaim(uint256 id) public view returns (Claim memory) {
        return claimed[id];
    }

    /**
        @dev returns owed for the tokenID based on timestamp:
        Equation:
            (delta * rate) / period
        Returns bonus based on getBonus criteria
     */
    function owed(uint256 id, address claimee) public view returns (uint256, uint256, bool) {
        Claim memory _token = claimed[id];
        uint256 timestamp = _token.lastOwner == address(0x0) ? startTimestamp : _token.timestamp;
        uint256 owedCosmos = ((block.timestamp - timestamp) * rate / period);
        (uint256 accruedBonus, uint256 bonus, bool newBonusTimestamp) = getBonus(_token, claimee);
        return (owedCosmos + accruedBonus, bonus, newBonusTimestamp);
    }

    /**
        @dev returns bonus based on the following conditions:
        - if it hasn't been a week since last claim then no bonus
        - if it is a new user, bonus value is reset to 0
        - if they have reached bonusCap return bonusCap as bonus
        - else increment by bonusIncrement if they are valid for a bonus
     */

    function getBonus(Claim memory _claim, address claimee) public view returns (uint256, uint256, bool) {
        if(_claim.lastOwner != claimee) return (0, 0, true);
        uint256 _numberOfBonuses = (block.timestamp - _claim.lastBonusTimestamp) / bonusPeriod;
        if(_numberOfBonuses == 0) return (0, 0, false);
        uint256 currentBonus = _claim.bonus;        
        if(currentBonus == bonusCap) return (_numberOfBonuses * bonusCap, bonusCap, true);
        return accruedBonuses(_numberOfBonuses, currentBonus);
    }

    /**
        @dev accrues bonuses based on last claimed
        i.e. if you have not claimed for 5 weeks - you are legible for 5 weeks worth of bonuses
        1 + 2 + 3 + 4 + 5 = 15 extra tokens
     */

    function accruedBonuses(uint256 numOfBonuses, uint256 currentBonus) internal view returns (uint256, uint256, bool) {
        if(numOfBonuses == 1) return (
            currentBonus + bonusIncrements,
            currentBonus + bonusIncrements,
            true
        );

        uint256 product = numOfBonuses * bonusIncrements + currentBonus;

        if(product > bonusCap) {
            uint256 delta = (bonusCap - currentBonus);
            return (
                arithmeticSum(
                    delta,
                    currentBonus + 1,
                    bonusIncrements
                ) + (numOfBonuses - delta) * bonusCap,
                bonusCap,
                true
            );
        }

        return (
            arithmeticSum(
                numOfBonuses,
                currentBonus + 1,
                bonusIncrements
            ),
            currentBonus + numOfBonuses * bonusIncrements,
            true
        );
    }
    
    function arithmeticSum(uint256 n, uint256 a, uint256 d) internal pure returns (uint256) {
        return (2 * a + (n - 1) * d) * (n * 1e18 /2) / 1e18;
    }
    
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /** SETTERS ADMIN ONLY */
    function updateNFT(IERC721EnumerableUpgradeable _nft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nft = _nft;
    }
    function updateToken(ICosmos _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token = _token;
    }
    function updateRate(uint256 _rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rate = _rate;
    }
    function updatePeriod(uint256 _period) external onlyRole(DEFAULT_ADMIN_ROLE) {
        period = _period;
    }
    function updateBonusPeriod(uint256 _bonusPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bonusPeriod = _bonusPeriod;
    }
    function updateBonus(uint256 _bonusIncrements, uint256 _totalBonusIntervals) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bonusIncrements = _bonusIncrements;
        totalBonusIntervals = _totalBonusIntervals;
        bonusCap = _bonusIncrements * _totalBonusIntervals;
    }
}