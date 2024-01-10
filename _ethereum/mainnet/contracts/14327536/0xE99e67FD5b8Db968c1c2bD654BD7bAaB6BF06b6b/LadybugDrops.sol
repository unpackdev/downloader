// The tokens of this contract are licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (https://creativecommons.org/licenses/by-nc-sa/4.0/)
// SPDX-License-Identifier:  CC-BY-NC-SA-4.0
pragma solidity ^0.8.0;

import "./LadybugFactory.sol";


/**
 * @author WrightCode
 * @title Ladybug Drops
 * @dev Encapsulates the data surrounding the 4 ladybug "drops".
 */
contract LadybugDrops is LadybugFactory {

    /**
     * @dev Modifier that prevents a date change once a drop has started.
     */
    modifier dropNotStarted(uint8 index, uint date) {
        // the drop we're updating can't be starting within the hour.
        require(drops[index].date == 0 || drops[index].date > block.timestamp + 3600, "Drop starting too soon");
        // the _date value must be two hours out from now
        require(date > block.timestamp + 7200, "New start date too close");
        _;
    }

    /**
     * @dev Modifier to ensure a price change on an active drop will be a descrease.
     * This contract does not allow a price increase on active drops.
     */
    modifier priceNotIncreased(uint8 index, uint price) {
        // the new price must be lower
        require(drops[index].price > price, "Price cannot increase");
        // price drop must be for current or future drop
        require(index >= _currentDropIndex(), "Drop has already completed");
        _;
    }

    /**
     * @dev Return an array of all the drops.
     */
    function getDrops() external view returns (Drop[] memory) {
        Drop[] memory results = new Drop[](drops.length);
        for (uint i = 0; i < drops.length; i++) {
            results[i] = drops[i];
        }
        return results;
    }

    /**
     * @dev Update the price and date of non-active drops only.
     */
    function updateDrop(uint8 index, uint price, uint date)
        external dropNotStarted(index, date) onlyOwner
        {
        drops[index].price = price;
        drops[index].date = date;
        // the price will go into effect on date
        drops[index].priceDate = date;
    }

    /**
     * @dev Decrease the price of an active drop.  Useful if drops "stall out".
     * Why would I do this?  Well, I am not convinced the world will love my ladybugs as
     * much as I love my ladybugs, and I am okay with this.  Art is subjective.
     * So if this proves true, then I want the ability to end the mint, and
     * re-evaluate my distribution plan.  I will not abandon my ladybugs.
     */
    function dropPrice(uint8 index, uint price)
        external priceNotIncreased(index, price) onlyOwner
        {
        drops[index].price = price;
        // the price will go into effect now, if the drops[index].date < block timestamp;
        if (drops[index].date < block.timestamp) {
            // drop is active, so set new priceDate
            drops[index].priceDate = block.timestamp;
        }
    }

    /**
     * @dev Return the current drop index and whether it's active or not.
     */
    function status() external view returns (uint index, bool active, bool complete) {
        return _status();
    }

    function _initializeDrops() internal onlyOwner {
        uint16 startAtIndex = _RESERVED_LADYBUGS;
        for (uint8 i = 0; i < drops.length; i++) {
            drops[i].startAtIndex = startAtIndex;
            startAtIndex += _TOKENS_PER_DROP;
        }
    }

    /**
     * @dev Returns the current drop (0-3) in which the next ladybug would be minted.
     * This does not take the drop date into account, so it might not be an active drop.
     */
    function _currentDropIndex() internal view returns (uint8) {
        for (uint i = drops.length - 1; i >= 0; i--) {
            if (_currentSupplyIndex() >= drops[i].startAtIndex) {
                return uint8(i);
            }
        }
        // should never reach this line of code
        revert("Error finding drop index");
    }

    /**
     * @dev Same call as status, but this one is 'internal'.  Breaking out the two
     * is being done for gas efficiency, when status is needed internally.
     */
    function _status() internal view returns (uint index, bool active, bool complete) {
        uint8 currentIndex = _currentDropIndex();
        bool isComplete = _currentSupplyIndex() >= _MAX_LADYBUGS;
        // a drop is active if all are not complete, the date is non-zero,
        // and the blockchain time is greater than the drop date.
        bool isActive = isComplete != true &&
            drops[currentIndex].date != 0 &&
            drops[currentIndex].date <= block.timestamp;
        return (currentIndex, isActive, isComplete);
    }

}
