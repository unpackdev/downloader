// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

/**
 * @dev Interface of the Genesis Sale Smart Contract.
 *
 * Selling EDGEX tokens at a fixed price
 * with a 365-day lock period.
 */

interface IGenesisSale {
    /**
     * @dev sends in `eth` in the transaction as `value`
     *
     * The function calculates the price of the ETH send
     * in value to equivalent amount in USD using chainlink
     * oracle and transfer the equivalent amount of tokens back to the user.
     *
     * Requirements:
     * `_reciever` address has to be whitelisted.
     */
    function buyEdgex(address _reciever, uint8 poolId) external payable returns (bool);

    /**
     * @dev allocate the amount of tokens (`EDGEX`) to a specific account.
     *
     * Requirements:
     * `caller` should have governor role previlages.
     * `_user` should've to be whitelisted.
     *
     * Used for off-chain purchases with on-chain settlements.
     */
    function allocate(
        uint256 _tokens,
        address _user,
        uint8 _method,
        uint8 poolId
    ) external returns (bool);

    /**
     * @dev transfer the control of genesis sale to another account.
     *
     * Onwers can add governors.
     *
     * Requirements:
     * `_newOwner` cannot be a zero address.
     *
     * CAUTION: EXECUTE THIS FUNCTION WITH CARE.
     */
    function revokeOwnership(address _newOwner) external returns (bool);

    /**
     * @dev transfers the edgex tokens to the user's wallet after the
     * 365-day lock time.
     *
     * Requirements:
     * `caller` should have a valid token balance > 0;
     * `_purchaseId` should be valid.
     */
    function claim(uint256 _purchaseId) external returns (bool);

    /**
     * @dev can change the minimum and maximum purchase value of edgex tokens
     * per transaction.
     *
     * Requirements:
     *  `_maxCap` can never be zero.
     *
     * `caller` should have governor role.
     */
    function updateCap(uint256 _minCap, uint256 _maxCap)
        external
        returns (bool);

    /**
     * @dev add an account with governor level previlages.
     *
     * Requirements:
     * `caller` should have admin role.
     * `_newGovernor` should not be a zero wallet.
     */
    function updateGovernor(address _newGovernor) external returns (bool);

    /**
     * @dev can change the contract address of EDGEX tokens.
     *
     * Requirements:
     * `_contract` cannot be a zero address.
     */
    function updateContract(address _contract) external returns (bool);

    /**
     * @dev can change the Chainlink ETH Source.
     *
     * Requirements:
     * `_ethSource` cannot be a zero address.
     */
    function updateEthSource(address _ethSource) external returns (bool);

    /**
     * @dev can change the address to which all paybale ethers are sent to.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_newEthSource` cannot be a zero address.
     */
    function updateEthWallet(address _newEthWallet) external returns (bool);

    /**
     * @dev can change the address to which a part of sold tokens are paid to.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_newOrgWallet` cannot be a zero address.
     */
    function updateOrgWallet(address _newOrgWallet) external returns (bool);

    /**
     * @dev can update the locktime for each poolId in number of days.
     *
     * Requirements:
     * `caller` should be admin.
     * `poolId` should be a valid one
     */
    function updatePoolLock(uint8 poolId, uint256 lockDays) external returns (bool);

    /**
     * @dev can update the cap for each poolId in number of edgex tokens.
     *
     * Requirements:
     * `caller` should be admin.
     * `poolId` should be a valid one
     */
    function updatePoolCap(uint8 poolId, uint256 poolCap) external returns (bool);

    /**
     * @dev can allows admin to take out the unsold tokens from the smart contract.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_to` cannot be a zero address.
     * `_amount` should be less than the current EDGEX token balance.
     *
     * Prevents the tokens from getting locked within the smart contract.
     */
    function drain(address _to, uint256 _amount) external returns (bool);
}
