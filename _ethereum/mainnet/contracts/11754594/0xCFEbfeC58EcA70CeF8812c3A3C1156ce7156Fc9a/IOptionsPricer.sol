// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12; 

import "./IHegicOptions.sol";

interface IOptionsPricer {
    
    function getOptionPrice(uint tokenId) external view returns (uint);
    function getOptionPriceWithParams(
        uint strike,
        uint expiration,
        uint amount,
        IHegicOptions.OptionType optionType
    ) external view returns (uint);
}