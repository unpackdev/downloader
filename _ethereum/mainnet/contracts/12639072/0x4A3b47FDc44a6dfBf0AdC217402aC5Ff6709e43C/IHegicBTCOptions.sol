// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IHegicOptionTypes.sol";

interface IHegicBTCOptions is IHegicOptionTypes {
    function priceProvider() external view returns (address);

    function impliedVolRate() external view returns (uint256);

    enum State {Inactive, Active, Exercised, Expired}

    function exercise(uint256 optionID) external;

    function options(uint256)
        external
        view
        returns (
            State state,
            address payable holder,
            uint256 strike,
            uint256 amount,
            uint256 lockedAmount,
            uint256 premium,
            uint256 expiration,
            IHegicOptionTypes.OptionType optionType
        );

    struct Option {
        State state;
        address payable holder;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        IHegicOptionTypes.OptionType optionType;
    }

    function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
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

    function create(
        uint256 period,
        uint256 amount,
        uint256 strike,
        IHegicOptionTypes.OptionType optionType
    ) external payable returns (uint256 optionID);

    function transfer(uint256 optionID, address payable newHolder) external;
}
