// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity =0.8.9;

import "./IUSDV.sol";

interface IUnlockValidator {
    function isValid(
        address user,
        uint256 amount,
        IUSDV.LockTypes lockType
    ) external view returns (bool);

    event Invalidate(address account);
    event Validate(address account);
}
