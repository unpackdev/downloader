// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IMapleWithdrawalManagerStorage {

    /**
     *  @dev    Returns the address of the pool contract.
     *  @return pool Address of the pool contract.
     */
    function pool() external view returns (address pool);

    /**
     *  @dev    Returns the address of the pool manager contract.
     *  @return poolManager Address of the pool manager contract.
     */
    function poolManager() external view returns (address poolManager);

    /**
     *  @dev    Returns the total amount of shares pending redemption.
     *  @return totalShares Total amount of shares pending redemption.
     */
    function totalShares() external view returns (uint256 totalShares);

    /**
     *  @dev    Checks if an account is set to perform withdrawals manually.
     *  @param  account  Address of the account.
     *  @return isManual `true` if the account withdraws manually, `false` if not.
     */
    function isManualWithdrawal(address account) external view returns (bool isManual);

    /**
     *  @dev    Returns the amount of shares available for manual withdrawal.
     *  @param  owner           The address of the owner of shares.
     *  @return sharesAvailable Amount of shares available for manual withdrawal.
     */
    function manualSharesAvailable(address owner) external view returns (uint256 sharesAvailable);

    /**
     *  @dev    Returns the request identifier of an account.
     *          Returns zero if the account does not have a withdrawal request.
     *  @param  account   Address of the account.
     *  @return requestId Identifier of the withdrawal request.
     */
    function requestIds(address account) external view returns (uint128 requestId);

    /**
     *  @dev    Returns the first and last withdrawal requests pending redemption.
     *  @return nextRequestId Identifier of the next withdrawal request that will be processed.
     *  @return lastRequestId Identifier of the last created withdrawal request.
     */
    function queue() external view returns (uint128 nextRequestId, uint128 lastRequestId);

}
