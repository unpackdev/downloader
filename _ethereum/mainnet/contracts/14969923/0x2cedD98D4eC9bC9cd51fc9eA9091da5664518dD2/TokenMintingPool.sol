// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IVault.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./Address.sol";
import "./Math.sol";
import "./ERC165Checker.sol";
import "./EnumerableSet.sol";

/**
 * @title Token minting pool contract.
 */
abstract contract TokenMintingPool is VRFConsumerBaseV2 {
    using EnumerableSet for EnumerableSet.Bytes32Set;


    /* ========================================== VARIABLES ========================================== */

    VRFCoordinatorV2Interface internal COORDINATOR;

    bytes32 private _vrfKeyHash; // The key hash to run Chainlink VRF

    uint64 public vrfSubscriptionId; // Chainlink Subscription ID
                                        // See https://vrf.chain.link/

    uint256 private s_requestId; // Request ID sent by the VRF

    IVault public immutable vault; // Reference to the vault where tokens will be minted.

    EnumerableSet.Bytes32Set private _availableTokenHashes;                     // The available token hashes that haven't been minted yet

    uint256[] private _randomSeeds; //  random seeds numbers provided by Chainlink VRF v2, ensuring that
                                     // even though the mint is 1st come / 1st serve, the order in
                                     // which token hashes were uploaded does not matter.
                                     // Number of random seeds is determined by the supply when locking.


    uint256 private _randomValue;    // (_randomValue != 0) serves as a check to verify that the
                                    // supply is locked.

    uint256 private _seedCounter; // Allows to have a different seed for each mint

    uint256 public initialSupply; //Initial supply of the drop when locking the supply


    /* ========================================== EVENTS ========================================== */

    event TokensAdded(uint256 indexed addedNumber);
    event TokensRemoved(uint256 indexed removedNumber);


    /* ========================================== CONSTRUCTOR AND HELPERS ========================================== */

    /**
     * @dev modifier to check that the vault implements {IVault}, like {Vault}.
     */
    modifier onlyValidVault(address vaultAddress) {
        require(
            ERC165Checker.supportsInterface(vaultAddress, type(IVault).interfaceId),
            'TokenMintingPool: Target token registry contract does not match the interface requirements.'
        );
        _;
    }

    /**
     * @dev Constructor.
     *
     *  - Sets the parameters to use Chainlink VRF for token hashes shuffling pre-mint.
     *  - Sets the token registry
     *
     * Requirement: {vaultAddress} must point to a valid {IVault} contract.
     *
     */
    constructor(
        address vaultAddress,
        address vrfCoordinator,
        bytes32 vrfKeyHash,
        uint64 _vrfSubscriptionId
    ) onlyValidVault(vaultAddress) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        vault = IVault(vaultAddress);
        _vrfKeyHash = vrfKeyHash;
        vrfSubscriptionId = _vrfSubscriptionId;
    }

    /* ============================================ TOKEN SUPPLY HELPERS ============================================ */

    /**
     * @dev add multiple token hashes to the supply.
     * Note: if the input is too big, the transaction will fail due to high gas limit.
     */
    function _addTokens(bytes32[] calldata tokenHashes) internal {
        require(!tokenSupplyLocked(), 'TokenMintingPool: Token supply is locked. Cannot add new tokens.');
        for (uint256 ii = 0; ii < tokenHashes.length; ii++) {
            _availableTokenHashes.add(tokenHashes[ii]);
        }
         emit TokensAdded(tokenHashes.length);
    }

    /**
     * @dev remove multiple token hashes from the supply.
     * Note: if the input is too big, the transaction will fail due to high gas limit.
     */
    function _removeTokens(bytes32[] calldata tokenHashes) internal {
        require(!tokenSupplyLocked(), 'TokenMintingPool: Token supply is locked. Cannot remove tokens.');
        for (uint256 ii = 0; ii < tokenHashes.length; ii++) {
            _availableTokenHashes.remove(tokenHashes[ii]);
        }
        emit TokensRemoved(tokenHashes.length);
    }

    /**
     * @dev Triggers the token supply locking process by making a request to Chainlink VRF to get a set of random seeds.
     * The random seeds, when provided by Chainlink, will automatically trigger a shuffle of all the token hashes
     * and lock the supply. See {fulfillRandomWords()}.
     *
     * This cannot be undone, but can be called again if chainlink failed to return a random number.
     */
    function _lockTokenSupply(uint32 callbackGasLimit, uint32 numberSeeds) internal {
        initialSupply = remainingSupplyCount();
        require(numberSeeds < 501);
        require(!tokenSupplyLocked(), 'TokenMintingPool: Token supply is already locked.');
        s_requestId = COORDINATOR.requestRandomWords(
            _vrfKeyHash,
            vrfSubscriptionId,
            3, // Default number of confirmations
            callbackGasLimit, // See https://docs.chain.link/docs/vrf-contracts/
            numberSeeds // This value should be lower than 500 (VRF v2 can only provide 500 seeds by call)
        );
    }

    /**
     * @dev Tells whether or not the token supply is locked.
     */
    function tokenSupplyLocked() public view returns (bool) {
        return _randomValue != 0;
    }

    /**
     * @dev Callback function used by the VRF Coordinator, that will update the seed array,
     * and lock the supply in the process (See {tokenSupplyLocked()})
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        if (!tokenSupplyLocked()) {
            _randomValue = randomWords[0];
            _randomSeeds = randomWords;
        }
    }

    /**
     * @dev The size of the remaining supply.
     */
    function remainingSupplyCount() public view returns (uint256) {
        return _availableTokenHashes.length();
    }

    /* ================================================== MINTING ================================================== */

    /**
     * @dev Minting function
     *
     * Parameters:
     *  - to: the address that will recieve the newly minted tokens
     *  - numTokens: the number of tokens to mint
     *
     * Requirements:
     *  - The token supply must be locked.
     *  - The number of requested tokens needs to be <= The remaining supply.
     *
     */
    function _mintTokens(
        address to,
        uint256 numTokens
    ) internal {
        require(tokenSupplyLocked(), 'TokenMintingPool: Token supply needs to be locked.');
        require(remainingSupplyCount() + 1 > numTokens, 'TokenMintingPool: Not enough tokens left.');
        for (uint256 ii = 0; ii < numTokens; ii++) {
            uint256 index = _randomSeeds[_seedCounter % _randomSeeds.length] % remainingSupplyCount();
            bytes32 tokenHash = _availableTokenHashes.at(index);
            vault.mint(to, tokenHash, 1, '');
            _availableTokenHashes.remove(tokenHash);
            _seedCounter += 1;
        }
    }
}
