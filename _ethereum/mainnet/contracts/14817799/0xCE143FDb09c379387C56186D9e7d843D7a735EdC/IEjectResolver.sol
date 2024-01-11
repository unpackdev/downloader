// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "./SEject.sol";

interface IEjectResolver {
    function checker(
        uint256,
        Order memory order,
        address feeToken_
    ) external view returns (bool, bytes memory);
}
