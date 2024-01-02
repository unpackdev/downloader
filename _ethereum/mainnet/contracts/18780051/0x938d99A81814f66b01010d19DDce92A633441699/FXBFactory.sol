// SPDX-License-Identifier: ISC
pragma solidity ^0.8.23;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================ FXBFactory ============================
// ====================================================================
// Factory contract for FXB tokens
// Frax Finance: https://github.com/FraxFinance

import "./Strings.sol";
import "./Timelock2Step.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./FXB.sol";

/// @title FXBFactory
/// @notice  Deploys FXB ERC20 contracts
/// @dev "FXB" and "bond" are interchangeable
/// @dev https://github.com/FraxFinance/frax-bonds
contract FXBFactory is Timelock2Step {
    using Strings for uint256;

    // =============================================================================================
    // Storage
    // =============================================================================================

    // Core
    /// @notice The Frax token contract
    address public immutable FRAX;

    /// @notice Array of bond addresses
    address[] public fxbs;

    /// @notice Whether a given address is a bond
    mapping(address _fxb => bool _isFxb) public isFxb;

    /// @notice Whether a given timestamp has a bond deployed
    mapping(uint256 _timestamp => bool _isFxb) public isTimestampFxb;

    // =============================================================================================
    // Constructor
    // =============================================================================================

    /// @notice Constructor
    /// @param _timelock The owner of this contract
    /// @param _frax The address of the FRAX token
    constructor(address _timelock, address _frax) Timelock2Step(_timelock) {
        FRAX = _frax;
    }

    //==============================================================================
    // Helper Functions
    //==============================================================================

    /// @notice This function returns the 3 letter name of a month, given its index
    /// @param _monthIndex The index of the month
    /// @return _monthName The name of the month
    function _monthNames(uint256 _monthIndex) internal pure returns (string memory _monthName) {
        if (_monthIndex == 1) return "JAN";
        if (_monthIndex == 2) return "FEB";
        if (_monthIndex == 3) return "MAR";
        if (_monthIndex == 4) return "APR";
        if (_monthIndex == 5) return "MAY";
        if (_monthIndex == 6) return "JUN";
        if (_monthIndex == 7) return "JUL";
        if (_monthIndex == 8) return "AUG";
        if (_monthIndex == 9) return "SEP";
        if (_monthIndex == 10) return "OCT";
        if (_monthIndex == 11) return "NOV";
        if (_monthIndex == 12) return "DEC";
        revert InvalidMonthNumber();
    }

    // =============================================================================================
    // View functions
    // =============================================================================================

    /// @notice Returns the total number of bonds addresses created
    /// @return _length uint256 Number of bonds addresses created
    function fxbsLength() public view returns (uint256 _length) {
        return fxbs.length;
    }

    /// @notice Generates the bond symbol in the format FXB_YYYYMMDD
    /// @param _maturityTimestamp Date the bond will mature
    /// @return _symbol The symbol of the bond
    function _generateSymbol(uint256 _maturityTimestamp) internal pure returns (string memory _symbol) {
        // Maturity date
        uint256 month = DateTimeLibrary.getMonth(_maturityTimestamp);
        uint256 day = DateTimeLibrary.getDay(_maturityTimestamp);
        uint256 year = DateTimeLibrary.getYear(_maturityTimestamp);

        // Generate the month part of the symbol
        string memory monthString;
        if (month > 9) {
            monthString = month.toString();
        } else {
            monthString = string.concat("0", month.toString());
        }

        // Generate the day part of the symbol
        string memory dayString;
        if (day > 9) {
            dayString = day.toString();
        } else {
            dayString = string.concat("0", day.toString());
        }

        // Assemble all the strings into one
        _symbol = string(abi.encodePacked("FXB", "_", year.toString(), monthString, dayString));
    }

    /// @notice Generates the bond name in the format FXB_ID_MMMDDYYYY
    /// @param _id The id of the bond
    /// @param _maturityTimestamp Date the bond will mature
    /// @return _name The name of the bond
    function _generateName(uint256 _id, uint256 _maturityTimestamp) internal pure returns (string memory _name) {
        // Maturity date
        uint256 month = DateTimeLibrary.getMonth(_maturityTimestamp);
        uint256 day = DateTimeLibrary.getDay(_maturityTimestamp);
        uint256 year = DateTimeLibrary.getYear(_maturityTimestamp);

        // Generate the day part of the name
        string memory dayString;
        if (day > 9) {
            dayString = day.toString();
        } else {
            dayString = string(abi.encodePacked("0", day.toString()));
        }

        // Assemble all the strings into one
        _name = string(
            abi.encodePacked("FXB", "_", _id.toString(), "_", _monthNames(month), dayString, year.toString())
        );
    }

    // =============================================================================================
    // Configurations / Privileged functions
    // =============================================================================================

    /// @notice Generates a new bond contract
    /// @param _maturityTimestamp Date the bond will mature and be redeemable
    /// @return fxb The address of the new bond
    /// @return id The id of the new bond
    function createFxbContract(uint256 _maturityTimestamp) external returns (address fxb, uint256 id) {
        _requireSenderIsTimelock();

        // Round the timestamp down to 00:00 UTC
        uint256 _coercedMaturityTimestamp = (_maturityTimestamp / 1 days) * 1 days;

        // Make sure the bond didn't expire
        if (_coercedMaturityTimestamp <= block.timestamp) {
            revert BondMaturityAlreadyExpired();
        }

        // Ensure bond maturity is unique
        if (isTimestampFxb[_coercedMaturityTimestamp]) {
            revert BondMaturityAlreadyExists();
        }

        // Set the bond id
        id = fxbsLength();

        // Get the new symbol and name
        string memory symbol = _generateSymbol({ _maturityTimestamp: _coercedMaturityTimestamp });
        string memory name = _generateName({ _id: id, _maturityTimestamp: _coercedMaturityTimestamp });

        // Create the new contract
        fxb = address(
            new FXB({ _symbol: symbol, _name: name, _maturityTimestamp: _coercedMaturityTimestamp, _frax: FRAX })
        );

        // Add the new bond address to the array and update the mapping
        fxbs.push(fxb);
        isFxb[fxb] = true;

        // Mark the maturity timestamp as having a bond associated with it
        isTimestampFxb[_coercedMaturityTimestamp] = true;

        emit BondCreated({
            fxb: fxb,
            id: id,
            symbol: symbol,
            name: name,
            maturityTimestamp: _coercedMaturityTimestamp
        });
    }

    // ==============================================================================
    // Events
    // ==============================================================================

    /// @notice Emitted when a new bond is created
    /// @param fxb Address of the bond
    /// @param id The ID of the bond
    /// @param symbol The bond's symbol
    /// @param name Name of the bond
    /// @param maturityTimestamp Date the bond will mature
    event BondCreated(address fxb, uint256 id, string symbol, string name, uint256 maturityTimestamp);

    // ==============================================================================
    // Errors
    // ==============================================================================

    /// @notice Thrown when an invalid month number is passed
    error InvalidMonthNumber();

    /// @notice Thrown when a bond with the same maturity already exists
    error BondMaturityAlreadyExists();

    /// @notice Thrown when attempting to create a bond with an expiration before the current time
    error BondMaturityAlreadyExpired();
}
