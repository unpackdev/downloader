// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ILUSDToken is IERC20 { 
    
    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event LUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IBLUSDToken is IERC20 {
    function mint(address _to, uint256 _bLUSDAmount) external;

    function burn(address _from, uint256 _bLUSDAmount) external;
}

interface ICurvePool is IERC20 { 
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256 mint_amount);

    function remove_liquidity(uint256 burn_amount, uint256[2] memory _min_amounts) external;

    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external;

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function get_dy(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_dy_underlying(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function D() external returns (uint256);

    function future_A_gamma_time() external returns (uint256);
}

interface IYearnVault is IERC20 { 
    function deposit(uint256 _tokenAmount) external returns (uint256);

    function withdraw(uint256 _tokenAmount) external returns (uint256);

    function lastReport() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function calcTokenToYToken(uint256 _tokenAmount) external pure returns (uint256); 

    function token() external view returns (address);

    function availableDepositLimit() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function name() external view returns (string memory);

    function setDepositLimit(uint256 limit) external;

    function withdrawalQueue(uint256) external returns (address);
}

interface IBAMM {
    function deposit(uint256 lusdAmount) external;

    function withdraw(uint256 lusdAmount, address to) external;

    function swap(uint lusdAmount, uint minEthReturn, address payable dest) external returns(uint);

    function getSwapEthAmount(uint lusdQty) external view returns(uint ethAmount, uint feeLusdAmount);

    function getLUSDValue() external view returns (uint256, uint256, uint256);

    function setChicken(address _chicken) external;
}

interface IChickenBondManager {
    // Valid values for `status` returned by `getBondData()`
    enum BondStatus {
        nonExistent,
        active,
        chickenedOut,
        chickenedIn
    }

    function lusdToken() external view returns (ILUSDToken);
    function bLUSDToken() external view returns (IBLUSDToken);
    function curvePool() external view returns (ICurvePool);
    function bammSPVault() external view returns (IBAMM);
    function yearnCurveVault() external view returns (IYearnVault);
    // constants
    function INDEX_OF_LUSD_TOKEN_IN_CURVE_POOL() external pure returns (int128);

    function createBond(uint256 _lusdAmount) external returns (uint256);
    function createBondWithPermit(
        address owner, 
        uint256 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external  returns (uint256);
    function chickenOut(uint256 _bondID, uint256 _minLUSD) external;
    function chickenIn(uint256 _bondID) external;
    function redeem(uint256 _bLUSDToRedeem, uint256 _minLUSDFromBAMMSPVault) external returns (uint256, uint256);

    // getters
    function calcRedemptionFeePercentage(uint256 _fractionOfBLUSDToRedeem) external view returns (uint256);
    function getBondData(uint256 _bondID) external view returns (uint256 lusdAmount, uint64 claimedBLUSD, uint64 startTime, uint64 endTime, uint8 status);
    function getLUSDToAcquire(uint256 _bondID) external view returns (uint256);
    function calcAccruedBLUSD(uint256 _bondID) external view returns (uint256);
    function calcBondBLUSDCap(uint256 _bondID) external view returns (uint256);
    function getLUSDInBAMMSPVault() external view returns (uint256);
    function calcTotalYearnCurveVaultShareValue() external view returns (uint256);
    function calcTotalLUSDValue() external view returns (uint256);
    function getPendingLUSD() external view returns (uint256);
    function getAcquiredLUSDInSP() external view returns (uint256);
    function getAcquiredLUSDInCurve() external view returns (uint256);
    function getTotalAcquiredLUSD() external view returns (uint256);
    function getPermanentLUSD() external view returns (uint256);
    function getOwnedLUSDInSP() external view returns (uint256);
    function getOwnedLUSDInCurve() external view returns (uint256);
    function calcSystemBackingRatio() external view returns (uint256);
    function calcUpdatedAccrualParameter() external view returns (uint256);
    function getBAMMLUSDDebt() external view returns (uint256);
}

interface IBondNFT is IERC721Enumerable {
    struct BondExtraData {
        uint80 initialHalfDna;
        uint80 finalHalfDna;
        uint32 troveSize;         // Debt in LUSD
        uint32 lqtyAmount;        // Holding LQTY, staking or deposited into Pickle
        uint32 curveGaugeSlopes;  // For 3CRV and Frax pools combined
    }

    function mint(address _bonder, uint256 _permanentSeed) external returns (uint256, uint80);
    function setFinalExtraData(address _bonder, uint256 _tokenID, uint256 _permanentSeed) external returns (uint80);
    function chickenBondManager() external view returns (IChickenBondManager);
    function getBondAmount(uint256 _tokenID) external view returns (uint256 amount);
    function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime);
    function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime);
    function getBondInitialHalfDna(uint256 _tokenID) external view returns (uint80 initialHalfDna);
    function getBondInitialDna(uint256 _tokenID) external view returns (uint256 initialDna);
    function getBondFinalHalfDna(uint256 _tokenID) external view returns (uint80 finalHalfDna);
    function getBondFinalDna(uint256 _tokenID) external view returns (uint256 finalDna);
    function getBondStatus(uint256 _tokenID) external view returns (uint8 status);
    function getBondExtraData(uint256 _tokenID) external view returns (uint80 initialHalfDna, uint80 finalHalfDna, uint32 troveSize, uint32 lqtyAmount, uint32 curveGaugeSlopes);
}

interface IBondNFTArtwork {
    function tokenURI(uint256 _tokenID, IBondNFT.BondExtraData calldata _bondExtraData) external view returns (string memory);
}

contract EggTraitWeights {
    enum BorderColor {
        White,
        Black,
        Bronze,
        Silver,
        Gold,
        Rainbow
    }

    enum CardColor {
        Red,
        Green,
        Blue,
        Purple,
        Pink,
        YellowPink,
        BlueGreen,
        PinkBlue,
        RedPurple,
        Bronze,
        Silver,
        Gold,
        Rainbow
    }

    enum ShellColor {
        OffWhite,
        LightBlue,
        DarkerBlue,
        LighterOrange,
        LightOrange,
        DarkerOrange,
        LightGreen,
        DarkerGreen,
        Bronze,
        Silver,
        Gold,
        Rainbow,
        Luminous
    }

    uint256[6] public borderWeights = [30e16, 30e16, 15e16, 12e16, 8e16, 5e16];
    uint256[13] public cardWeights = [12e16, 12e16, 12e16, 11e16, 11e16, 7e16, 7e16, 7e16, 7e16, 5e16, 4e16, 3e16, 2e16];
    uint256[13] public shellWeights = [11e16, 9e16, 9e16, 10e16, 10e16, 10e16, 10e16, 10e16, 75e15, 6e16, 4e16, 25e15, 1e16];

    // Turn the pseudo-random number `rand` -- 18 digit FP in range [0,1) -- into a border color.
    function _getBorderColor(uint256 rand) internal view returns (BorderColor) {
        uint256 needle = borderWeights[uint256(BorderColor.White)];
        if (rand < needle) { return BorderColor.White; }
        needle += borderWeights[uint256(BorderColor.Black)];
        if (rand < needle) { return BorderColor.Black; }
        needle += borderWeights[uint256(BorderColor.Bronze)];
        if (rand < needle) { return BorderColor.Bronze; }
        needle += borderWeights[uint256(BorderColor.Silver)];
        if (rand < needle) { return BorderColor.Silver; }
        needle += borderWeights[uint256(BorderColor.Gold)];
        if (rand < needle) { return BorderColor.Gold; }
        return BorderColor.Rainbow;
    }

    function _getCardAffinityWeights(BorderColor borderColor) internal view returns (uint256[13] memory cardWeightsCached) {
        if (borderColor == BorderColor.Bronze ||
            borderColor == BorderColor.Silver ||
            borderColor == BorderColor.Gold   ||
            borderColor == BorderColor.Rainbow
        ) {
            uint256 selectedCardColor =
                borderColor == BorderColor.Bronze ? uint256(CardColor.Bronze) :
                borderColor == BorderColor.Silver ? uint256(CardColor.Silver) :
                borderColor == BorderColor.Gold ? uint256(CardColor.Gold) :
                uint256(CardColor.Rainbow);
            uint256 originalWeight = cardWeights[selectedCardColor];
            uint256 finalWeight = originalWeight * 2;
            // As we are going to duplicate the original weight of the selected color,
            // we reduce that extra amount from all other weights, proportionally,
            // so we keep the total of 100%
            for (uint256 i = 0; i < cardWeightsCached.length; i++) {
                cardWeightsCached[i] = cardWeights[i] * (1e18 - finalWeight) / (1e18 - originalWeight);
            }
            cardWeightsCached[selectedCardColor] = finalWeight;
        } else {
            for (uint256 i = 0; i < cardWeightsCached.length; i++) {
                cardWeightsCached[i] = cardWeights[i];
            }
        }
    }

    // Turn the pseudo-random number `rand` -- 18 digit FP in range [0,1) -- into a card color.
    function _getCardColor(uint256 rand, BorderColor borderColor) internal view returns (CardColor) {
        // first adjust weights for affinity
        uint256[13] memory cardWeightsCached = _getCardAffinityWeights(borderColor);

        // then compute color
        uint256 needle = cardWeightsCached[uint256(CardColor.Red)];
        if (rand < needle) { return CardColor.Red; }
        needle += cardWeightsCached[uint256(CardColor.Green)];
        if (rand < needle) { return CardColor.Green; }
        needle += cardWeightsCached[uint256(CardColor.Blue)];
        if (rand < needle) { return CardColor.Blue; }
        needle += cardWeightsCached[uint256(CardColor.Purple)];
        if (rand < needle) { return CardColor.Purple; }
        needle += cardWeightsCached[uint256(CardColor.Pink)];
        if (rand < needle) { return CardColor.Pink; }
        needle += cardWeightsCached[uint256(CardColor.YellowPink)];
        if (rand < needle) { return CardColor.YellowPink; }
        needle += cardWeightsCached[uint256(CardColor.BlueGreen)];
        if (rand < needle) { return CardColor.BlueGreen; }
        needle += cardWeightsCached[uint256(CardColor.PinkBlue)];
        if (rand < needle) { return CardColor.PinkBlue; }
        needle += cardWeightsCached[uint256(CardColor.RedPurple)];
        if (rand < needle) { return CardColor.RedPurple; }
        needle += cardWeightsCached[uint256(CardColor.Bronze)];
        if (rand < needle) { return CardColor.Bronze; }
        needle += cardWeightsCached[uint256(CardColor.Silver)];
        if (rand < needle) { return CardColor.Silver; }
        needle += cardWeightsCached[uint256(CardColor.Gold)];
        if (rand < needle) { return CardColor.Gold; }
        return CardColor.Rainbow;
    }

    function _getShellAffinityWeights(BorderColor borderColor) internal view returns (uint256[13] memory shellWeightsCached) {
        if (borderColor == BorderColor.Bronze ||
            borderColor == BorderColor.Silver ||
            borderColor == BorderColor.Gold   ||
            borderColor == BorderColor.Rainbow
        ) {
            uint256 selectedShellColor =
                borderColor == BorderColor.Bronze ? uint256(ShellColor.Bronze) :
                borderColor == BorderColor.Silver ? uint256(ShellColor.Silver) :
                borderColor == BorderColor.Gold ? uint256(ShellColor.Gold) :
                uint256(ShellColor.Rainbow);
            uint256 originalWeight = shellWeights[selectedShellColor];
            uint256 finalWeight = originalWeight * 2;
            // As we are going to duplicate the original weight of the selected color,
            // we reduce that extra amount from all other weights, proportionally,
            // so we keep the total of 100%
            for (uint256 i = 0; i < shellWeightsCached.length; i++) {
                shellWeightsCached[i] = shellWeights[i] * (1e18 - finalWeight) / (1e18 - originalWeight);
            }
            shellWeightsCached[selectedShellColor] = finalWeight;
        } else {
            for (uint256 i = 0; i < shellWeightsCached.length; i++) {
                shellWeightsCached[i] = shellWeights[i];
            }
        }
    }

    // Turn the pseudo-random number `rand` -- 18 digit FP in range [0,1) -- into a shell color.
    function _getShellColor(uint256 rand, BorderColor borderColor) internal view returns (ShellColor) {
        // first adjust weights for affinity
        uint256[13] memory shellWeightsCached = _getShellAffinityWeights(borderColor);

        // then compute color
        uint256 needle = shellWeightsCached[uint256(ShellColor.OffWhite)];
        if (rand < needle) { return ShellColor.OffWhite; }
        needle += shellWeightsCached[uint256(ShellColor.LightBlue)];
        if (rand < needle) { return ShellColor.LightBlue; }
        needle += shellWeightsCached[uint256(ShellColor.DarkerBlue)];
        if (rand < needle) { return ShellColor.DarkerBlue; }
        needle += shellWeightsCached[uint256(ShellColor.LighterOrange)];
        if (rand < needle) { return ShellColor.LighterOrange; }
        needle += shellWeightsCached[uint256(ShellColor.LightOrange)];
        if (rand < needle) { return ShellColor.LightOrange; }
        needle += shellWeightsCached[uint256(ShellColor.DarkerOrange)];
        if (rand < needle) { return ShellColor.DarkerOrange; }
        needle += shellWeightsCached[uint256(ShellColor.LightGreen)];
        if (rand < needle) { return ShellColor.LightGreen; }
        needle += shellWeightsCached[uint256(ShellColor.DarkerGreen)];
        if (rand < needle) { return ShellColor.DarkerGreen; }
        needle += shellWeightsCached[uint256(ShellColor.Bronze)];
        if (rand < needle) { return ShellColor.Bronze; }
        needle += shellWeightsCached[uint256(ShellColor.Silver)];
        if (rand < needle) { return ShellColor.Silver; }
        needle += shellWeightsCached[uint256(ShellColor.Gold)];
        if (rand < needle) { return ShellColor.Gold; }
        needle += shellWeightsCached[uint256(ShellColor.Rainbow)];
        if (rand < needle) { return ShellColor.Rainbow; }
        return ShellColor.Luminous;
    }
}

interface IChickenBondManagerGetter {
    function chickenBondManager() external view returns (IChickenBondManager);
}

contract GenerativeEggArtwork is EggTraitWeights, IBondNFTArtwork {
    using Strings for uint256;

    enum EggSize {
        Tiny,
        Small,
        Normal,
        Big
    }

    struct BondData {
        uint256 tokenID;
        uint256 lusdAmount;
        uint256 claimedBLUSD;
        uint256 startTime;
        uint256 endTime;
        uint80 initialHalfDna;
        uint80 finalHalfDna;
        uint8 status;

        // Attributes derived from the DNA
        BorderColor borderColor;
        CardColor cardColor;
        ShellColor shellColor;
        EggSize eggSize;

        // Further data derived from the attributes
        string solidBorderColor;
        string solidCardColor;
        string solidShellColor;
        bool isBlendedShell;
        bool hasCardGradient;
        string[2] cardGradient;
    }

    function _getEggSize(uint256 lusdAmount) internal pure returns (EggSize) {
        return (
            lusdAmount <    1_000e18 ?  EggSize.Tiny   :
            lusdAmount <   10_000e18 ?  EggSize.Small  :
            lusdAmount <  100_000e18 ?  EggSize.Normal :
         /* lusdAmount >= 100_000e18 */ EggSize.Big
        );
    }

    function _cutDNA(uint256 dna, uint8 startBit, uint8 numBits) internal pure returns (uint256) {
        uint256 ceil = 1 << numBits;
        uint256 bits = (dna >> startBit) & (ceil - 1);

        return bits * 1e18 / ceil; // scaled to [0,1) range
    }

    function _calcAttributes(BondData memory _bondData) internal view {
        uint80 dna = _bondData.initialHalfDna;

        _bondData.borderColor = _getBorderColor(_cutDNA(dna,  0, 26));
        _bondData.cardColor   = _getCardColor  (_cutDNA(dna, 26, 27), _bondData.borderColor);
        _bondData.shellColor  = _getShellColor (_cutDNA(dna, 53, 27), _bondData.borderColor);

        _bondData.eggSize = _getEggSize(_bondData.lusdAmount);
    }

    function _getSolidBorderColor(BorderColor _color) internal pure returns (string memory) {
        return (
            _color == BorderColor.White  ?    "#fff" :
            _color == BorderColor.Black  ?    "#000" :
            _color == BorderColor.Bronze ? "#cd7f32" :
            _color == BorderColor.Silver ? "#c0c0c0" :
            _color == BorderColor.Gold   ? "#ffd700" : ""
        );
    }

    function _getSolidCardColor(CardColor _color) internal pure returns (string memory) {
        return (
            _color == CardColor.Red    ? "#ea394e" :
            _color == CardColor.Green  ? "#5caa4b" :
            _color == CardColor.Blue   ? "#008bf7" :
            _color == CardColor.Purple ? "#9d34e8" :
            _color == CardColor.Pink   ? "#e54cae" : ""
        );
    }

    function _getSolidShellColor(ShellColor _shell, CardColor _card) internal pure returns (string memory) {
        return (
            _shell == ShellColor.OffWhite      ? "#fff1cb" :
            _shell == ShellColor.LightBlue     ? "#e5eff9" :
            _shell == ShellColor.DarkerBlue    ? "#aedfe2" :
            _shell == ShellColor.LighterOrange ? "#f6dac9" :
            _shell == ShellColor.LightOrange   ? "#f8d1b2" :
            _shell == ShellColor.DarkerOrange  ? "#fcba92" :
            _shell == ShellColor.LightGreen    ? "#c5e8d6" :
            _shell == ShellColor.DarkerGreen   ? "#e5daaa" :
            _shell == ShellColor.Bronze        ? "#cd7f32" :
            _shell == ShellColor.Silver        ? "#c0c0c0" :
            _shell == ShellColor.Gold          ? "#ffd700" :

            _shell == ShellColor.Luminous ? (
                _card == CardColor.Bronze ? "#cd7f32" :
                _card == CardColor.Silver ? "#c0c0c0" :
                _card == CardColor.Gold   ? "#ffd700" : ""
            ) : ""
        );
    }

    function _getCardGradient(CardColor _color) internal pure returns (bool, string[2] memory) {
        return (
            _color == CardColor.YellowPink ? (true, ["#ffd200", "#ff0087"]) :
            _color == CardColor.BlueGreen  ? (true, ["#008bf7", "#58b448"]) :
            _color == CardColor.PinkBlue   ? (true, ["#f900bd", "#00a7f6"]) :
            _color == CardColor.RedPurple  ? (true, ["#ea394e", "#9d34e8"]) :
            _color == CardColor.Bronze     ? (true, ["#804a00", "#cd7b26"]) :
            _color == CardColor.Silver     ? (true, ["#71706e", "#b6b6b6"]) :
            _color == CardColor.Gold       ? (true, ["#aa6c39", "#ffae00"]) : (false, ["", ""])
        );
    }

    function _calcDerivedData(BondData memory _bondData) internal pure {
        _bondData.solidBorderColor = _getSolidBorderColor(_bondData.borderColor);
        _bondData.solidCardColor = _getSolidCardColor(_bondData.cardColor);
        _bondData.solidShellColor = _getSolidShellColor(_bondData.shellColor, _bondData.cardColor);

        _bondData.isBlendedShell = _bondData.shellColor == ShellColor.Luminous && !(
            _bondData.cardColor == CardColor.Bronze ||
            _bondData.cardColor == CardColor.Silver ||
            _bondData.cardColor == CardColor.Gold   ||
            _bondData.cardColor == CardColor.Rainbow
        );

        (_bondData.hasCardGradient, _bondData.cardGradient) = _getCardGradient(_bondData.cardColor);
    }

    function tokenURI(uint256 _tokenID, IBondNFT.BondExtraData calldata _bondExtraData) external view returns (string memory) {
        IChickenBondManager chickenBondManager =
            IChickenBondManagerGetter(msg.sender).chickenBondManager();

        BondData memory bondData;
        bondData.tokenID = _tokenID;
        (
            bondData.lusdAmount,
            bondData.claimedBLUSD,
            bondData.startTime,
            bondData.endTime,
            bondData.status
        ) = chickenBondManager.getBondData(_tokenID);
        bondData.initialHalfDna = _bondExtraData.initialHalfDna;
        bondData.finalHalfDna = _bondExtraData.finalHalfDna;

        _calcAttributes(bondData);
        _calcDerivedData(bondData);

        return _getMetadataJSON(bondData);
    }

    // function testTokenURI(
    //     uint256 _tokenID,
    //     uint256 _lusdAmount,
    //     uint256 _startTime,
    //     BorderColor _borderColor,
    //     CardColor _cardColor,
    //     ShellColor _shellColor,
    //     EggSize _eggSize
    // )
    //     external
    //     pure
    //     returns (string memory)
    // {
    //     BondData memory bondData;
    //     bondData.tokenID = _tokenID;
    //     bondData.lusdAmount = _lusdAmount;
    //     bondData.startTime = _startTime;
        
    //     bondData.borderColor = _borderColor;
    //     bondData.cardColor = _cardColor;
    //     bondData.shellColor = _shellColor;
    //     bondData.eggSize = _eggSize;

    //     _calcDerivedData(bondData);

    //     return _getMetadataJSON(bondData);
    // }

    function _getMetadataCardAttributes(BondData memory _bondData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '{"trait_type":"Border","value":"', _getBorderValue(_bondData.borderColor), '"},',
            '{"trait_type":"Card","value":"', _getCardValue(_bondData.cardColor), '"},',
            '{"trait_type":"Shell","value":"', _getShellValue(_bondData.shellColor), '"},',
            '{"trait_type":"Size","value":"', _getSizeValue(_bondData.eggSize), '"}'
        );
    }

    function _getMetadataAttributes(BondData memory _bondData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '"attributes":[',
                '{"display_type":"date","trait_type":"Created","value":', _bondData.startTime.toString(), '},',
                '{"display_type":"number","trait_type":"Bond Amount","value":', _formatDecimal(_bondData.lusdAmount), '},',
                '{"trait_type":"Bond Status","value":"', _getBondStatusValue(IChickenBondManager.BondStatus(_bondData.status)), '"},',
                _getMetadataCardAttributes(_bondData),
            ']'
        );
    }

    function _getMetadataJSON(BondData memory _bondData) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    abi.encodePacked(
                        '{',
                            '"name":"LUSD Chicken #', _bondData.tokenID.toString(), '",',
                            '"description":"LUSD Chicken Bonds",',
                            '"image":"data:image/svg+xml;base64,', Base64.encode(_getSVG(_bondData)), '",',
                            '"background_color":"0b112f",',
                            _getMetadataAttributes(_bondData),
                        '}'
                    )
                )
            )
        );
    }

    function _getBondStatusValue(IChickenBondManager.BondStatus _status) internal pure returns (string memory) {
        return (
            _status == IChickenBondManager.BondStatus.chickenedIn  ? "Chickened In"  :
            _status == IChickenBondManager.BondStatus.chickenedOut ? "Chickened Out" :
            _status == IChickenBondManager.BondStatus.active       ? "Active"        : ""
        );
    }

    function _getBorderValue(BorderColor _border) internal pure returns (string memory) {
        return (
            _border == BorderColor.White    ? "White"   :
            _border == BorderColor.Black    ? "Black"   :
            _border == BorderColor.Bronze   ? "Bronze"  :
            _border == BorderColor.Silver   ? "Silver"  :
            _border == BorderColor.Gold     ? "Gold"    :
            _border == BorderColor.Rainbow  ? "Rainbow" : ""
        );
    }

    function _getCardValue(CardColor _card) internal pure returns (string memory) {
        return (
            _card == CardColor.Red        ? "Red"         :
            _card == CardColor.Green      ? "Green"       :
            _card == CardColor.Blue       ? "Blue"        :
            _card == CardColor.Purple     ? "Purple"      :
            _card == CardColor.Pink       ? "Pink"        :
            _card == CardColor.YellowPink ? "Yellow-Pink" :
            _card == CardColor.BlueGreen  ? "Blue-Green"  :
            _card == CardColor.PinkBlue   ? "Pink-Blue"   :
            _card == CardColor.RedPurple  ? "Red-Purple"  :
            _card == CardColor.Bronze     ? "Bronze"      :
            _card == CardColor.Silver     ? "Silver"      :
            _card == CardColor.Gold       ? "Gold"        :
            _card == CardColor.Rainbow    ? "Rainbow"     : ""
        );
    }

    function _getShellValue(ShellColor _shell) internal pure returns (string memory) {
        return (
            _shell == ShellColor.OffWhite      ? "Off-White"      :
            _shell == ShellColor.LightBlue     ? "Light Blue"     :
            _shell == ShellColor.DarkerBlue    ? "Darker Blue"    :
            _shell == ShellColor.LighterOrange ? "Lighter Orange" :
            _shell == ShellColor.LightOrange   ? "Light Orange"   :
            _shell == ShellColor.DarkerOrange  ? "Darker Orange"  :
            _shell == ShellColor.LightGreen    ? "Light Green"    :
            _shell == ShellColor.DarkerGreen   ? "Darker Green"   :
            _shell == ShellColor.Bronze        ? "Bronze"         :
            _shell == ShellColor.Silver        ? "Silver"         :
            _shell == ShellColor.Gold          ? "Gold"           :
            _shell == ShellColor.Rainbow       ? "Rainbow"        :
            _shell == ShellColor.Luminous      ? "Luminous"       : ""
        );
    }

    function _getSizeValue(EggSize _size) internal pure returns (string memory) {
        return (
            _size == EggSize.Tiny   ? "Tiny"   :
            _size == EggSize.Small  ? "Small"  :
            _size == EggSize.Normal ? "Normal" :
            _size == EggSize.Big    ? "Big"    : ""
        );
    }

    function _getMonthString(uint256 _month) internal pure returns (string memory) {
        return (
            _month ==  1 ? "JANUARY"   :
            _month ==  2 ? "FEBRUARY"  :
            _month ==  3 ? "MARCH"     :
            _month ==  4 ? "APRIL"     :
            _month ==  5 ? "MAY"       :
            _month ==  6 ? "JUNE"      :
            _month ==  7 ? "JULY"      :
            _month ==  8 ? "AUGUST"    :
            _month ==  9 ? "SEPTEMBER" :
            _month == 10 ? "OCTOBER"   :
            _month == 11 ? "NOVEMBER"  :
            _month == 12 ? "DECEMBER"  : ""
        );
    }

    function _formatDate(uint256 timestamp) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _getMonthString(BokkyPooBahsDateTimeLibrary.getMonth(timestamp)),
            ' ',
            BokkyPooBahsDateTimeLibrary.getDay(timestamp).toString(),
            ', ',
            BokkyPooBahsDateTimeLibrary.getYear(timestamp).toString()
        );
    }

    function _formatDecimal(uint256 decimal) internal pure returns (string memory) {
        return ((decimal + 0.5e18) / 1e18).toString();
    }

    function _getSVGStyle(BondData memory _bondData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<style>',
                '#cb-egg-', _bondData.tokenID.toString(), ' .cb-egg path {',
                    'animation: shake 3s infinite ease-out;',
                    'transform-origin: 50%;',
                '}',

                '@keyframes shake {',
                    '0% { transform: rotate(0deg); }',
                    '65% { transform: rotate(0deg); }',
                    '70% { transform: rotate(3deg); }',
                    '75% { transform: rotate(0deg); }',
                    '80% { transform: rotate(-3deg); }',
                    '85% { transform: rotate(0deg); }',
                    '90% { transform: rotate(3deg); }',
                    '100% { transform: rotate(0deg); }',
                '}',
            '</style>'
        );
    }

    function _getSVGDefCardDiagonalGradient(BondData memory _bondData) internal pure returns (bytes memory) {
        if (!_bondData.hasCardGradient) {
            return bytes('');
        }

        return abi.encodePacked(
            '<linearGradient id="cb-egg-', _bondData.tokenID.toString(), '-card-diagonal-gradient" y1="100%" gradientUnits="userSpaceOnUse">',
                '<stop offset="0" stop-color="', _bondData.cardGradient[0], '"/>',
                '<stop offset="1" stop-color="', _bondData.cardGradient[1], '"/>',
            '</linearGradient>'
        );
    }

    function _getSVGDefCardRadialGradient(BondData memory _bondData) internal pure returns (bytes memory) {
        if (_bondData.shellColor != ShellColor.Luminous) {
            return bytes('');
        }

        return abi.encodePacked(
            '<radialGradient id="cb-egg-', _bondData.tokenID.toString(), '-card-radial-gradient" cx="50%" cy="45%" r="38%" gradientUnits="userSpaceOnUse">',
                '<stop offset="0" stop-opacity="0"/>',
                '<stop offset="0.25" stop-opacity="0"/>',
                '<stop offset="1" stop-color="#000" stop-opacity="1"/>',
            '</radialGradient>'
        );
    }

    function _getSVGDefCardRainbowGradient(BondData memory _bondData) internal pure returns (bytes memory) {
        if (_bondData.cardColor != CardColor.Rainbow && _bondData.borderColor != BorderColor.Rainbow) {
            return bytes('');
        }

        return abi.encodePacked(
            '<linearGradient id="cb-egg-', _bondData.tokenID.toString(), '-card-rainbow-gradient" y1="100%" gradientUnits="userSpaceOnUse">',
                '<stop offset="0" stop-color="#93278f"/>',
                '<stop offset="0.2" stop-color="#662d91"/>',
                '<stop offset="0.4" stop-color="#3395d4"/>',
                '<stop offset="0.5" stop-color="#39b54a"/>',
                '<stop offset="0.6" stop-color="#fcee21"/>',
                '<stop offset="0.8" stop-color="#fbb03b"/>',
                '<stop offset="1" stop-color="#ed1c24"/>',
            '</linearGradient>'
        );
    }

    function _getSVGDefShellRainbowGradient(BondData memory _bondData) internal pure returns (bytes memory) {
        if (
            _bondData.shellColor != ShellColor.Rainbow &&
            !(_bondData.shellColor == ShellColor.Luminous && _bondData.cardColor == CardColor.Rainbow)
        ) {
            return bytes('');
        }

        return abi.encodePacked(
            '<linearGradient id="cb-egg-', _bondData.tokenID.toString(), '-shell-rainbow-gradient" x1="39%" y1="59%" x2="62%" y2="35%" gradientUnits="userSpaceOnUse">',
                '<stop offset="0" stop-color="#3fa9f5"/>',
                '<stop offset="0.38" stop-color="#39b54a"/>',
                '<stop offset="0.82" stop-color="#fcee21"/>',
                '<stop offset="1" stop-color="#fbb03b"/>',
            '</linearGradient>'
        );
    }

    function _getSVGDefs(BondData memory _bondData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<defs>',
                _getSVGDefCardDiagonalGradient(_bondData),
                _getSVGDefCardRadialGradient(_bondData),
                _getSVGDefCardRainbowGradient(_bondData),
                _getSVGDefShellRainbowGradient(_bondData),
            '</defs>'
        );
    }

    function _getSVGBorder(BondData memory _bondData) internal pure returns (bytes memory) {
        if (_bondData.shellColor == ShellColor.Luminous && _bondData.borderColor == BorderColor.Black) {
            // We will use the black radial gradient as border (covering the entire card)
            return bytes('');
        }

        return abi.encodePacked(
            '<rect ',
                _bondData.borderColor == BorderColor.Rainbow
                    ? abi.encodePacked('style="fill: url(#cb-egg-', _bondData.tokenID.toString(), '-card-rainbow-gradient)" ')
                    : abi.encodePacked('fill="', _bondData.solidBorderColor, '" '),
                'width="100%" height="100%" rx="37.5"',
            '/>'
        );
    }

    function _getSVGCard(BondData memory _bondData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _bondData.cardColor == CardColor.Rainbow && _bondData.borderColor == BorderColor.Rainbow
                ? bytes('') // Rainbow gradient already placed by border
                : abi.encodePacked(
                    '<rect ',
                        _bondData.cardColor == CardColor.Rainbow
                            ? abi.encodePacked('style="fill: url(#cb-egg-', _bondData.tokenID.toString(), '-card-rainbow-gradient)" ')
                            : _bondData.hasCardGradient
                            ? abi.encodePacked('style="fill: url(#cb-egg-', _bondData.tokenID.toString(), '-card-diagonal-gradient)" ')
                            : abi.encodePacked('fill="', _bondData.solidCardColor, '" '),
                        'x="30" y="30" width="690" height="990" rx="37.5"',
                    '/>'
                ),

            _bondData.cardColor == CardColor.Rainbow
                ? '<rect fill="#000" opacity="0.05" x="30" y="30" width="690" height="990" rx="37.5"/>'
                : ''
        );
    }

    function _getSVGCardRadialGradient(BondData memory _bondData) internal pure returns (bytes memory) {
        if (_bondData.shellColor != ShellColor.Luminous) {
            return bytes('');
        }

        return abi.encodePacked(
            '<rect ',
                'style="fill: url(#cb-egg-', _bondData.tokenID.toString(), '-card-radial-gradient); mix-blend-mode: hard-light" ',
                _bondData.borderColor == BorderColor.Black
                    ? 'width="100%" height="100%" '
                    : 'x="30" y="30" width="690" height="990" ',
                'rx="37.5"',
            '/>'
        );
    }

    function _getSVGShadowBelowEgg(BondData memory _bondData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<ellipse ',
                _bondData.shellColor == ShellColor.Luminous ? 'style="mix-blend-mode: luminosity" ' : '',
                'fill="#0a102e" ',
                _bondData.eggSize == EggSize.Tiny
                    ? 'cx="375" cy="560.25" rx="60" ry="11.4" '
                    : _bondData.eggSize == EggSize.Small
                    ? 'cx="375" cy="589.5" rx="80" ry="15.2" '
                    : _bondData.eggSize == EggSize.Big
                    ? 'cx="375" cy="648" rx="120" ry="22.8" '
                    // _bondData.eggSize == EggSize.Normal
                    : 'cx="375" cy="618.75" rx="100" ry="19" ',
            '/>'
        );
    }

    function _getSVGShellPathData(BondData memory _bondData) internal pure returns (string memory) {
        return _bondData.eggSize == EggSize.Tiny
            ? 'M293.86 478.12c0 45.36 36.4 82.13 81.29 82.13s81.29-36.77 81.29-82.13S420.05 365.85 375.15 365.85C332.74 365.85 293.86 432.76 293.86 478.12Z'
            : _bondData.eggSize == EggSize.Small
            ? 'M266.81 480c0 60.48 48.53 109.5 108.39 109.5s108.39-49.02 108.39-109.5S435.06 330.3 375.2 330.3C318.65 330.3 266.81 419.52 266.81 480Z'
            : _bondData.eggSize == EggSize.Big
            ? 'M212.71 483.74c0 90.72 72.79 164.26 162.59 164.26s162.59-73.54 162.59-164.26S465.1 259.2 375.3 259.2C290.47 259.2 212.71 393.02 212.71 483.74Z'
            // _bondData.eggSize == EggSize.Normal
            : 'M239.76 481.87c0 75.6 60.66 136.88 135.49 136.88s135.49-61.28 135.49-136.88S450.08 294.75 375.25 294.75C304.56 294.75 239.76 406.27 239.76 481.87Z';
    }

    function _getSVGHighlightPathData(BondData memory _bondData) internal pure returns (string memory) {
        return _bondData.eggSize == EggSize.Tiny
            ? 'M328.96 409.4c-6 13.59-5.48 29.53 3.25 36.11 9.76 7.35 23.89 9 36.98-3.13 12.57-11.66 23.48-43.94 1.24-55.5C358.25 380.55 335.59 394.35 328.96 409.4Z'
            : _bondData.eggSize == EggSize.Small
            ? 'M313.61 388.36c-8 18.12-7.3 39.38 4.33 48.16 13.01 9.8 31.85 12 49.31-4.18 16.76-15.54 31.3-58.59 1.65-74C352.66 349.9 322.45 368.3 313.61 388.36Z'
            : _bondData.eggSize == EggSize.Big
            ? 'M282.91 346.3c-12 27.18-10.96 59.06 6.51 72.22 19.51 14.7 47.77 18 73.95-6.26 25.14-23.32 46.96-87.89 2.49-111C341.5 288.6 296.17 316.2 282.91 346.3Z'
            // _bondData.eggSize == EggSize.Normal
            : 'M298.26 367.33c-10 22.65-9.13 49.22 5.42 60.19 16.26 12.25 39.81 15 61.63-5.22 20.95-19.43 39.13-73.24 2.07-92.5C347.08 319.25 309.31 342.25 298.26 367.33Z';
    }

    function _getSVGSelfShadowPathData(BondData memory _bondData) internal pure returns (string memory) {
        return _bondData.eggSize == EggSize.Tiny
            ? 'M416.17 385.02c11.94 20.92 19.15 45.35 19.14 65.52 0 45.36-36.4 82.13-81.3 82.13a80.45 80.45 0 0 1-52.52-19.45C314.52 541.03 342.54 560.27 375 560.27c44.9 0 81.3-36.77 81.3-82.13C456.31 447.95 440.18 408.22 416.17 385.02Z'
            : _bondData.eggSize == EggSize.Small
            ? 'M429.89 355.86c15.92 27.89 25.53 60.46 25.53 87.36 0 60.48-48.54 109.5-108.4 109.5a107.26 107.26 0 0 1-70.03-25.92C294.36 563.88 331.72 589.52 375 589.52c59.86 0 108.4-49.02 108.4-109.5C483.42 439.76 461.91 386.8 429.89 355.86Z'
            : _bondData.eggSize == EggSize.Big
            ? 'M457.33 297.54c23.88 41.83 38.29 90.7 38.29 131.04 0 90.72-72.8 164.26-162.6 164.26a160.9 160.9 0 0 1-105.03-38.9C254.04 609.56 310.08 648.04 375 648.04c89.8 0 162.6-73.54 162.6-164.26C537.62 423.4 505.37 343.94 457.33 297.54Z'
            // _bondData.eggSize == EggSize.Normal
            : 'M443.61 326.7c19.9 34.86 31.91 75.58 31.91 109.2 0 75.6-60.67 136.88-135.5 136.88a134.08 134.08 0 0 1-87.53-32.41C274.2 586.72 320.9 618.78 375 618.78c74.83 0 135.5-61.28 135.5-136.88C510.52 431.58 483.64 365.37 443.61 326.7Z';
    }

    function _getSVGEgg(BondData memory _bondData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<g class="cb-egg">',
                '<path ',
                    _bondData.shellColor == ShellColor.Rainbow ||
                    _bondData.shellColor == ShellColor.Luminous && _bondData.cardColor == CardColor.Rainbow
                        ? abi.encodePacked('style="fill: url(#cb-egg-', _bondData.tokenID.toString(), '-shell-rainbow-gradient)" ')
                        : _bondData.isBlendedShell
                        ? bytes('style="mix-blend-mode: luminosity" fill="#e5eff9" ')
                        : abi.encodePacked('fill="', _bondData.solidShellColor, '" '),
                    'd="', _getSVGShellPathData(_bondData), '"',
                '/>',

                '<path style="mix-blend-mode: soft-light" fill="#fff" d="', _getSVGHighlightPathData(_bondData), '"/>',
                '<path style="mix-blend-mode: soft-light" fill="#000" d="', _getSVGSelfShadowPathData(_bondData), '"/>',
            '</g>'
        );
    }

    function _getSVGText(BondData memory _bondData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<text fill="#fff" font-family="''Arial Black'', Arial" font-size="72px" font-weight="800" text-anchor="middle" x="50%" y="14%">LUSD</text>',

            '<text fill="#fff" font-family="''Arial Black'', Arial" font-size="30px" font-weight="800" text-anchor="middle" x="50%" y="19%">',
                'ID: ', _bondData.tokenID.toString(),
            '</text>',

            '<text fill="#fff" font-family="''Arial Black'', Arial" font-size="40px" font-weight="800" text-anchor="middle" x="50%" y="72%">BOND AMOUNT</text>',

            '<text fill="#fff" font-family="''Arial Black'', Arial" font-size="64px" font-weight="800" text-anchor="middle" x="50%" y="81%">',
                _formatDecimal(_bondData.lusdAmount),
            '</text>',

            '<text fill="#fff" font-family="''Arial Black'', Arial" font-size="30px" font-weight="800" text-anchor="middle" x="50%" y="91%" opacity="0.6">',
                _formatDate(_bondData.startTime),
            '</text>'
        );
    }

    function _getSVG(BondData memory _bondData) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 750 1050">',
                _getSVGStyle(_bondData),
                _getSVGDefs(_bondData),

                '<g id="cb-egg-', _bondData.tokenID.toString(), '">',
                    _getSVGBorder(_bondData),
                    _getSVGCard(_bondData),
                    _getSVGCardRadialGradient(_bondData),
                    _getSVGShadowBelowEgg(_bondData),
                    _getSVGEgg(_bondData),
                    _getSVGText(_bondData),
                '</g>',
            '</svg>'
        );
    }
}