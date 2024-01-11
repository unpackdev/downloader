//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IValidator.sol";

interface IBonusProgram is IValidator {
    function description() external pure returns (string memory);
    function bonusAmount(uint256 num) external pure returns (uint256);

    function onPurchase(address owner, uint256 num) external;
}
