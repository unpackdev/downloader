// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

/*
███████╗████████╗ ██████╗ ███╗   ██╗██╗  ██╗███████╗
██╔════╝╚══██╔══╝██╔═══██╗████╗  ██║██║ ██╔╝██╔════╝
███████╗   ██║   ██║   ██║██╔██╗ ██║█████╔╝ ███████╗
╚════██║   ██║   ██║   ██║██║╚██╗██║██╔═██╗ ╚════██║
███████║   ██║   ╚██████╔╝██║ ╚████║██║  ██╗███████║
╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝
*/

/**
 * @title Trading hours ERC20 Token
 * @notice A fun and innovative approach to balanced crypto trading. Operates only during standard trading hours.
 * @dev ERC20 Token that can be transferred only during standard trading hours,
 * taking into account Daylight Saving Time adjustments.
 * Inherits from solmate ERC20 and openzeppelin Ownable contracts.
 */
contract TradingHoursCoin is ERC20, Ownable {
    using BokkyPooBahsDateTimeLibrary for uint256;

    uint256 public hoursToSub; 

    // 32 byte error string
    string private constant ERROR_STRING = "Trading closed. Try again later.";

    constructor() ERC20('Trading Hours Coin', 'THC', 18) {
        // one billion coin total supply
        _mint(msg.sender, 1000000000 ether);
        adjustDST();
    }
    /**
    * @notice Function to manually trigger DST adjustment based on the current date
    * any wallet can call this function by design
    */
    function adjustDST() public {
        uint256 timestamp = block.timestamp;
        uint256 month = BokkyPooBahsDateTimeLibrary.getMonth(timestamp);
        uint256 day = BokkyPooBahsDateTimeLibrary.getDay(timestamp);

        if ((month > 3 && month < 11) 
        || (month == 3 && day >= secondSundayOfMarch(BokkyPooBahsDateTimeLibrary.getYear(timestamp))) 
        || (month == 11 && day < firstSundayOfNovember(BokkyPooBahsDateTimeLibrary.getYear(timestamp)))) {
            hoursToSub = 4; // DST is UTC-4
        } else {
            hoursToSub = 5; // Non-DST is UTC-5
        }
    }

    // Helper functions to determine the second Sunday of March and the first Sunday of November
    function secondSundayOfMarch(uint year) private pure returns (uint) {
        uint256 day = 8; // March 8 is the earliest possible second Sunday
        while (BokkyPooBahsDateTimeLibrary.getDayOfWeek(BokkyPooBahsDateTimeLibrary.timestampFromDate(year, 3, day)) != 7) {
            unchecked {
                day++;
            }
        }
        return day;
    }

    function firstSundayOfNovember(uint year) private pure returns (uint) {
        uint256 day = 1; // November 1 is the earliest possible first Sunday
        while (BokkyPooBahsDateTimeLibrary.getDayOfWeek(BokkyPooBahsDateTimeLibrary.timestampFromDate(year, 11, day)) != 7) {
            unchecked{
                day++;
            }
        }
        return day;
    }

    // Override ERC20 transfer functions to check if trading is closed
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if(isTradingClosed()){
            revert(ERROR_STRING);
        }
        return super.transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if(isTradingClosed()){
            revert(ERROR_STRING);
        }
        return super.transfer(to, amount);
    }

    function isTradingClosed() public view returns(bool) {
        uint256 timestamp = getAdjustedTimestamp();
        bool isWeekend = BokkyPooBahsDateTimeLibrary.isWeekEnd(timestamp);

        if(isWeekend) {
            return true;
        }

        uint256 hour = BokkyPooBahsDateTimeLibrary.getHour(timestamp);
        uint256 minute = BokkyPooBahsDateTimeLibrary.getMinute(timestamp);

        if(hour < 9 || hour > 15) {
            return true;
        }

        if(hour == 9 && minute < 30) {
            return true;
        }

        return false;
    }

    function getAdjustedTimestamp() public view returns(uint timestamp) {
        return BokkyPooBahsDateTimeLibrary.subHours(block.timestamp, hoursToSub);
    }
}
