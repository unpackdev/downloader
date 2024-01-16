// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "./Token.sol";
import "./SafeMath.sol";

/**
 * The batch transfer contract is used to solve the problem of high gas costs caused by transfers between multiple addresses,
 * because each transfer will incur a gas fee, while the batch transfer contract can complete transfers between multiple addresses with only one gas fee.
 */
contract VivMultiTransfer is Token {
    using SafeMath for uint256;

    /**
     * Check if size of address equals to size of value
     * @param addresses  array of address
     * @param values array of value
     */
    modifier checkSize(address[] memory addresses, uint256[] memory values) {
        require(addresses.length > 0, "VIV1201");
        require(addresses.length == values.length, "VIV0029");
        _;
    }

    /**
     * Multi transfer
     * @param addresses  array of address
     * @param values array of value
     */
    function multiTransfer(
        address[] memory addresses,
        uint256[] memory values,
        address _token
    ) external payable checkSize(addresses, values) {
        uint256 tmp = 0;
        for (uint256 i = 0; i < values.length; i++) {
            tmp = tmp.add(values[i]);
        }

        _checkTransferIn(_token, tmp);
        _transferFrom(_token, msg.sender, address(this), tmp);

        for (uint256 i = 0; i < addresses.length; i++) {
            _transfer(_token, addresses[i], values[i]);
        }
    }
}
