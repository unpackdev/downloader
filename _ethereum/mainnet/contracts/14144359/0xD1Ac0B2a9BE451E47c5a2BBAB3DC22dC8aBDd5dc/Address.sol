/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

library Address {
    function isContract(address target) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := gt(extcodesize(target), 0)
        }
    }
}
