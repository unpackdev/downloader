// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Float.sol";

interface IDiscountProfile {
    function discount(address _user) external view returns (float memory);
}
