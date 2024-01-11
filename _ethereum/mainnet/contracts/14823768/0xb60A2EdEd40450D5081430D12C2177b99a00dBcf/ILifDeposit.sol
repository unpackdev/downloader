// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title LifDeposit contract interface
 * @dev A contract that manages deposits in Lif tokens 
 */
interface ILifDeposit {

    /**
     * @dev Lif token getter
     * @return lifToken Address of the Lif token
     }
     */
    function getLifTokenAddress() external view returns (address lifToken);

    /**
     * @dev Withdrawal delay getter
     * @return delay Delay time in seconds before the requested withdrawal will be possible
     */
    function getWithdrawDelay() external view returns (uint256 delay);

    /**
     * @dev Withdrawal delay setter
     * @param _withdrawDelay New withdrawDelay value in seconds
     */
    function setWithdrawDelay(uint256 _withdrawDelay) external;

    /**
     * @dev Makes deposit of Lif tokens
     * @param organization The organization Id
     * @param value The value to be deposited
     */
    function addDeposit(
        bytes32 organization,
        uint256 value
    ) external;

    /**
     * @dev Submits withdrawal request
     * @param organization The organization Id
     * @param value The value to withdraw
     */
    function submitWithdrawalRequest(
        bytes32 organization,
        uint256 value
    ) external;

    /**
     * @dev Returns information about deposit withdrawal request
     * @param organization The organization Id
     * @return exists The request existence flag
     * @return value Deposit withdrawal value
     * @return withdrawTime Withraw time on seconds
     */
    function getWithdrawalRequest(bytes32 organization)
        external
        view 
        returns (
            bool exists,
            uint256 value,
            uint256 withdrawTime
        );

    /**
     * @dev Transfer deposited tokens to the sender
     * @param organization The organization OrgId
     */
    function withdrawDeposit(
        bytes32 organization
    ) external;
}
