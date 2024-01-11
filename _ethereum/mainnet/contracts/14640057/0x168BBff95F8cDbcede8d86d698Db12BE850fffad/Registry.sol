//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;
import "./Ownable.sol";
import "./Storage.sol";

contract Registry is Storage, Ownable {
    address public logicContract;

    function setLogicContract(address _c)
        public
        onlyOwner
        returns (bool success)
    {
        logicContract = _c;
        return true;
    }

    function _fallback() internal virtual {
        _delegate(logicContract);
    }

    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}
