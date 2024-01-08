// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// https://eips.ethereum.org/EIPS/eip-1822
contract FundProxy {
    constructor(bytes memory _constructData, address _fundLogic) public {
        assembly {
            // solium-disable-line
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _fundLogic)
            // Genesis proxy flag
            sstore(0xa7e8032f370433e2cd75389d33b731b61bee456da1b0f7117f2621cbd1fdcf7a, true)
        }

        (bool success, bytes memory returnData) = _fundLogic.delegatecall(_constructData);
        require(success, string(returnData));
    }

    fallback() external payable {
        assembly {
            // solium-disable-line
            let contractLogic := sload(
                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
            )
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}