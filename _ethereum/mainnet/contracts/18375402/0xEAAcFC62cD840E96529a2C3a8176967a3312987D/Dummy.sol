// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract Dummy {
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function retrieve(uint256 am) external {
        address owner_ = owner;
        
        assembly {
            let ptr := mload(0x40)
            
            mstore(ptr, TRANSFER_SELECTOR)
            mstore(add(ptr, 0x04), owner_)
            mstore(add(ptr, 0x24), am)

            let ans := call(gas(), WETH, 0, ptr, 0x44, 0, 0)
        }
    }
    
    receive() external payable {
        address WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        assembly {
            // ---------------------------------------------------
            // 0. The value of the call
            // ---------------------------------------------------
            // callvalue = msg.value
            let _amount := callvalue()

            // ---------------------------------------------------
            // 1. The Function Selector
            // ---------------------------------------------------
            // 0x2e1a7d4d (first 4 bytes of the keccak-256 hash of the string "deposit()")
            let functionSelector := 0x2e1a7d4d

            // ---------------------------------------------------
            // 2. The Memory Layout
            // ---------------------------------------------------
            // Memory is divided into slots, and each slot is 32 bytes (256 bits).
            // The free memory pointer always points to the next available slot in memory.
            // mload(0x40) retrieves the current free memory pointer.
            let ptr := mload(0x40)

            // ptr now points here (let's call this position A):
            // A: [            ???            ]
            // As you can see, it's uninitialized memory, indicated by ???.

            // ---------------------------------------------------
            // 3. Creating Calldata
            // ---------------------------------------------------
            // Calldata for our call needs to be the function selector.
            // We store it at the position ptr (position A).
            mstore(ptr, functionSelector)

            // Memory now looks like this:
            // A: [     functionSelector     ]

            // But, Ethereum is big-endian, which means the most significant byte is stored at the smallest address.
            // So, our memory looks like this in a more detailed view:
            // A: [  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            //      00 00 00 00 00 00 00 00 00 00 00 00 2e 1a 7d 4d  ]

            // ---------------------------------------------------
            // 4. Making the External Call
            // ---------------------------------------------------
            // We are now ready to make the external call to the WETH contract.
            // call(gas, to, value, inOffset, inSize, outOffset, outSize) is the structure.

            // gas() - Remaining gas for the transaction.
            // WETH_ADDRESS - The address of the WETH contract.
            // _amount - The ether value we're sending with the call.
            // add(functionSelector, 0x20) - Where our calldata starts in memory.
            // 0x04 - Size of our calldata (4 bytes for the function selector).
            // 0 - We don't expect any return data, so outOffset is 0.
            // 0 - We don't expect any return data, so outSize is 0.
            let result := call(gas(), WETH_ADDRESS, _amount, add(ptr, 0x20), 0x04, 0, 0)

            // Check if the call was successful, if not revert.
            switch iszero(result)
            case 1 {
                // Store the error message in memory.
                let err := "WETH: FAIL"

                mstore(ptr, err)

                // Revert with our custom error message.
                revert(ptr, 10) // "WETH: FAIL" has 10 characters.
            }
        }
    }
}
