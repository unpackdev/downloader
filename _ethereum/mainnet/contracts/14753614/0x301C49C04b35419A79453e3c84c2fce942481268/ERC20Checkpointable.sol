// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "./IERC20Checkpointable.sol";

// ERC20Checkpointable.sol
contract ERC20Checkpointable is IERC20Checkpointable {
    /// @notice The number of checkpoints for each account
    mapping(address => uint256) public override numCheckpoints;

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint256 => Checkpoint)) private _checkpoints;

    function getCheckpoint(address account, uint256 index) external view override returns (Checkpoint memory) {
        return _checkpoints[account][index];
    }

    /**
     * @notice Determine the prior balance for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The final balance the account had as of the given block
     */
    function getPriorBalance(address account, uint256 blockNumber) external view override returns (uint256) {
        require(blockNumber < block.number, "ERC20Checkpointable::getPriorBalance: INVALID_BLOCK_NUMBER");

        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (_checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return _checkpoints[account][nCheckpoints - 1].balance;
        }

        // Next check implicit zero balance
        if (_checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = _checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.balance;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return _checkpoints[account][lower].balance;
    }

    function _writeCheckpoint(
        address account,
        uint256 oldBalance,
        uint256 newBalance
    ) internal {
        uint256 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints > 0 && _checkpoints[account][nCheckpoints - 1].fromBlock == block.number) {
            _checkpoints[account][nCheckpoints - 1].balance = newBalance;
        } else {
            _checkpoints[account][nCheckpoints] = Checkpoint(block.number, newBalance);
            numCheckpoints[account] = nCheckpoints + 1;
        }

        emit BalanceChanged(account, oldBalance, newBalance);
    }
}
