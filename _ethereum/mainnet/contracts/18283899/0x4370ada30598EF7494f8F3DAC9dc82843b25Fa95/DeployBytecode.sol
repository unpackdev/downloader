// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8;



/*
* @author Forkswap.org
* @notice Smart contract that let's you deploy other smart contracts using bytecode.
*/

contract DeployBytecode {


    receive() external payable {}

    mapping(address => address) public contractCreators;

    event DeployContract(address indexed owner, address smartcontract, string website);


    /* 
    * Given a bytecode and website, deploy a smart contract. Your smart contract constructor can be payable
    * but shouldn't have any arguments in constructor. You can bypass arguments via invokeMethod below
    */
    function deployFromBytecode(bytes memory bytecode, string memory website) payable public returns (address) {
        address child;
        uint256 val = msg.value;
        assembly{
            mstore(0x0, bytecode)
            // create(value, offset, size)
            child := create(val,0xa0, calldatasize())
        }
        require(child != address(0), 'wrong call');
        contractCreators[child] = msg.sender;
        emit DeployContract(msg.sender, child, website);
        return child;
   }


    /*
    *   Invoke any smart contract method as long as you've deployed it. 
    *   Can be used for changing ownerships or similar. 
    */
   function invokeMethod(address destination, bytes memory data) payable public returns (bool){
        require(contractCreators[destination] == msg.sender, 'wrong call');
        if (external_call(destination, msg.value, data.length, data)){
            return true;
        } else {
            return false;
        }
   }


    // REFERENCE: Gnosis Safe <3 
    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes memory data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas(), 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}