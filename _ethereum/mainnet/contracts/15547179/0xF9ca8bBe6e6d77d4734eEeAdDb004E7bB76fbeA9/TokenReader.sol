pragma solidity 0.4.24;
import "./DetailedERC20.sol";

/**
 * @title TokenReader
 * @dev Helper methods for reading name/symbol/decimals parameters from ERC20 token contracts.
 */
library TokenReader {
    bytes4 private constant _NAME = 0x06fdde03; // web3.eth.abi.encodeFunctionSignature("name()")
    bytes4 private constant _NAME_CAPS = 0xa3f4df7e; // web3.eth.abi.encodeFunctionSignature("NAME()")
    bytes4 private constant _SYMBOL = 0x95d89b41; // web3.eth.abi.encodeFunctionSignature("symbol")
    bytes4 private constant _SYMBOL_CAPS = 0xf76f8d78; // web3.eth.abi.encodeFunctionSignature("SYMBOL()")
    bytes4 private constant _DECIMALS = 0x313ce567; // web3.eth.abi.encodeFunctionSignature("decimals()")
    bytes4 private constant _DECIMALS_CAPS = 0x2e0f2625; // web3.eth.abi.encodeFunctionSignature("DECIMALS()")
    bytes4 private constant _TOTAL_SUPPLY = 0x18160ddd; // web3.eth.abi.encodeFunctionSignature("totalSupply()")
    bytes4 private constant _TOKEN_URI = 0xc87b56dd; // web3.eth.abi.encodeFunctionSignature("tokenURI(uint256)")

    /**
    * @dev Reads the name property of the provided token.
    * Either name() or NAME() method is used.
    * Both, string and bytes32 types are supported.
    * @param _token address of the token contract.
    * @return token name as a string or an empty string if none of the methods succeeded.
    */
    function readName(address _token) internal view returns (string) {
        return _readStringWithFallback(_token, _NAME, _NAME_CAPS);
    }

    /**
    * @dev Reads the symbol property of the provided token.
    * Either symbol() or SYMBOL() method is used.
    * Both, string and bytes32 types are supported.
    * @param _token address of the token contract.
    * @return token symbol as a string or an empty string if none of the methods succeeded.
    */
    function readSymbol(address _token) internal view returns (string) {
        return _readStringWithFallback(_token, _SYMBOL, _SYMBOL_CAPS);
    }

    /**
    * @dev Reads the decimals property of the provided token.
    * Either decimals() or DECIMALS() method is used.
    * @param _token address of the token contract.
    * @return token decimals or 0 if none of the methods succeeded.
    */
    function readDecimals(address _token) internal view returns (uint256) {
        return _readIntWithFallback(_token, _DECIMALS, _DECIMALS_CAPS);
    }

    function readTotalSupply(address _token) internal view returns (uint256) {
        return _readIntFunctionThatMightNotExist(_token, _TOTAL_SUPPLY);
    }

    function readTokenURI(address _token, uint256 _tokenId) internal view returns (string) {
        bytes memory encodedParams = abi.encodeWithSelector(_TOKEN_URI, _tokenId);
        return _dynamicStringMethodCall(_token, encodedParams);
    }

    function _readStringWithFallback(address _contract, bytes4 _selector1, bytes4 _selector2)
        internal
        view
        returns (string)
    {
        string memory firstResult = _readStringFunctionThatMightNotExist(_contract, _selector1);

        if (bytes(firstResult).length > 0) {
            return firstResult;
        }

        return _readStringFunctionThatMightNotExist(_contract, _selector2);
    }

    function _readIntWithFallback(address _contract, bytes4 _selector1, bytes4 _selector2)
        internal
        view
        returns (uint256)
    {
        uint256 firstResult = _readIntFunctionThatMightNotExist(_contract, _selector1);

        if (firstResult > 0) {
            return firstResult;
        }

        return _readIntFunctionThatMightNotExist(_contract, _selector2);
    }

    function _readStringFunctionThatMightNotExist(address _contract, bytes4 _selector) internal view returns (string) {
        bytes memory encodedParams = abi.encodeWithSelector(_selector);
        return _dynamicStringMethodCall(_contract, encodedParams);
    }

    function _dynamicStringMethodCall(address _contract, bytes encodedParams) internal view returns (string) {
        uint256 ptr;
        uint256 size;

        assembly {
            let encodedParams_data := add(0x20, encodedParams)
            let encodedParams_size := mload(encodedParams)

            ptr := mload(0x40)
            staticcall(gas, _contract, encodedParams_data, encodedParams_size, ptr, 32)
            pop
            mstore(0x40, add(ptr, returndatasize))

            switch gt(returndatasize, 32)
                case 1 {
                    returndatacopy(mload(0x40), 32, 32) // string length
                    size := mload(mload(0x40))
                }
                default {
                    size := returndatasize // 32 or 0
                }
        }
        string memory res = new string(size);
        assembly {
            if gt(returndatasize, 32) {
                // load as string
                returndatacopy(add(res, 32), 64, size)
                jump(exit)
            }
            // solhint-disable
            if gt(returndatasize, 0) {
                let i := 0
                ptr := mload(ptr) // load bytes32 value
                mstore(add(res, 32), ptr) // save value in result string

                for {

                } gt(ptr, 0) {
                    i := add(i, 1)
                } {
                    // until string is empty
                    ptr := shl(8, ptr) // shift left by one symbol
                }
                mstore(res, i) // save result string length
            }
            exit:


            // solhint-enable

        }
        return res;
    }

    function _readIntFunctionThatMightNotExist(address _contract, bytes4 selector) internal view returns (uint256) {
        uint256 decimals;
        // bytes32 nameBytes = _encodeMethodSignature();
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 32))
            mstore(ptr, selector)
            if iszero(staticcall(gas, _contract, ptr, 4, ptr, 32)) {
                mstore(ptr, 0)
            }
            decimals := mload(ptr)
        }
        return decimals;
    }
}
