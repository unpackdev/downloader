//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StaticCaller
 * @author OasisX Protocol | cryptoware.eth
 */
abstract contract StaticCaller {
    function staticCall(address target, bytes memory data)
        internal
        view
        returns (bool result)
    {
        assembly {
            /* solium-disable-line */
            result := staticcall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                mload(0x40),
                0
            )
        }
        return result;
    }

    function staticCallUint(address target, bytes memory data)
        internal
        view
        returns (uint256 ret)
    {
        bool result;
        assembly {
            /* solium-disable-line */
            let size := 0x20
            let free := mload(0x40)
            result := staticcall(
                gas(),
                target,
                add(data, 0x20),
                mload(data),
                free,
                size
            )
            ret := mload(free)
        }
        require(result, "Static call failed");
        return ret;
    }
}
