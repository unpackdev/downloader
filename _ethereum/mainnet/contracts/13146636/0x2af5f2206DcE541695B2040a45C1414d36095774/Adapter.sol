// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import "./IERC20.sol";

abstract contract Adapter {
    //
    //  _       _                        _
    // (_)_ __ | |_ ___ _ __ _ __   __ _| |___
    // | | '_ \| __/ _ \ '__| '_ \ / _` | / __|
    // | | | | | ||  __/ |  | | | | (_| | \__ \
    // |_|_| |_|\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Perform an internal option purchase
    /// @param caller Address purchasing the option
    /// @param currencies List of usable currencies
    /// @param amounts List of usable currencies amounts
    /// @param data Extra data usable by adapter
    /// @return A tuple containing used amounts and output data
    function purchase(
        address caller,
        address[] memory currencies,
        uint256[] memory amounts,
        bytes calldata data
    ) internal virtual returns (uint256[] memory, bytes memory);

    function _preparePayment(address[] memory currencies, uint256[] memory amounts) internal {
        require(currencies.length == amounts.length, 'A2');
        for (uint256 currencyIdx = 0; currencyIdx < currencies.length; ++currencyIdx) {
            if (currencies[currencyIdx] == address(0)) {
                require(msg.value >= amounts[currencyIdx], 'A1');
            } else {
                require(
                    IERC20(currencies[currencyIdx]).transferFrom(msg.sender, address(this), amounts[currencyIdx]),
                    'A2'
                );
            }
        }
    }

    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    /// @dev Perform an option purchase
    /// @param caller Address purchasing the option
    /// @param currencies List of usable currencies
    /// @param amounts List of usable currencies amounts
    /// @param data Extra data usable by adapter
    /// @return A tuple containing used amounts and output data
    function run(
        address caller,
        address[] memory currencies,
        uint256[] memory amounts,
        bytes calldata data
    ) external payable returns (uint256[] memory, bytes memory) {
        _preparePayment(currencies, amounts);
        return purchase(caller, currencies, amounts, data);
    }

    function name() external view virtual returns (string memory);
}
