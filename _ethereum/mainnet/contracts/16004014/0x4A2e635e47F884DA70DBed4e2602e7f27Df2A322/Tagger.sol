// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./Ownable.sol";

/**
 * @title   Tagger
 * @author  AuraFinance
 * @notice  Peripheral contract that simply emits an event tagging an address with
 *          an arbitrary string, without storage.
 */
contract Tagger is Ownable {
    event Tag(address addr, string tag);

    function tag(address _addr, string memory _tag) public onlyOwner {
        emit Tag(_addr, _tag);
    }
}
