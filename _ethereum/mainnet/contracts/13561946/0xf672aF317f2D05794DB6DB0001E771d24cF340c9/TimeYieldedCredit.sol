// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./AccessControlEnumerable.sol";

/// @custom:security-contact astridfox@protonmail.com
contract TimeYieldedCredit is AccessControlEnumerable {
    
    bytes32 public constant YIELD_MANAGER_ROLE = keccak256("YIELD_MANAGER_ROLE");

    // A mapping between yieldId and it's usedCredit
    // A yieldId is an integer representing an entity (address, token, etc...)
    // yieldIds are assigned by an inheriting contract
    mapping(uint256 => uint256) _usedCredit;

    // The timeframe in seconds that generates `yield`
    // Should not be too low as it becomes susceptible to malicious nodes
    uint256 public yieldStep;

    // The amount acrrued after `yieldStep` seconds had passed
    uint256 public yield;

    // The begining timestamp against which yieldsSteps are calculated
    uint256 public epoch;

    // The timestamp after which no more yield will be allowed
    uint256 public horizon = type(uint256).max;

    constructor(
        address yieldManager,
        uint256 yieldStep_,
        uint256 yield_,
        uint256 epoch_,
        uint256 horizon_)
        {
            require(yieldStep_ > 0, "TimeYieldedCredit: yieldStep must be positive");

            epoch = epoch_;
            yieldStep = yieldStep_;
            yield = yield_;
            _setHorizon(horizon_);
            _setupRole(YIELD_MANAGER_ROLE, yieldManager);

        }

    /**
    * @dev Sets a new horizon for the contract as given by `newHorizon`.
    */
    function setHorizon(uint256 newHorizon) public onlyRole(YIELD_MANAGER_ROLE) {
        _setHorizon(newHorizon);
    }

    function _setHorizon(uint256 newHorizon) internal {
        require(newHorizon > epoch, "TimeYieldedCredit: new horizon precedes epoch");
    
        horizon = newHorizon;
    }

    /**
     * @dev Returns the maximum yield up to this point in time
     */
    function getCurrentYield() public view returns(uint256) {
        uint256 effectiveTs = block.timestamp < horizon ? block.timestamp : horizon;
        if (effectiveTs < epoch) {
            return 0;
        }
        unchecked {
            // uint256 currentYieldStep = (effectiveTs - epoch) / yieldStep;
            return ((effectiveTs - epoch) / yieldStep) * yield;
        }
    }

    /**
     * @dev Returns the available credit for `yieldId`, depending on
     * the current time and how much was already spent by it.
     */
    function _creditFor(uint256 yieldId) internal view returns (uint256) {
        uint256 currentYield = getCurrentYield();
        
        uint256 currentSpent = _usedCredit[yieldId];
        if (currentYield > currentSpent) {
            unchecked {
                return currentYield - currentSpent;
            }
        }
        return 0;
    }

    /**
     * @dev Spends `amount` credit from `yieldId`'s balance if available.
     */
    function _spendCredit(uint256 yieldId, uint256 amount) internal {
        uint256 credit = _creditFor(yieldId);
        require(amount <= credit, "TimeYieldedCredit: Insufficient credit");
        _usedCredit[yieldId] += amount;
    }

    /**
     * @dev Spends all available credit from `yieldId`'s balance.
     * Returns the amount of credit spent.
     */
    function _spendAll(uint256 yieldId) internal returns (uint256) {
        uint256 credit = _creditFor(yieldId);
        require(credit > 0, "TimeYieldedCredit: Insufficient credit");
        _usedCredit[yieldId] += credit;

        return credit;
    }

    function _spendCreditBatch(
        uint256[] calldata yieldIds,
        uint256[] calldata amounts
    ) internal returns (uint256) {
        require(yieldIds.length == amounts.length, "TimeYieldedCredit: Incorrect arguments length");
        uint256 totalSpent = 0;

        uint256 currentYield = getCurrentYield();
        
        for (uint256 i = 0; i < yieldIds.length; i++) {
            
            uint256 yieldId = yieldIds[i];
            uint256 currentSpent = _usedCredit[yieldId];

            // if currentSpent == currentYield then revert
            // Thrown when no more credit to spend for the specific yieldId
            require(currentYield > currentSpent, "TimeYieldedCredit: No credit available");

            uint256 amount = amounts[i];
            uint256 credit;
            unchecked {
                credit = currentYield - currentSpent;
            }

            // Thrown when there is some credit available for yieldId but not enough
            require(amount <= credit, "TimeYieldedCredit: Insufficient credit");

            _usedCredit[yieldId] += amount;
            totalSpent += amount;
        }

        return totalSpent;
    }
}