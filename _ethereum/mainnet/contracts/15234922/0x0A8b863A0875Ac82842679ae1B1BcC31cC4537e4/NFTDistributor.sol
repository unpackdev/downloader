// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WhiteListV2.sol";
import "./INFTCore.sol";
import "./ReentrancyGuard.sol";
import "./RandomlyAssigned.sol";

/**
 * NFTDistributor provides a free NFT mint using the companion ERC721
 * contract (the addrsses of which is passed in deployment). The NFTDistributor
 * supports two phases: private and public. During private phase the user
 * must be on a whitelist (implemented via a merkle tree). During the public
 * phase, the NFT maybe minited by anyone (per address cap is enforced by
 * the mint function).
 */
contract NFTDistributor is ReentrancyGuard, WhiteListV2, RandomlyAssigned {
    // emited when the Distributor is opened for mint
    event DistributorStart(uint256 timestamp);

    // emitted when hash over metadata file is recorded in the contract
    // this is done prior to start of the mint.  The indexes for each
    // nft that is minted are then randomly (best effort) assigned.
    // Note that this is a free mint a more secure random function
    // like from chainlink is not used for this scenario.
    event MetaDataHashSet(bytes32 hash, uint256 timestamp);

    // emits whenver timeline of the min is updated
    event DistributorConfSet(
        uint256 privatePhaseHours,
        uint256 publicPhaseHours
    );
    // emitted whenever an nft is minted
    event DistributorMintedToken(
        address indexed to,
        uint256 indexed startTokId,
        uint256 quantity
    );

    // tracks how many nfts issued to a given address
    // during the private and public phases
    struct balance {
        uint256 privCount;
        uint256 pubCount;
    }

    struct distributorState {
        uint256 startTime;
        // Set before the very first nft is minted
        bytes32 metadataHash;
        // tracks nft quantities per address
        // to enforce per address quotas
        mapping(address => balance) balances;
        // tokenID to randomly (best effort)
        // assigned metaData index
        mapping(uint256 => uint256) mixer;
        bool paused;
    }

    struct distributorConf {
        // duration of the private minting phase
        uint256 privatePhaseHours;
        // duration of the public minting phase
        uint256 publicPhaseHours;
        uint256 perUserPublicQuota;
        string wlistID;
        address nftAddress;
        // max number of nfts that can be
        // issued in a single call
        uint256 maxNftsPerRequest;
        // upper bound on number of nfts that
        // will be minted by the NFTDistributor
        // contract.
        uint256 maxSupply;
    }

    distributorState private distState;
    distributorConf public distConf;

    constructor(
        uint256 _privatePhaseHours,
        uint256 _publicPhaseHours,
        uint256 _perUserPublicQuota,
        string memory _wlistID,
        address _nftAddress,
        uint256 _maxNftsPerRequest,
        uint256 _maxSupply
    ) RandomlyAssigned(_maxSupply, 1) {
        distConf = distributorConf(
            _privatePhaseHours,
            _publicPhaseHours,
            _perUserPublicQuota,
            _wlistID,
            _nftAddress,
            _maxNftsPerRequest,
            _maxSupply
        );
    }

    /**
     * Returns true if minting is currently only open to
     * white listed addresses, false otherwise.
     */
    function isInPrivatePhase() public view returns (bool) {
        if (
            distState.startTime == 0 || isPaused() || remainingInventory() == 0
        ) {
            return false;
        }

        uint256 secondsElapsed = block.timestamp - distState.startTime;
        return (secondsElapsed < distConf.privatePhaseHours * 3600);
    }

    /**
     * Returns true if minting is currently open to any address.
     */
    function isInPublicPhase() public view returns (bool) {
        if (
            distState.startTime == 0 || isPaused() || remainingInventory() == 0
        ) {
            return false;
        }
        uint256 secondsElapsed = block.timestamp - distState.startTime;
        return ((secondsElapsed >= distConf.privatePhaseHours * 3600) &&
            (secondsElapsed <
                (distConf.privatePhaseHours + distConf.publicPhaseHours) *
                    3600));
    }

    /**
     * Returns true if minting is in either private or public phase
     */
    function isDistributorOpen() public view returns (bool) {
        return (isInPrivatePhase() || isInPublicPhase());
    }

    /**
     * Returns the number of NFTs that can still be minted.
     */
    function remainingInventory() public view returns (uint256) {
        INFTCore nft = INFTCore(distConf.nftAddress);
        if (distConf.maxSupply > nft.totalSupply()) {
            return (distConf.maxSupply - nft.totalSupply());
        } else {
            return 0;
        }
    }

    /**
     * Support of updates to minting config.
     */
    function setDistributorConf(
        uint256 _privatePhaseHours,
        uint256 _publicPhaseHours,
        uint256 _perUserPublicQuota,
        string memory _wlistID,
        // max number of nfts that can be issued in a single call
        uint256 _maxNftsPerRequest
    ) external onlySU {
        distConf.privatePhaseHours = _privatePhaseHours;
        distConf.publicPhaseHours = _publicPhaseHours;
        distConf.perUserPublicQuota = _perUserPublicQuota;
        distConf.wlistID = _wlistID;
        distConf.maxNftsPerRequest = _maxNftsPerRequest;

        emit DistributorConfSet(_privatePhaseHours, _publicPhaseHours);
    }

    /**
     * Registers the hash over of the external metadata file. Serves as part
     * of evidence chain that nft to metadata mapping was not manipulated.
     */
    function setMetadataHash(bytes32 hash) external onlySU {
        distState.metadataHash = hash;
        emit MetaDataHashSet(hash, block.timestamp);
    }

    /**
     * Puases the mint proccess.
     */
    function pause() external onlySU {
        distState.paused = true;
    }

    /**
     * Unpauses the mint proccess.
     */
    function unpause() external onlySU {
        distState.paused = false;
    }

    /**
     * Returns true if mint is paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return distState.paused;
    }

    /**
     * Returns the registed metadata hash.
     */
    function getMetadataHash() public view returns (bytes32) {
        return distState.metadataHash;
    }

    /**
     * Returns the startime in seconds, of the mint event.
     * The return value will be 0 if the mint was not started yet.
     */
    function getStartTime() public view returns (uint256) {
        return distState.startTime;
    }

    /**
     * Opens the mint, begining the private phase.
     */
    function startDistributor() external onlySU {
        require(distState.startTime == 0, "distributor already started");
        distState.startTime = block.timestamp;
        emit DistributorStart(block.timestamp);
    }

    /**
     * Returns the number of NFts a given address has remaining to mint.
     * Takes into account private vs. public phase as well as associated quotas.
     */
    function getRemainingCount(
        address user,
        bytes32[] memory proof,
        string memory leafSource
    ) external view returns (uint256 remaining) {
        uint256 maxCap;
        uint256 ownCount;
        // whitelist check
        if (isInPrivatePhase()) {
            bool authorized;
            (authorized, maxCap) = isOnWhiteList(
                distConf.wlistID,
                proof,
                leafSource
            );
            ownCount = distState.balances[user].privCount;
        } else if (isInPublicPhase()) {
            ownCount = distState.balances[user].pubCount;
            maxCap = distConf.perUserPublicQuota;
        }

        if (maxCap <= ownCount) {
            return 0;
        } else {
            return (maxCap - ownCount);
        }
    }

    function _getRemainingCount(
        address user,
        bytes32[] memory proof,
        string memory leafSource
    ) internal returns (uint256 remaining) {
        uint256 maxCap;
        uint256 ownCount;
        // whitelist check
        if (isInPrivatePhase()) {
            bool authorized;
            (authorized, maxCap) = isAllowed(
                distConf.wlistID,
                proof,
                leafSource
            );
            
            require(authorized, "addr not on the whitelist");  
            ownCount = distState.balances[user].privCount;
        } else if (isInPublicPhase()) {
            ownCount = distState.balances[user].pubCount;
            maxCap = distConf.perUserPublicQuota;
        }

        if (maxCap <= ownCount) {
            return 0;
        } else {
            return (maxCap - ownCount);
        }
    }

    /**
     * Free NFT mint. If the mint is in the private phase then the calling address
     * must be on the white list (supported via merkle tree). Public mint is open
     * to all addresses (except for other contracts).  Mint quotas encoded in merkle
     * tree leaf nodes. Per address mint count is tracked and enforced by mintNFt.
     */
    function mintNft(
        bytes32[] memory proof,
        string memory leafSource,
        uint256 askCount
    ) external nonReentrant returns (uint256 tokID) {
        require(msg.sender.code.length == 0, "contract caller not allowed");
        require(isDistributorOpen(), "Distributor closed");
        require(remainingInventory() > 0, "Out of inventory");
        require(
            askCount > 0 && askCount <= distConf.maxNftsPerRequest,
            "nft mint ask out of range"
        );

        uint256 remainingCount = _getRemainingCount(
            msg.sender,
            proof,
            leafSource);
        require(remainingCount >= askCount, "no quantity remains");

        INFTCore nft = INFTCore(distConf.nftAddress);

        for (uint256 i = 0; i < askCount; i++) {
            uint256 _id = nft.mint(msg.sender);
            if (i == 0) {
                tokID = _id;
            }

            if (isInPrivatePhase()) {
                distState.balances[msg.sender].privCount++;
            } else {
                distState.balances[msg.sender].pubCount++;
            }
            distState.mixer[_id] = nextToken();
        }
        emit DistributorMintedToken(msg.sender, tokID, askCount);
    }

    /**
     * returns the randomly selected metadata index mapping for a given tokenID.
     * Note that this is a free mint a more secure random function
     * like from chainlink is not used for this scenario.
     */
    function getAssignedIndex(uint256 tokenId) external view returns (uint256) {
        INFTCore nft = INFTCore(distConf.nftAddress);
        // tokenID expected to start at 1 and consecutively go up to nftBatchSize
        require(
            tokenId > 0 && tokenId <= nft.totalSupply(),
            "tokenId out of bounds"
        );
        return distState.mixer[tokenId];
    }
}
