// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist {
    mapping(address => uint256) public whitelist; // address => count permitted during presale
    uint256 public start; // sale period start
    uint256 public end; // optional sale period end

    // _end == 0 skips period end check
    constructor(uint256 _start, uint256 _end) {
        start = _start;
        end = _end;
    }

    function setTimes(uint256 _start, uint256 _end) external {
        start = _start;
        end = _end;
    }

    function set(address[] calldata addresses, uint256[] calldata entries)
        external
    {
        require(
            addresses.length == entries.length,
            "addresses length != entries length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "zero");
            whitelist[addresses[i]] = entries[i];
        }
    }

    function isMintable(uint256 qty, address to) public returns (bool) {
        // if we're in the whitelist period
        if (
            (block.timestamp > start) && (end == 0 || (block.timestamp < end))
        ) {
            // grab the current balance for this address
            uint256 balance = whitelist[to];
            // if the requested qty is greater than the balance
            if (qty > balance) {
                return false; // nope
            }
            // update the balance for this address
            whitelist[to] = balance - qty;
            return true; // yep!
        }
        return false;
    }
}
