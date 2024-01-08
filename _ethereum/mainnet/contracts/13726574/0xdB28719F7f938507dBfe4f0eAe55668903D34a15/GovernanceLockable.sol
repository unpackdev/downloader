pragma solidity ^0.5.2;

import "./Governable.sol";
import "./Lockable.sol";

contract GovernanceLockable is Lockable, Governable {
    constructor(address governance) public Governable(governance) {}

    function lock() public onlyGovernance {
        super.lock();
    }

    function unlock() public onlyGovernance {
        super.unlock();
    }
}
