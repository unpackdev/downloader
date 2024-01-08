// SPDX-License-Identifier: MIT
pragma solidity ^0.5.3;

/// @title Proxy - GSVE  proxy contract allows to execute all transactions applying the code of a master contract and then burning a gas token.
/// @author Stefan George - <stefan@gnosis.io>
/// @author Richard Meissner - <richard@gnosis.io>
/// @author Gas Save Protocol - <GasSave.org>

interface IGasToken {
    /**
     * @dev return number of tokens freed up.
     */
    function freeFromUpTo(address from, uint256 value) external returns (uint256); 
}

/**
* @dev interface to allow gsve to be burned for upgrades
*/
interface IBeacon {
    function getAddressGastoken(address safe) external view returns(address);
    function getAddressGasTokenSaving(address safe) external view returns(uint256);
}

contract Proxy {

    // masterCopy always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal masterCopy;

    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    function () 
        external
        payable
    {
        uint256 gasStart = gasleft();
        uint256 returnDataLength;
        bool success;
        bytes memory returndata;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }

            //set returndata to the location of the free data pointer
            returndata := mload(0x40)
            calldatacopy(0, 0, calldatasize())
            success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)

            //copy the return data and then MOVE the free data pointer to avoid overwriting. Without this movement, the operation reverts.
            //ptr movement amount is probably overkill and wastes a few hundred gas for no reason, but better to be safe!
            returndatacopy(returndata, 0, returndatasize())
            returnDataLength:= returndatasize()
            mstore(0x40, add(0x40, add(0x200, mul(returndatasize(), 0x20)))) 
        }

        //work out how much gas we've spent so far
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        
        //if the gas amount is low, then don't burn anything and finish the proxy operation
        if(gasSpent < 48000){
            assembly{
                if eq(success, 0) { revert(returndata, returnDataLength) }
                return(returndata, returnDataLength)
            }
        }
        //if the operation has been expensive, then look at burning gas tokens
        else{
            //query the beacon to see what gas token the user want's to burn
            IBeacon beacon = IBeacon(0x1370CAf8181771871cb493DFDC312cdeD17a2de8);
            address gsveBeaconGastoken = beacon.getAddressGastoken(address(this));
            if(gsveBeaconGastoken == address(0)){
                assembly{
                    if eq(success, 0) { revert(returndata, returnDataLength) }
                    return(returndata, returnDataLength)
                }
            }
            else{
                uint256 gsveBeaconAmount = beacon.getAddressGasTokenSaving(gsveBeaconGastoken);
                gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
                IGasToken(gsveBeaconGastoken).freeFromUpTo(msg.sender,  (gasSpent + 16000) / gsveBeaconAmount);
                assembly{
                    if eq(success, 0) { revert(returndata, returnDataLength) }
                    return(returndata, returnDataLength)
                }
            }
        }
    }
}
