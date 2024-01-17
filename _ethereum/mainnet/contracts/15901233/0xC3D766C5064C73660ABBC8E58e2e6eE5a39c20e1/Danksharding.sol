// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Erc20C17Contract.sol";

contract Danksharding is
Erc20C17Contract
{
    string public constant VERSION = "danksharding";

    constructor(
        string[2] memory strings,
        address[4] memory addresses,
        uint256[67] memory uint256s,
        bool[24] memory bools
    ) Erc20C17Contract(strings, addresses, uint256s, bools)
    {

    }

    function decimals()
    public
    pure
    override
    returns (uint8)
    {
        return 18;
    }
}
