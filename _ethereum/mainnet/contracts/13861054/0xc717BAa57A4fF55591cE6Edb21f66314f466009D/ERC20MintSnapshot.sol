// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

// Code Based on Compound's Comp.sol: https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

contract ERC20MintSnapshot is ERC20 {
    /// @notice A checkpoint for marking number of mints from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint224 mints;
    }

    /// @notice A record of mint checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    // Address to signify snapshotted total mint amount
    address private constant TOTAL_MINT = address(0);

    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {}

    /**
     * @notice Determine the prior amount of mints for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the mint balance at
     * @return The amount of mints the account had as of the given block
     */
    function getPriorMints(address account, uint256 blockNumber)
        public
        view
        returns (uint224)
    {
        require(
            blockNumber < block.number,
            "ERC20MintSnapshot::getPriorMints: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].mints;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.mints;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].mints;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint224 value =
            safe224(
                amount,
                "ERC20MintSnapshot::_beforeTokenTransfer: Amount minted exceeds limit"
            );
        if (from == address(0) && value > 0) {
            uint32 totalMintNum = numCheckpoints[TOTAL_MINT];
            uint224 totalMintOld =
                totalMintNum > 0
                    ? checkpoints[TOTAL_MINT][totalMintNum - 1].mints
                    : 0;
            uint224 totalMintNew =
                add224(
                    totalMintOld,
                    value,
                    "ERC20MintSnapshot::_beforeTokenTransfer: mint amount overflows"
                );
            _writeCheckpoint(TOTAL_MINT, totalMintNum, totalMintNew);

            uint32 minterNum = numCheckpoints[to];
            uint224 minterOld =
                minterNum > 0 ? checkpoints[to][minterNum - 1].mints : 0;
            uint224 minterNew =
                add224(
                    minterOld,
                    value,
                    "ERC20MintSnapshot::_beforeTokenTransfer: mint amount overflows"
                );
            _writeCheckpoint(to, minterNum, minterNew);
        }
    }

    function _writeCheckpoint(
        address minter,
        uint32 nCheckpoints,
        uint224 newMints
    ) internal {
        uint32 blockNumber =
            safe32(
                block.number,
                "ERC20MintSnapshot::_writeCheckpoint: block number exceeds 32 bits"
            );

        if (
            nCheckpoints > 0 &&
            checkpoints[minter][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[minter][nCheckpoints - 1].mints = newMints;
        } else {
            checkpoints[minter][nCheckpoints] = Checkpoint(
                blockNumber,
                newMints
            );
            numCheckpoints[minter] = nCheckpoints + 1;
        }
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe224(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint224)
    {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function add224(
        uint224 a,
        uint224 b,
        string memory errorMessage
    ) internal pure returns (uint224) {
        uint224 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
}
