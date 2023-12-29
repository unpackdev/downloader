/**
 *Submitted for verification at Etherscan.io on 2020-06-02
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;


/*
 * Copyright (c) The Force Protocol Development Team
*/
/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20Detailed {
    function symbol() external view returns (string memory);
}

contract NameGen {
    function append(string memory a, string memory b, string memory c) public pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

   function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function gen(string memory symbol, uint id) public view returns (string memory) {
        return append("Bond", symbol, uint2str(id));
    }

    function gen(address token, uint id) public view returns (string memory) {
        return gen(token != address(0) ? IERC20Detailed(token).symbol() : "ETH", id);
    }
}