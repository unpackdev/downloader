/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title BeaconMakerWithCall
 * @author yoonsung.eth
 * @notice Beacon Minimal Proxy를 배포하는 기능을 가진 Maker Dummy
 * @dev template에는 단 한번만 호출 가능한 initialize 함수가 필요하며, 이는 필수적으로 호출되어 과정이 생략되어야 함.
 */
contract BeaconMakerWithCall {
    /**
     * @param beacon call 했을 경우, 주소가 반환되어야 함
     * @param initializationCalldata template로 배포할 때 초기화 할 함수
     */
    constructor(address beacon, bytes memory initializationCalldata) payable {
        (, bytes memory returnData) = beacon.staticcall("");
        address template = abi.decode(returnData, (address));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = template.delegatecall(initializationCalldata);
        if (!success) {
            // pass along failure message from delegatecall and revert.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Beacon Address
        bytes20 targetBytes = bytes20(beacon);
        // place Beacon Proxy code in memory.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d3d3d3d3d730000000000000000000000000000000000000000000000000000)
            mstore(add(clone, 0x6), targetBytes)
            mstore(add(clone, 0x1a), 0x5afa3d82803e368260203750808036602082515af43d82803e903d91603a57fd)
            mstore(add(clone, 0x3a), 0x5bf3000000000000000000000000000000000000000000000000000000000000)
            // return Beacon Minimal Proxy code to write it to spawned contract runtime.
            return(add(0x00, clone), 0x3c) // Beacon Minimal Proxy runtime code, length
        }
    }
}
