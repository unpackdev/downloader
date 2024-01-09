/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title MinimalMaker
 * @author yoonsung.eth
 * @notice Minimal Proxy를 배포하는 기능을 가진 Maker Dummy
 * @dev template에는 단 한번만 호출 가능한 initialize 함수가 필요하며, 이는 필수적으로 호출되어 과정이 생략되어야 함.
 */
contract MinimalMaker {
    constructor(address template) payable {
        // Template Address
        bytes20 targetBytes = bytes20(template);
        // place Minimal Proxy eip-1167 code in memory.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            // return eip-1167 code to write it to spawned contract runtime.
            return(add(0x00, clone), 0x2d) // eip-1167 runtime code, length
        }
    }
}
