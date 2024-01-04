// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "./IHegicOptions.sol";

interface IOptionsBuyer {
    event BuyOption(
        address account,
        uint tokenId,
        uint strike,
        uint expiration,
        uint amount,
        IHegicOptions.OptionType optionType,
        uint premium
    );

    function getOptionPrice(uint tokenId) external view returns (uint);

    function sellOption(uint tokenId) external;
}