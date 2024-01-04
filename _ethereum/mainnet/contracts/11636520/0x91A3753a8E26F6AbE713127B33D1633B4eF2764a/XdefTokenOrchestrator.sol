pragma solidity 0.6.12;

import "./Ownable.sol";

import "./XdefTokenMonetaryPolicy.sol";


/**
 * @title XdefTokenOrchestrator
 * @notice The orchestrator is the main entry point for rebase operations. It coordinates the policy
 * actions with external consumers.
 */
contract XdefTokenOrchestrator is Ownable {

    event TransactionFailed(address indexed destination, uint index, bytes data);

    // Stable ordering is not guaranteed.
    bool[] transactionEnabled;
    address[] transactionDestination;
    bytes[] transactionData;

    XdefTokenMonetaryPolicy public policy;

    function setMonetaryPolicy(address _policy)
        public
        onlyOwner
    {
        policy = XdefTokenMonetaryPolicy(_policy);
    }

    /**
     * @param policy_ Address of the XdefToken policy.
     */
    constructor (address policy_)
        public
    {
        policy = XdefTokenMonetaryPolicy(policy_);
    }

    /**
     * @notice Main entry point to initiate a rebase operation.
     *         The XdefTokenOrchestrator calls rebase on the policy and notifies downstream applications.
     *         Contracts are guarded from calling, to avoid flash loan attacks on liquidity
     *         providers.
     *         If a transaction in the transaction list reverts, it is swallowed and the remaining
     *         transactions are executed.
     */
    function rebase()
        external
    {
        require(msg.sender == tx.origin);  // solhint-disable-line avoid-tx-origin

        policy.rebase();

        for (uint i = 0; i < transactionEnabled.length; i++) {
            // Transaction storage t = transactions[i];
            if (transactionEnabled[i]) {
                bool result = externalCall(transactionDestination[i], transactionData[i]);
                if (!result) {
                    emit TransactionFailed(transactionDestination[i], i, transactionData[i]);
                    revert("Transaction Failed");
                }
            }
        }
    }

    /**
     * @notice Adds a transaction that gets called for a downstream receiver of rebases
     * @param destination Address of contract destination
     * @param data Transaction data payload
     */
    function addTransaction(address destination, bytes memory data)
        external
        onlyOwner
    {
        transactionEnabled.push(true);
        transactionDestination.push(destination);
        transactionData.push(data);
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint index)
        external
        onlyOwner
    {
        require(index < transactionEnabled.length, "index out of bounds");

        if (index < transactionEnabled.length - 1) {
            transactionEnabled[index] = transactionEnabled[transactionEnabled.length - 1];
            transactionDestination[index] = transactionDestination[transactionEnabled.length - 1];
            transactionData[index] = transactionData[transactionEnabled.length - 1];
        }

        transactionEnabled.pop();
        transactionDestination.pop();
        transactionData.pop();
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint index, bool enabled)
        external
        onlyOwner
    {
        require(index < transactionEnabled.length, "index must be in range of stored tx list");
        transactionEnabled[index] = enabled;
    }

    /**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */
    function transactionsSize()
        external
        view
        returns (uint256)
    {
        return transactionEnabled.length;
    }

    /**
     * @dev wrapper to call the encoded transactions on downstream consumers.
     * @param destination Address of destination contract.
     * @param data The encoded data payload.
     * @return True on success
     */
    function externalCall(address destination, bytes memory data)
        internal
        returns (bool)
    {
        bool result;
        assembly {  // solhint-disable-line no-inline-assembly
            // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let outputAddress := mload(0x40)

            // First 32 bytes are the padded length of data, so exclude that
            let dataAddress := add(data, 32)

            result := call(
                // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB)
                // + callValueTransferGas (9000) + callNewAccountGas
                // (25000, in case the destination address does not exist and needs creating)
                sub(gas(), 34710),


                destination,
                0, // transfer value in wei
                dataAddress,
                mload(data),  // Size of the input, in bytes. Stored in position 0 of the array.
                outputAddress,
                0  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}
