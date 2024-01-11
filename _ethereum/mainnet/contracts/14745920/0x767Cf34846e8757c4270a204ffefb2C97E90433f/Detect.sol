// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC721.sol";

contract Detect {
    enum TokenType { ERC20, ERC721, Invalid }

    // getting these ERC165 id's from https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md#specification
    bytes4 private constant _ERC721_EIP165ID = 0x80ac58cd;
    bytes4 private constant _ERC721_TOKENRECEIVER_EIP165ID = 0x150b7a02;
    bytes4 private constant _ERC721_METADATA_EIP165ID = 0x5b5e139f;
    bytes4 private constant _ERC721_ENUMERABLE_EIP165ID = 0x780e9d63;

    bytes private constant _ENCODED_ERC20_DECIMALS =
        abi.encodeWithSignature("decimals()");
    bytes private constant _ENCODED_ERC20_TOTAL_SUPPLY =
        abi.encodeWithSignature("totalSupply()");
    bytes private constant _ENCODED_ERC20_ALLOWANCE =
        abi.encodeWithSignature(
            "allowance(address,address)",
            address(0),
            address(0)
        );
    bytes private constant _ENCODED_ERC721_EIP165ID =
        abi.encodeWithSignature("supportsInterface(bytes4)", _ERC721_EIP165ID);
    bytes private constant _ENCODED_ERC721_TOKENRECEIVER_EIP165ID =
        abi.encodeWithSignature(
            "supportsInterface(bytes4)",
            _ERC721_TOKENRECEIVER_EIP165ID
        );
    bytes private constant _ENCODED_ERC721_METADATA_EIP165ID =
        abi.encodeWithSignature(
            "supportsInterface(bytes4)",
            _ERC721_METADATA_EIP165ID
        );
    bytes private constant _ENCODED_ERC721_ENUMERABLE_EIP165ID =
        abi.encodeWithSignature(
            "supportsInterface(bytes4)",
            _ERC721_ENUMERABLE_EIP165ID
        );

    function isERC20(address contractAddress, uint256 gasLimit)
        public
        view
        returns (bool)
    {
        (bool successDecimals, bytes memory data1) =
            contractAddress.staticcall{ gas: gasLimit }(
                _ENCODED_ERC20_DECIMALS
            );

        (bool successERC20Allowance, bytes memory data2) =
            contractAddress.staticcall{ gas: gasLimit }(
                _ENCODED_ERC20_ALLOWANCE
            );
        return ((successDecimals && data1.length > 0) ||
            (successERC20Allowance && data2.length > 0));
    }

    function isERC721(address contractAddress, uint256 gasLimit)
        public
        view
        returns (bool)
    {
        (bool successERC721, bytes memory data1) =
            contractAddress.staticcall{ gas: gasLimit }(
                _ENCODED_ERC721_EIP165ID
            );
        (bool successERC721TokenReceiver, bytes memory data2) =
            contractAddress.staticcall{ gas: gasLimit }(
                _ENCODED_ERC721_TOKENRECEIVER_EIP165ID
            );
        (bool successERC721Metadata, bytes memory data3) =
            contractAddress.staticcall{ gas: gasLimit }(
                _ENCODED_ERC721_METADATA_EIP165ID
            );
        (bool successERC721Enumerable, bytes memory data4) =
            contractAddress.staticcall{ gas: gasLimit }(
                _ENCODED_ERC721_ENUMERABLE_EIP165ID
            );
        return ((successERC721 && data1.length > 0) ||
            (successERC721TokenReceiver && data2.length > 0) ||
            (successERC721Metadata && data3.length > 0) ||
            (successERC721Enumerable && data4.length > 0));
    }

    function detectTokenType(address contractAddress, uint256 gasLimit)
        external
        view
        returns (TokenType)
    {
        if (isERC721(contractAddress, gasLimit)) {
            return TokenType.ERC721;
        }
        if (isERC20(contractAddress, gasLimit)) {
            return TokenType.ERC20;
        }
        return TokenType.Invalid;
    }
}
