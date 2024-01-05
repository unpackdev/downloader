// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "./SafeERC20.sol";
import "./TimedEscrow.sol";

/**
 * @dev A factory to deploy instances of TimedEscrow with with given parameters
 *
 */
contract TimedEscrowFactory {
    using SafeERC20 for IERC20;
    /* ============ Events ============ */

    event TimedEscrowCreated(
        address indexed _timedEscrow,
        address _token,
        address _beneficiary,
        uint256 _releaseTime,
        address _rescuer,
        uint256 _rescueTime
    );

    /* ============ Functions ============ */
    function create(
        IERC20 token_,
        address beneficiary_,
        uint256 releaseTime_,
        address rescuer_,
        uint256 rescueTime_
    ) external returns (address) {
        TimedEscrow timedEscrow =
            new TimedEscrow(
                token_,
                beneficiary_,
                releaseTime_,
                rescuer_,
                rescueTime_
            );

        emit TimedEscrowCreated(
            address(timedEscrow),
            address(token_),
            beneficiary_,
            releaseTime_,
            rescuer_,
            rescueTime_
        );

        return address(timedEscrow);
    }
}
