// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IHegicOptions {
    event Create(
        uint256 indexed id,
        address indexed account,
        uint256 settlementFee,
        uint256 totalFee
    );

    enum State {Inactive, Active, Exercised, Expired}
    enum OptionType {Invalid, Put, Call}
    
    function impliedVolRate() external view returns(uint);

    function create(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionType optionType
    )
        external
        payable
        returns (uint256 optionID);

    function transfer(uint256 optionID, address payable newHolder) external;

    function exercise(uint256 optionID) external;

    function options(uint) external view returns (
        State state,
        address payable holder,
        uint256 strike,
        uint256 amount,
        uint256 lockedAmount,
        uint256 premium,
        uint256 expiration,
        OptionType optionType
    );

    function unlock(uint256 optionID) external;
}

interface IHegicETHOptions is IHegicOptions {
        function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionType optionType
    )
        external
        view
        returns (
            uint256 total,
            uint256 settlementFee,
            uint256 strikeFee,
            uint256 periodFee
        );
}

interface IHegicERC20Options is IHegicOptions {
    function fees(
        uint256 period,
        uint256 amount,
        uint256 strike,
        OptionType optionType
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
}
