// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./IPirateGames.sol";
import "./IPytheas.sol";
import "./IOrbitalBlockade.sol";
import "./ITPirates.sol";
import "./IRAW.sol";
import "./IPirates.sol";
import "./IColonist.sol";
import "./IImperialGuild.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";


contract PirateGames is IPirateGames, VRFConsumerBaseV2, Pausable {
    struct MintCommit {
        bool stake;
        uint16 tokenId;
    }

    uint8[][6] public rarities;
    uint8[][6] public aliases;

    uint256 public OnosiaLiquorId;

    uint256 private maxRawEonCost;


    // address => can call
    mapping(address => bool) private admins;

    // address -> commit # -> commits
    mapping(address => mapping(uint16 => MintCommit)) private _mintCommits;
    // address -> commit num of commit need revealed for account
    mapping(address => uint16) private _pendingCommitId;

    // amout pending needed to toggle randomness
    uint16 toggleLimit;
    // counter for toggle randomness
    uint16 toggleCounter;

    uint16 private _commitId = 1;
    uint16 private pendingMintAmt;
    bool public allowCommits = false;

    address public auth;

    // reference to Pytheas for checking that a colonist has mined enough
    //rEON to make an attempt as well as pay from this amount, either the  current mint cost on
    //a successful pirate mint, or pirate tax on a failed attempt.
    IPytheas public pytheas;
    //reference to the OrbitalBlockade, where pirates are staked out, awaiting weak colonist miners.
    IOrbitalBlockade public orbital;
    // reference to raw Eon for attempts
    IRAW public raw;
    // reference to pirate collection
    IPirates public pirateNFT;
    // reference to the colonist NFT collection
    IColonist public colonistNFT;
    // reference to the galactic imperialGuild collection
    IImperialGuild public imperialGuild;
    // Chainlink references
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    uint256 linkFee;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    bytes32 keyHash; 
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
      //amount pending that toggles a randomness call
    uint32 public numWords = 1;
    uint256[] private randomness;
    uint256 public s_requestId;
    address s_owner;

    event MintCommitted(address indexed owner, uint256 indexed tokenId);
    event MintRevealed(address indexed owner, uint16[] indexed tokenId);

    constructor() VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        auth = msg.sender;
        admins[msg.sender] = true;
        admins[address(this)] = true;

        //RatioChance 90
        rarities[0] = [27, 230];
        aliases[0] = [1, 0];
        //RatioChance 80
        rarities[1] = [51, 204];
        aliases[1] = [1, 0];
        //RatioChance 60
        rarities[2] = [90, 175];
        aliases[2] = [1, 0];
        //RatioChance 40
        rarities[3] = [155, 132];
        aliases[3] = [1, 0];
        //RatioChance 10
        rarities[4] = [200, 60];
        aliases[4] = [1, 0];
        //RatioChance 0
        rarities[5] = [255];
        aliases[5] = [0];
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    /** CRITICAL TO SETUP */
    modifier requireContractsSet() {
        require(
            address(raw) != address(0) &&
                address(pirateNFT) != address(0) &&
                address(colonistNFT) != address(0) &&
                address(pytheas) != address(0) &&
                address(orbital) != address(0) &&
                address(imperialGuild) != address(0),
            "Contracts not set"
        );
        _;
    }

    function setContracts(
        address _rEON,
        address _pirateNFT,
        address _colonistNFT,
        address _pytheas,
        address _orbital,
        address _imperialGuild
    ) external onlyOwner {
        raw = IRAW(_rEON);
        pirateNFT = IPirates(_pirateNFT);
        colonistNFT = IColonist(_colonistNFT);
        pytheas = IPytheas(_pytheas);
        orbital = IOrbitalBlockade(_orbital);
        imperialGuild = IImperialGuild(_imperialGuild);
    }

    function getPendingMint(address addr)
        external
        view
        returns (MintCommit memory)
    {
        require(_pendingCommitId[addr] != 0, "no pending commits");
        return _mintCommits[addr][_pendingCommitId[addr]];
    }

    function hasMintPending(address addr) external view returns (bool) {
        return _pendingCommitId[addr] != 0;
    }

    function canMint(address addr) external view returns (bool) {
         uint16 commitIdCur = _pendingCommitId[addr];
         if (randomness.length == 1) {
            return 
            _pendingCommitId[addr] != 0;
         } else {
        return
            _pendingCommitId[addr] != 0 &&
            randomness.length >= commitIdCur;
         }
    }

     // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
         randomness.push(randomWords[0]);
    }


    function deleteCommit(address addr) external {
        require(
            auth == msg.sender || admins[msg.sender],
            "Only admins can call this"
        );

        uint16 commitIdCur = _pendingCommitId[addr];
        require(commitIdCur > 0, "No pending commit");
        delete _mintCommits[addr][commitIdCur];
        delete _pendingCommitId[addr];
    }

    function forceRevealCommit(address addr) external {
        require(
            auth == msg.sender || admins[msg.sender],
            "Only admins can call this"
        );
        pirateAttempt(addr);
    }

    function mintCommit(uint16 tokenId, bool stake)
        external
        whenNotPaused
        noCheaters
    {
        require(allowCommits, "adding commits disallowed");
        require(
            _pendingCommitId[msg.sender] == 0,
            "Already have pending mints"
        );
        uint16 piratesMinted = pirateNFT.piratesMinted();
        require(
            piratesMinted + pendingMintAmt + 1 <= 6000,
            "All tokens minted"
        );
        uint256 minted = colonistNFT.minted();
        uint256 maxTokens = colonistNFT.getMaxTokens();
        uint256 rawCost = rawMintCost(minted, maxTokens);

        raw.burn(1, rawCost, msg.sender);
        raw.updateOriginAccess(msg.sender);

        colonistNFT.transferFrom(msg.sender, address(this), tokenId);

        _mintCommits[msg.sender][_commitId] = MintCommit(stake, tokenId);
        _pendingCommitId[msg.sender] = _commitId;
        pendingMintAmt += 1;
        toggleCounter += 1;
        if (toggleCounter == toggleLimit) {
            requestRandomWords();
            toggleCounter = 0;
            _commitId += 1; 
        }
        emit MintCommitted(msg.sender, tokenId);
    }

    function mintReveal() external whenNotPaused noCheaters {
        pirateAttempt(msg.sender);
    }

    function pirateAttempt(address addr) internal {
        uint16 commitIdCur = _pendingCommitId[addr];
        require(commitIdCur >= 0, "No pending commit");
        require(randomness.length >= commitIdCur, "Random seed not set");
        MintCommit memory commit = _mintCommits[addr][commitIdCur];
        pendingMintAmt -= 1;
        uint16 colonistId = commit.tokenId;
        uint16 piratesMinted = pirateNFT.piratesMinted();
        uint256 seed = randomness[commitIdCur];
        uint256 circulation = colonistNFT.totalCir();
        uint8 chanceTable = getRatioChance(piratesMinted, circulation);
        seed = uint256(keccak256(abi.encode(seed, addr)));
        uint8 yayNay = getPirateResults(seed, chanceTable);
        // if the attempt fails, pay pirate tax and claim remaining
        if (yayNay == 0) {
            colonistNFT.safeTransferFrom(address(this), addr, colonistId);
        } else {
            colonistNFT.burn(colonistId);
            uint16[] memory pirateId = new uint16[](1);
            uint16[] memory pirateIdToStake = new uint16[](1);
            piratesMinted++;
            address recipient = selectRecipient(seed);
            if (
                recipient != addr &&
                imperialGuild.getBalance(addr, OnosiaLiquorId) > 0
            ) {
                // If the mint is going to be stolen, there's a 50% chance
                //  a pirate will prefer a fine crafted EON liquor over it
                if (seed & 1 == 1) {
                    imperialGuild.safeTransferFrom(
                        addr,
                        recipient,
                        OnosiaLiquorId,
                        1,
                        ""
                    );
                    recipient = addr;
                }
            }

            pirateId[0] = piratesMinted;
            if (!commit.stake || recipient != addr) {
                pirateNFT._mintPirate(recipient, seed);
            } else {
                pirateNFT._mintPirate(address(orbital), seed);
                pirateIdToStake[0] = piratesMinted;
            }
            pirateNFT.updateOriginAccess(pirateId);
            if (commit.stake) {
                orbital.addPiratesToCrew(addr, pirateIdToStake);
            }
            emit MintRevealed(addr, pirateId);
        }
        delete _mintCommits[addr][commitIdCur];
        delete _pendingCommitId[addr];
    }

    /**
     * @return the cost of the given token ID
     */
    function rawMintCost(uint256 tokenId, uint256 maxTokens)
        internal
        view
        returns (uint256)
    {
        if (tokenId <= (maxTokens * 8) / 24) return 4000; //10k-20k
        if (tokenId <= (maxTokens * 12) / 24) return 16000; //20k-30k
        if (tokenId <= (maxTokens * 16) / 24) return 48000; //30k-40k
        if (tokenId <= (maxTokens * 20) / 24) return 122500; //40k-50k
        if (tokenId <= (maxTokens * 22) / 24) return 250000; //50k-55k
        return maxRawEonCost;
    }

    function getRatioChance(uint256 pirates, uint256 circulation)
        public
        pure
        returns (uint8)
    {
        uint256 ratio = (pirates * 10000) / circulation;

        if (ratio <= 100) {
            return 0;
        } else if (ratio <= 300 && ratio >= 100) {
            return 1;
        } else if (ratio <= 500 && ratio >= 300) {
            return 2;
        } else if (ratio <= 800 && ratio >= 500) {
            return 3;
        } else if (ratio <= 999 && ratio >= 800) {
            return 4;
        } else {
            return 5;
        }
    }

    /**
     * Determines if an attempt to join the pirates is successful or not
     * granting a higher chance of success when the pirate to colonist ratio is
     * low, as the ratio gets closer to 10% the harder a chance at joining the pirates
     * becomes until ultimately they will not accept anyone else if the ratio is += 10%
    */
    function getPirateResults(uint256 seed, uint8 chanceTable)
        internal
        view
        returns (uint8)
    {
        seed >>= 16;
        uint8 yayNay = getResult(uint16(seed & 0xFFFF), chanceTable);
        return yayNay;
    }

    function getResult(uint256 seed, uint8 chanceTable)
        internal
        view
        returns (uint8)
    {
        uint8 result = uint8(seed) % uint8(rarities[chanceTable].length);
        // If the selected chance talbles rareity is selected (biased coin) return that
        if (seed >> 8 < rarities[chanceTable][result]) return result;
        // else return the aliases
        return aliases[chanceTable][result];
    }
    

    /** INTERNAL */

    /**
     * the first 10k colonist mints go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked pirate
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the pirate thief's owner)
     */
    function selectRecipient(uint256 seed) internal view returns (address) {
        if (((seed >> 245) % 10) != 0) return msg.sender; // top 10 bits
        address thief = orbital.randomPirateOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return msg.sender;
        return thief;
    }

     // Assumes the subscription is funded sufficiently.
    function adminRequestRandomWords() external {
        require(admins[msg.sender], "only admins can request randomness");
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }



    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setOnosiaLiquorId(uint256 typeId) external onlyOwner {
        OnosiaLiquorId = typeId;
    }

    function setAllowCommits(bool allowed) external onlyOwner {
        allowCommits = allowed;
    }

    function setToggleLimit(uint16 _toggleLimit) external onlyOwner {
        toggleLimit = _toggleLimit;
    }

    function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
        pendingMintAmt = uint16(pendingAmt);
    }

    function setVRFsub(bytes32 _keyHash, uint64 _s_subscriptionId, uint32 _callbackGasLimit, uint16 _requestConfirmations) external onlyOwner {
        keyHash = _keyHash;
        s_subscriptionId = _s_subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    function resetToggleCounter (uint16 _toggleCounter) external onlyOwner {
        toggleCounter = _toggleCounter;
    }

    /* enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disable
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function emergencyExtraction(address recipient, uint256 tokenId) external onlyOwner {
        colonistNFT.transferFrom(address(this), recipient, tokenId);
    }
}

