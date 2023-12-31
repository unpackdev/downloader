// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./OwnerManager.sol";

/**
 * @title TraderManager
 * @notice A contract managing authorized traders.
 */
abstract contract TraderManager is OwnerManager {
    
    event AddedTrader(address trader);
    event RemovedTrader(address trader);

    // a linked list is used for a better efficience over an array
    mapping(address => address) internal traders;
    uint256 internal traderCount;

    /**
     * @notice Set the initial authorized traders. To be called by KnightSafe setup only.
     * @dev The function is similar to addTrader. But since "owner" is not ready at setup, we need to copy the code here.
     * @param initTraders List of initial authorized traders.
     */
    function setupTrader(address[] memory initTraders) internal {
        traders[ADDRESS_PTR] = ADDRESS_PTR;
        traderCount = initTraders.length;

        for (uint256 i = 0; i < initTraders.length; i++) { 
            require(initTraders[i] != address(0) && initTraders[i] != ADDRESS_PTR, "Trader address is invalid");
            require(traders[initTraders[i]] == address(0), "New trader already in trader list");
            traders[initTraders[i]] = traders[ADDRESS_PTR];
            traders[ADDRESS_PTR] = initTraders[i];
            emit AddedTrader(initTraders[i]);            
        }
    }

    /**
     * @dev Only trader can call functions marked by this modifier. 
     */
    modifier onlyTrader() {
        require(isTrader(msg.sender), "Trader only");
        _;
    }
    
    /**
     * @notice Add a trader to the authorized trader list
     * @param trader Trader to be added to the authorized list
     */
    function addTrader(address trader) public onlyOwner {
        require(trader != address(0) && trader != ADDRESS_PTR, "Trader address is invalid");
        require(traders[trader] == address(0), "New trader already in trader list");
        traders[trader] = traders[ADDRESS_PTR];
        traders[ADDRESS_PTR] = trader;
        traderCount++;
        emit AddedTrader(trader);
    }

    /**
     * @notice Remove a trader from the authorized trader list
     * @param trader Trader to be removed from the authorized list
     */
    function removeTrader(address trader) public onlyOwner {
        require(trader != address(0) && trader != ADDRESS_PTR, "Trader address is invalid");
        require(traders[trader] != address(0), "Trader is not in trader list");

        address previousTrader = ADDRESS_PTR;
        address currentTrader = traders[previousTrader];
        while (currentTrader != ADDRESS_PTR) {
            if (currentTrader == trader) {
                traders[previousTrader] = traders[trader];
                traders[trader] = address(0);
                traderCount--;
                emit RemovedTrader(trader);
                break;
            }
            previousTrader = currentTrader;
            currentTrader = traders[previousTrader];
        }
    }

    /**
     * @notice Allowing mulitple remove trader and add trader in one call
     * @param toRemoveTraders List of traders to be removed from the authorized trader list
     * @param toAddTraders List of traders to be added to the authorized trader list
     */
    function batchUpdateTraders(address[] memory toRemoveTraders, address[] memory toAddTraders) public onlyOwner {
        for (uint256 i = 0; i < toRemoveTraders.length; i++) {
            removeTrader(toRemoveTraders[i]);
        }
        for (uint256 i = 0; i < toAddTraders.length; i++) {
            addTrader(toAddTraders[i]);
        }
    }

    /**
     * @notice Check if trader is in the authorized trader list.
     * @param trader Trader to be checked.
     * @return Boolean if trader is in the authorized trader list.
     */
    function isTrader(address trader) public view returns (bool) {
        return trader != ADDRESS_PTR && traders[trader] != address(0);
    }

    /**
     * @notice Get the list of authorized traders.
     * @return Array of the authorized traders.
     */
    function getTraders() public view returns (address[] memory) {
        address[] memory array = new address[](traderCount);

        uint256 index = 0;
        address currentTrader = traders[ADDRESS_PTR];
        while (currentTrader != ADDRESS_PTR) {
            array[index] = currentTrader;
            currentTrader = traders[currentTrader];
            index++;
        }
        return array;
    }

}