// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IPriceCalculatorManager.sol";

contract PriceCalculatorManager is IPriceCalculatorManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _allowedCalculators;

    event CalculatorRemoved(address indexed calculator);
    event CalculatorAdded(address indexed calculator);

    function addCalculator(address calculator) external onlyOwner {
        require(!_allowedCalculators.contains(calculator), "PriceCalculatorManager: Already allowed");
        _allowedCalculators.add(calculator);

        emit CalculatorAdded(calculator);
    }

    function removeCalculator(address calculator) external onlyOwner {
        require(_allowedCalculators.contains(calculator), "PriceCalculatorManager: Not allowed");
        _allowedCalculators.remove(calculator);

        emit CalculatorRemoved(calculator);
    }

    function isCalculatorAllowed(address calculator) external view returns (bool) {
        return _allowedCalculators.contains(calculator);
    }
    
    function viewCountAllowedCalculators() external view returns (uint256) {
        return _allowedCalculators.length();
    }
    
    function viewAllowedCalculators(uint256 cursor, uint256 size)
        external
        view
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _allowedCalculators.length() - cursor) {
            length = _allowedCalculators.length() - cursor;
        }

        address[] memory allowedCalculators = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            allowedCalculators[i] = _allowedCalculators.at(cursor + i);
        }

        return (allowedCalculators, cursor + length);
    }
}