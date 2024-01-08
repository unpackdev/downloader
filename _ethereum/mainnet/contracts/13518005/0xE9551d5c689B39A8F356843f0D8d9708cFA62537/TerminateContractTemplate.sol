// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract TerminateContractTemplate is Ownable {
    uint256 public expiration;

    constructor() {}

    function setExpiration(uint256 _expiration) public virtual onlyOwner {
        expiration = _expiration;
    }

    function terminate() public virtual onlyOwner isOver {
        selfdestruct(payable(owner()));
    }

    modifier isLive() {
        require(
            expiration == 0 || block.timestamp <= expiration,
            "Terminated: Time over"
        );
        _;
    }

    modifier isOver() {
        require(
            expiration != 0 && block.timestamp > expiration,
            "Terminated: Contract is live"
        );
        _;
    }
}
