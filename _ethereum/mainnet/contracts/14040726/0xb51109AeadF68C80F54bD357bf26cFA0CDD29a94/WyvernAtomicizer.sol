/*

  << Wyvern Atomicizer >>

  Execute multiple transactions, in order, atomically (if any fails, all revert).

*/

pragma solidity 0.7.5;

import "./ArrayUtils.sol";

/**
 * @title WyvernAtomicizer
 * @author Wyvern Protocol Developers
 */
library WyvernAtomicizer {

    function atomicize (address[] calldata addrs, uint[] calldata values, uint[] calldata calldataLengths, bytes calldata calldatas)
        external
    {
        require(addrs.length == values.length && addrs.length == calldataLengths.length, "Addresses, calldata lengths, and values must match in quantity");

        uint j = 0;
        for (uint i = 0; i < addrs.length; i++) {
            bytes memory cd = new bytes(calldataLengths[i]);
            for (uint k = 0; k < calldataLengths[i]; k++) {
                cd[k] = calldatas[j];
                j++;
            }
            (bool success,) = addrs[i].call{value: values[i]}(cd);
            require(success, "Atomicizer subcall failed");
        }
    }

    // Transfer bundle assets since the amount of assets is dynamic.
    function atomicizeCustom (address[] calldata addrs, uint[] calldata values, uint[] calldata calldataLengths, bytes calldata calldatas)
        external
    {
        require(addrs.length == values.length && addrs.length == calldataLengths.length, "Addresses, calldata lengths, and values must match in quantity");

        uint start = 0;
        for (uint i = 0; i < addrs.length; i++) {
            if (i > 0) {
                start += calldataLengths[i - 1];
            }

            bytes memory cd = ArrayUtils.arraySlice(calldatas, start, calldataLengths[i]);
            (bool success,) = addrs[i].call{value: values[i]}(cd);
            require(success, "Atomicizer subcall failed");
        }
    }

    function atomicize1 (address addr, uint256 value, bytes calldata data) external {
        uint amount = value;
        if (msg.value != 0) {
            amount = msg.value;
        }
        (bool success,) = addr.call{value: amount}(data);
        require(success, "Atomicizer1 call failed");
    }

    function atomicize2 (address[] calldata addrs, uint[] calldata values, bytes calldata calldata0, bytes calldata calldata1) external {
        require(addrs.length == values.length && addrs.length == 2, "Addresses and values must match in quantity 2");

        (bool success,) = addrs[0].call{value: values[0]}(calldata0);
        require(success, "Atomicizer2 firstcall failed");

        (success,) = addrs[1].call{value: values[1]}(calldata1);
        require(success, "Atomicizer2 secondcall failed");
    }

    function atomicize3 (address[] calldata addrs, uint[] calldata values,
        bytes calldata calldata0, bytes calldata calldata1, bytes calldata calldata2) external {
        require(addrs.length == values.length && addrs.length == 3, "Addresses and values must match in quantity 3");

        (bool success,) = addrs[0].call{value: values[0]}(calldata0);
        require(success, "Atomicizer3 firstcall failed");

        (success,) = addrs[1].call{value: values[1]}(calldata1);
        require(success, "Atomicizer3 secondcall failed");

        (success,) = addrs[2].call{value: values[2]}(calldata2);
        require(success, "Atomicizer3 thirdcall failed");
    }

    function atomicize4 (address[] calldata addrs, uint[] calldata values, bytes calldata calldata0,
        bytes calldata calldata1, bytes calldata calldata2, bytes calldata calldata3) external {
        require(addrs.length == values.length && addrs.length == 4, "Addresses and values must match in quantity 4");

        (bool success,) = addrs[0].call{value: values[0]}(calldata0);
        require(success, "Atomicizer4 firstcall failed");

        (success,) = addrs[1].call{value: values[1]}(calldata1);
        require(success, "Atomicizer4 secondcall failed");

        (success,) = addrs[2].call{value: values[2]}(calldata2);
        require(success, "Atomicizer4 thirdcall failed");

        (success,) = addrs[3].call{value: values[3]}(calldata3);
        require(success, "Atomicizer4 forthcall failed");
    }
}
