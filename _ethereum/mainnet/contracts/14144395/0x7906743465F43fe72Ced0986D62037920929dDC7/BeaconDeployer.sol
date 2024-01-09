/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title BeaconDeployer
 * @author yoonsung.eth
 * @notice library that deploy Beacon contract.
 */
library BeaconDeployer {
    function deploy(address implementation) internal returns (address result) {
        bytes memory code = abi.encodePacked(
            hex"606161002960003933600081816002015260310152602080380360803960805160005560616000f3fe337f00000000000000000000000000000000000000000000000000000000000000001415602e57600035600055005b337f00000000000000000000000000000000000000000000000000000000000000001460605760005460005260206000f35b",
            abi.encode(implementation)
        );

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := create(0, add(code, 0x20), mload(code))

            // pass along failure message from failed contract deployment and revert.
            if iszero(extcodesize(result)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}
