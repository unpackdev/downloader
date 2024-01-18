pragma solidity ^0.8.13;

/// @author: 0xtygra

// Audited by: @silikastudio

import "./ERC721A.sol";
import "./Strings.sol";
import "./VRFV2WrapperConsumerBase.sol";
import "./VRFConsumerBaseV2.sol";
import "./LinkTokenInterface.sol";
import "./ConfirmedOwner.sol";

error ExceedsMaxMinted(
    uint256 MAX_MINT_AMOUNT,
    uint256 totalMinted,
    uint256 quantity
);
error ExceedsMaxPerTx(uint256 MAX_MINT_PER_TX, uint256 quantity);
error WrongAmount(uint256 sent, uint256 required);
error WithdrawNotAllowed(address sender);
error WithdrawFailed(uint256 balance);
error InvalidBurnMultiple(uint256 givenMultiple, uint256 requiredMultiple);
error OnlyOwnerBurn(address sender, address owner);
error RevealTooSoon(uint256 currMinted, uint256 numUntilNextReveal);

contract GoldenRatio is ERC721A, VRFV2WrapperConsumerBase, ConfirmedOwner {
    // Chainlink VRF Events
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }

    // Store a batch's end token + VRF random value used as a seed
    struct ShuffleData {
        uint256 seed;
        uint256 endId;
    }

    // Stores how many tokens need to be unrevealed before allowing
    // a reveal, after (and incl) a tokenId
    struct BatchRevealData {
        uint256 minNumUnrevealed;
        uint256 startTokenId;
    }

    // ============== Chainlink VRF data ===============
    uint32 constant VRF_GAS_LIMIT = 1_000_000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;

    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address wrapperAddress = 0x5A861794B927983406fCE1D062e00b9368d97Df6;

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    mapping(uint256 => address) public requestIdToSender;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    /*
     * Track the totalMinted when we last tried to reveal.
     * Used to ensure we're fault tolerant if Chainlink were to fail
     * to deliver a random value
     */
    uint256 totalMintedWhenLastRequested;

    // =================================================
    // Number of tokens to burn in order to mint 1 new token
    uint256 public constant NUM_PER_BURN = 2;
    uint256 public constant MAX_MINT_AMOUNT = 10_000_000;
    uint256 public constant MAX_MINT_PER_TX = 100;
    uint256 public constant MINT_PRICE = 0.001618 ether;
    address constant WITHDRAWAL_ADDRESS =
        0xfD65958e7D14c8935242CA33b3D58ce6679b3993;
    string constant tokenBaseURI = "ipfs://";
    string public constant contractURI =
        "ipfs://bafybeibsmoihpfg7y55277feuuoy2jpbtiv7kd5fyspbivh6l4u5bi6lli/contract.json";
    string constant defaultTokenUri =
        "ipfs://bafybeigxvj64x5qmz7376nnhvh5sblltgipj6lnpzzovt4ojnokgxadz7y/unrevealed.json";
    // As we have 10,000,000 NFTs, we'll chunk them into folders
    // of 10k files. ie->ipfs/Qm...../10000/10531.json
    uint256 constant IPFS_FOLDER_SIZE = 10_000;
    uint256 constant REVEAL_SHUFFLE_DATA_BATCH_SIZE = 5_000;

    // Number of unrevealed tokens required for a reveal
    // depends on the number of tokens minted overall
    BatchRevealData[] public minUnrevealedData;
    ShuffleData[] shuffleData;
    // Each million tokens' metadata+images will correspond to a separate root CID
    // This makes it easier for anyone to pin the assets themselves, as they only need
    // to pin in sets of 1 million
    string[10] ipfsRoots = [
        "bafybeihg5vxiwbtlrlcmtt2kw5ovv6vokcn2jbicwhhlyxcmh2biu76vve",
        "bafybeigp7kz7g2z6jeutsnzahbo6db5nmbu3rsjmz3b4auqimfqu2d2gy4",
        "bafybeibugzh76ut77i47ueveatd5swc4dozpv7tmunohxzlhupxuycvdoi",
        "bafybeig7hhguzlo7bts76qomorw4pgjicuf36o7ej5zrqxqb2mum3iyf4m",
        "bafybeibrtx7abu3cnyeszddhcqwa2l2n3dhdealzefysvuuxg32wle5cxq",
        "bafybeihfhntpmtu75p6pz6oweyq5ktxrvmkzwleen5wi7v2slajyjk2udi",
        "bafybeic2ppyaodi33q34zlmhy2bcg5pb4iqhprsidvp4j2jhk23adonnpe",
        "bafybeihe3zh6t66qxjbxjjucjeml42zgspefhjuv4jsq7o4kp4nkt7iqzi",
        "bafybeiem6tcckrowvq5oknctf3n73fhfolke77nbe7egbknhpc5ihx2suy",
        "bafybeift5ix22zegkomycok2fpzaez6yy6rupo5v6gvgsqad3grj4wyvdm"
    ];

    modifier OnlyAllowedCaller(address sender) {
        if (msg.sender != WITHDRAWAL_ADDRESS)
            revert WithdrawNotAllowed(msg.sender);
        _;
    }

    modifier OnlyEnoughToReveal() {
        uint256 currMinted = totalMinted();

        // Ensure there we have enough unrevealed tokens
        // or the project has minted out
        uint256 numUntilNextReveal = getNumUntilNextReveal();
        if (numUntilNextReveal != 0 && (currMinted != MAX_MINT_AMOUNT))
            revert RevealTooSoon(currMinted, numUntilNextReveal);
        else _;
    }

    constructor()
        payable
        ERC721A("ratios.gold", "RGold")
        VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
        ConfirmedOwner(msg.sender)
    {
        // Specify the reveal breakpoints
        minUnrevealedData.push(BatchRevealData(1000, 0));
        minUnrevealedData.push(BatchRevealData(5000, 10000));
        minUnrevealedData.push(BatchRevealData(10000, 50000));
    }

    /// @notice Withdraw contract ETH funds
    function withdrawFunds() external OnlyAllowedCaller(msg.sender) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(WITHDRAWAL_ADDRESS).call{value: balance}("");
        if (!success) revert WithdrawFailed(balance);
    }

    /// @notice Withdraw contract LINK funds
    function withdrawLink() public OnlyAllowedCaller(msg.sender) {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        uint256 balance = link.balanceOf(address(this));
        if (
            !link.transfer(
                address(WITHDRAWAL_ADDRESS),
                link.balanceOf(address(this))
            )
        ) revert WithdrawFailed(balance);
    }

    /// @notice Mint GoldenRatio tokens
    /// @param _quantity Number of tokens to mint.
    function publicMint(uint256 _quantity) external payable {
        if (_quantity > MAX_MINT_PER_TX)
            revert ExceedsMaxPerTx(MAX_MINT_PER_TX, _quantity);
        if (totalMinted() + _quantity > MAX_MINT_AMOUNT)
            revert ExceedsMaxMinted(MAX_MINT_AMOUNT, totalMinted(), _quantity);
        if (msg.value != _quantity * MINT_PRICE)
            revert WrongAmount(msg.value, _quantity * MINT_PRICE);
        _mint(msg.sender, _quantity);
    }

    /// @notice Burn NUM_PER_BURN tokens owned to mint 1 new token
    /// @param ids Ids owned by caller to burn
    function burn(uint256[] calldata ids) external {
        if (ids.length % NUM_PER_BURN != 0)
            revert InvalidBurnMultiple(ids.length, NUM_PER_BURN);

        // Check that the caller owns them all
        for (uint256 i; i < ids.length; ) {
            uint256 id = ids[i];
            // Check that caller owns token. Don't use ERC721a's `approvalCheck`
            // as that checks for owner or approved, whereas only owners can burn
            if (ownerOf(id) != msg.sender)
                revert OnlyOwnerBurn(msg.sender, ownerOf(id));
            _burn(id);
            unchecked {
                ++i;
            }
        }

        _mint(msg.sender, ids.length / NUM_PER_BURN);
    }

    /// @notice Get the highest revealed tokenId
    function getLastRevealed() public view returns (uint256) {
        return
            shuffleData.length > 0
                ? shuffleData[shuffleData.length - 1].endId
                : 0;
    }

    function getNumUntilNextReveal() public view returns (uint256) {
        uint256 lastRevealed = getLastRevealed();

        uint256 firstUnrevealed = lastRevealed != 0 ? lastRevealed + 1 : 0;
        uint256 currMinted = totalMinted();
        uint256 minNumUnrevealed;
        /*
         * Find the minimum number of tokens that need to be
         * unrevealed before we can reveal for the current number
         * of minted out tokens
         */
        if (minUnrevealedData[2].startTokenId <= currMinted) {
            minNumUnrevealed = minUnrevealedData[2].minNumUnrevealed;
        } else if (minUnrevealedData[1].startTokenId <= currMinted) {
            minNumUnrevealed = minUnrevealedData[1].minNumUnrevealed;
        } else {
            minNumUnrevealed = minUnrevealedData[0].minNumUnrevealed;
        }

        uint256 numUntilNextReveal = currMinted - firstUnrevealed <=
            minNumUnrevealed
            ? minNumUnrevealed - (currMinted - firstUnrevealed)
            : 0;

        if (numUntilNextReveal != 0) return numUntilNextReveal;

        /*
         * Special case to allow for another attempted reveal if that last
         * wasn't successful, but only if there has been *another*
         * `minUnrevealed` minted tokens since the last attempted reveal
         * In reality, Chainlink VRF should always successfully
         * provide a random value
         */
        uint256 numUntilReAttemptReveal = currMinted -
            totalMintedWhenLastRequested <
            minNumUnrevealed
            ? minNumUnrevealed - (currMinted - totalMintedWhenLastRequested)
            : 0;

        if (numUntilReAttemptReveal != 0) return numUntilReAttemptReveal;

        return 0;
    }

    /// @notice Reveal the next batch of unrevealed tokens
    /// by requesting a Chainlink VRF random value used to
    /// shuffle the revealed batch. Anyone can trigger a
    /// reveal. Each reveal costs ~0.3 LINK for the VRF number.
    /// The team will aim to keep the contract topped up with LINK,
    /// but anyone is able to fund it if the contract doesn't
    /// have enough LINK and they wish to reveal.
    function revealBatch() public OnlyEnoughToReveal returns (uint256) {
        // Make the request to Chainlink for a random value
        // Will be fulfilled after `requestConfirmations` blocks

        uint256 requestId = requestRandomness(
            VRF_GAS_LIMIT,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(VRF_GAS_LIMIT),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        totalMintedWhenLastRequested = totalMinted();

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    // Function Chainlink will call to supply us with the VRF random value
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        shuffleData.push(ShuffleData(_randomWords[0], totalMinted() - 1));

        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    // @notice Given a position in our theoretical array of
    // 10 million pieces of metadata, format the ipfs URI for the
    // given position.
    function _formatTokenURI(uint256 metadataPosition)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                tokenBaseURI,
                ipfsRoots[
                    (metadataPosition / (MAX_MINT_AMOUNT / ipfsRoots.length))
                ],
                "/",
                _toString(
                    (metadataPosition / IPFS_FOLDER_SIZE) * IPFS_FOLDER_SIZE
                ),
                "/",
                _toString(metadataPosition),
                ".json"
            );
    }

    /// @notice Finds a token's metadata given our shuffle logic.
    /// If unrevealed, return the default URI.
    /// If revealed, find the random seed for the token's batch
    /// and perform the shuffle to find its resultant metadata
    /// @param _tokenId ID of the token whose metadata we require
    function _getMetadata(uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        // If true, the token has not revealed yet
        if (_tokenId > getLastRevealed() || (shuffleData.length == 0)) {
            return defaultTokenUri;
        }

        for (uint256 i; i < shuffleData.length; ) {
            ShuffleData memory batch = shuffleData[i];

            /*
             * This will keep looping through batches until
             * endId the tokenId requested is in the current batch
             */
            if (_tokenId > batch.endId) {
                unchecked {
                    ++i;
                }
                continue;
            }

            // Find the lowest tokenID and batch size for all tokens revealed
            // in _tokenID's batch
            // Find the REVEAL_SHUFFLE_DATA_BATCH_SIZE within the whole reveal
            // that _tokenID falls into
            uint256 startOfThisTokensBatch = _tokenId -
                (_tokenId % REVEAL_SHUFFLE_DATA_BATCH_SIZE);
            uint256 endOfBatch = startOfThisTokensBatch +
                REVEAL_SHUFFLE_DATA_BATCH_SIZE >
                batch.endId
                ? batch.endId
                : startOfThisTokensBatch + REVEAL_SHUFFLE_DATA_BATCH_SIZE;
            uint256 batchSize = endOfBatch - startOfThisTokensBatch + 1;
            // Initializes the metadata array
            uint256[] memory metadata = new uint256[](batchSize);
            for (uint256 j = startOfThisTokensBatch; j <= endOfBatch; ) {
                metadata[j - startOfThisTokensBatch] = j;

                unchecked {
                    ++j;
                }
            }

            /*
             * Using the Chainlink VRF seed, goes through the metadata array
             * and randomly swaps two values, in order to achieve verifiably
             * random resultant metadata
             */
            for (uint256 k = startOfThisTokensBatch; k <= endOfBatch; ) {
                uint256 swap = (uint256(keccak256(abi.encode(batch.seed, k))) %
                    (batchSize));
                (metadata[k - startOfThisTokensBatch], metadata[swap]) = (
                    metadata[swap],
                    metadata[k - startOfThisTokensBatch]
                );

                unchecked {
                    ++k;
                }
            }

            // Now that all the swaps are complete, return the metadata
            // in the tokenId'th position
            uint256 metadataPosition = metadata[
                _tokenId - startOfThisTokensBatch
            ];
            return _formatTokenURI(metadataPosition);
        }

        // Should never be reached.
        revert();
    }

    /// @notice Return the metadataURI for a given tokenId
    /// @param _tokenId ID of the token whose metadata we require
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "Query for nonexistent token");

        return _getMetadata(_tokenId);
    }

    /// @notice Get the total number of tokens minted.
    /// Used in place of `totalSupply` due to our burn mechanic
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }
}
