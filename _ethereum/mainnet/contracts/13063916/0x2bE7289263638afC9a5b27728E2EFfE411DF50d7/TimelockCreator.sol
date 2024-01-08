pragma solidity 0.8.6;

import "./Timelock.sol";

/**
Factory contract that creates a timelock given global timelock parameters.
*/
contract TimelockCreator {
    event CreatedTimelockContract(
        address indexed,
        Timelock indexed,
        uint256,
        uint256,
        uint256
    );

    function createTimelock(
        address owner,
        IERC20 token,
        uint256 payoutAmount,
        uint256 unlockTimestamp,
        uint256 recoverTimestamp
    ) external returns (Timelock) {
        Timelock response = new Timelock(
            owner,
            token,
            payoutAmount,
            unlockTimestamp,
            recoverTimestamp
        );
        emit CreatedTimelockContract(
            owner,
            response,
            payoutAmount,
            unlockTimestamp,
            recoverTimestamp
        );
        return response;
    }
}
