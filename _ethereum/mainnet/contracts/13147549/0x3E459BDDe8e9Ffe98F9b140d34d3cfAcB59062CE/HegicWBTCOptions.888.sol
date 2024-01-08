// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import "./OptionType.888.sol";

interface HegicWBTCOptionsV888 {
    //
    //            _                        _
    //   _____  _| |_ ___ _ __ _ __   __ _| |___
    //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
    // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
    //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
    //

    function create(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionTypeV888.OptionType optionType
    ) external payable returns (uint256 optionID);

    function transfer(uint256 optionID, address payable newHolder) external;

    function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionTypeV888.OptionType optionType
    )
        external
        view
        returns (
            uint256 total,
            uint256 totalETH,
            uint256 settlementFee,
            uint256 strikeFee,
            uint256 periodFee
        );

    function wbtc() external view returns (address);
}
