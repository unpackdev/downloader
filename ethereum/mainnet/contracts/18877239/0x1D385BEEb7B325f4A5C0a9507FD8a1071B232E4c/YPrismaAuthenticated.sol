// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "ILocker.sol";

/**
    @title Yearn Prisma Authentication
    @author Yearn Finance
    @notice Contracts inheriting `YearnAuthenticated` permit only a trusted set of callers.
 */
contract YPrismaAuthenticated {
    ILocker public immutable LOCKER;

    constructor(address _locker) {
        LOCKER = ILocker(_locker);
    }

    modifier enforceAuth() {
        require(isAuthenticated(msg.sender), "!authorized");
        _;
    }

    function isAuthenticated(address _caller) public view returns (bool) {
        return (
            _caller == LOCKER.proxy() ||
            _caller == LOCKER.governance() ||
            _caller == address(LOCKER)
        );
    }
}
