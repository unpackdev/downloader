//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./console.sol";
import "./Address.sol";

import "./IMutagenToken.sol";
import "./ActiveAfterBlock.sol";

contract EVPool is ActiveAfterBlock {
    using Address for address payable;

    /*********************************
     * Constants, structs and events *
     *********************************/

    // Pool token values
    uint128 public constant GENESIS_VALUE = 8 ether;
    uint128 public constant MUTAGEN_VALUE = 0.08 ether;

    // The max number of tokens per transaction
    uint8 public constant MAX_TOKENS_PER_BUY = 10;

    struct QueuedMint {
        address owner;
        uint8 amount;
        uint256 gasPrice;
    }

    event TokensQueued(
        uint16 amount,
        address to,
        uint16 genesesRemaining,
        uint16 mutagensRemaining,
        uint256 poolPrice
    );

    event TokensSold(
        uint16 amount,
        address to,
        uint16 genesesRemaining,
        uint16 mutagensRemaining,
        uint256 poolPrice
    );

    /********************
     * Public variables *
     ********************/

    // Remaining token counts
    uint8 public genesesRemaining = 40;
    uint16 public mutagensRemaining = 4096;

    // Owner-redeemable token count (for giveaways etc)
    uint8 public redeemableTokens = 32;

    // Queued minting operation
    QueuedMint queued;

    // Mutagen token contract address
    address mutagenAddress;

    constructor(address _mutagenAddress, uint256 _startingBlock) {
        mutagenAddress = _mutagenAddress;
        startingBlock = _startingBlock;
    }

    /****************
     * User actions *
     ****************/

    /**
     * @dev Get the current price for buying a token from the pool
     */
    function getPoolPrice() public view returns (uint256) {
        uint16 currentPoolSize = _poolSize();

        return
            currentPoolSize > 0
                ? ((genesesRemaining *
                    GENESIS_VALUE +
                    mutagensRemaining *
                    MUTAGEN_VALUE) / currentPoolSize)
                : 0;
    }

    /**
     * @dev Get the current pool state
     */
    function getPoolState()
        public
        view
        returns (
            uint8 geneses,
            uint16 mutagens,
            uint256 price
        )
    {
        return (genesesRemaining, mutagensRemaining, getPoolPrice());
    }

    /**
     * @dev Buy a token from the pool
     */
    function buy(uint8 tokenCount) external payable isActive noContractAllowed {
        require(tokenCount > 0, "Cannot buy 0 tokens");
        require(
            tokenCount <= MAX_TOKENS_PER_BUY,
            "Too many tokens per purchase"
        );

        // Perform queued mint
        _performMint(queued.owner, queued.amount, queued.gasPrice);

        uint16 remainingTokens = _poolSize();
        require(remainingTokens >= tokenCount, "Not enough tokens in the pool");

        // Collect pool fees
        uint256 usedFees = _collectPoolFees(tokenCount);

        // Push the mint operation into the queue
        _queueMint(tokenCount, msg.sender);

        // Refund any excess ether to the caller
        _refundExcess(usedFees);

        // If these are the last remaining tokens in the pool
        // we close out the queue right away
        if (remainingTokens == tokenCount) {
            _performMint(queued.owner, queued.amount, queued.gasPrice);
        }
    }

    /*******************
     * Admin functions *
     *******************/

    /**
     * @dev Withdraw contract balance
     */
    function withdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).sendValue(balance);
    }

    /**
     * @dev Redeem a token from the pool to an address
     */
    function redeem(address[] memory recipients) external onlyOwner {
        require(
            redeemableTokens >= recipients.length,
            "Token redeem limit reached"
        );
        // Make sure there are still tokens in the pool
        require(_poolSize() >= recipients.length, "Not enough tokens");

        // Decrease redeemable token count
        redeemableTokens -= uint8(recipients.length);

        for (uint8 i = 0; i < recipients.length; i++) {
            // Perform queued mint
            _performMint(queued.owner, queued.amount, queued.gasPrice);
            // Push the mint operation into the queue
            _queueMint(1, recipients[i]);
        }
    }

    /*************
     * Internals *
     *************/

    /**
     * @dev Get the current size of the pool
     */
    function _poolSize() internal view returns (uint16) {
        return genesesRemaining + mutagensRemaining;
    }

    /**
     * @dev Perform the minting operation
     */
    function _performMint(
        address to,
        uint8 amount,
        uint256 gasPrice
    ) internal {
        uint16 poolSize = _poolSize();
        uint256[] memory probabilities = _expand(_seed(), amount);

        for (uint256 i = 0; i < probabilities.length; i++) {
            if (
                // There is one main and two edge cases where
                // the user will receive a Mutagen from the pool
                // Case 1: Randomness results in the user receiving a Mutagen
                // This should happen most of the time.
                probabilities[i] % poolSize < mutagensRemaining ||
                // Case 2: There are no Geneses left
                genesesRemaining == 0 ||
                // Case 3: The queued buy came from a txn with 0 gas price.
                // We assume it's from a private mempool and mint a Mutagen if possible.
                // This is in place to prevent people fishing out Genesis tokens during the sale.
                // Sorry Flashbots.
                (gasPrice == 0 && mutagensRemaining > 0)
            ) {
                mutagensRemaining -= 1;
                uint256[] memory seeds = _expand(_seed(), 2);
                IMutagen(mutagenAddress).mintMutagen(
                    to,
                    uint8(seeds[0] % 4),
                    uint8(seeds[1] % 100),
                    mutagensRemaining
                );
            } else {
                genesesRemaining -= 1;
                IMutagen(mutagenAddress).mintGenesis(to, genesesRemaining);
            }
        }

        (uint8 geneses, uint16 mutagens, uint256 poolPrice) = getPoolState();

        emit TokensSold(amount, to, geneses, mutagens, poolPrice);
    }

    /**
     * @dev Queue a minting operation
     */
    function _queueMint(uint8 amount, address to) internal {
        queued.owner = to;
        queued.amount = amount;
        queued.gasPrice = tx.gasprice;

        (uint8 geneses, uint16 mutagens, uint256 poolPrice) = getPoolState();
        emit TokensQueued(amount, to, geneses, mutagens, poolPrice);
    }

    /**
     * @dev Return a randomish number for probabilistic operations
     */
    function _seed() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 253),
                        blockhash(block.number - 254),
                        blockhash(block.number - 255),
                        genesesRemaining,
                        mutagensRemaining
                    )
                )
            );
    }

    /**
     * @dev Expand a random value to create n more random values
     */
    function _expand(uint256 randomValue, uint8 n)
        internal
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    /**
     * @dev Check if the user sent enough ether and record contract fees
     */
    function _collectPoolFees(uint8 tokenCount) internal returns (uint256) {
        uint256 purchasePrice = tokenCount * getPoolPrice();
        require(msg.value >= purchasePrice, "Payment too small");

        return purchasePrice;
    }

    /**
     * @dev Refund any excess ether to the sender
     */
    function _refundExcess(uint256 usedFees) internal {
        if (msg.value > usedFees) {
            payable(msg.sender).sendValue(msg.value - usedFees);
        }
    }

    /**
     * @dev Check if the caller is an EOA and not a contract
     */
    modifier noContractAllowed() {
        require(
            !payable(msg.sender).isContract() && msg.sender == tx.origin,
            "Not allowed to buy from a contract!"
        );
        _;
    }
}
