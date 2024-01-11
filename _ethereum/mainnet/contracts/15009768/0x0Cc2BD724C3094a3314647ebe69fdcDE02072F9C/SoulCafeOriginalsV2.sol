// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./Staking.sol";
import "./ICafeStaking.sol";
import "./StakingCommons.sol";
import "./Errors.sol";
import "./ERC721LockerUpgradeable.sol";
import "./ProxyRegistry.sol";

interface ICafeStakingInfo {
    function stakeInfoERC721(
        uint256 trackId,
        address account,
        uint256 page,
        uint256 records
    ) external view returns (uint256[] memory, uint256);
}

enum Phase {
    Whitelist,
    Community,
    OpenSale
}

struct Collection {
    uint128 communityPrice;
    uint128 price;
    uint32 starts;
    uint32 ends;
    uint32 cap;
    uint32 supply;
    uint32 pieces;
    uint32 merkleIndex;
    uint32 quota;
    Phase phase;
    bool paused;
    mapping(address => uint256) quotaWLMints;
    mapping(address => uint256) quotaOSMints;
    string placeholder;
    string uri;
}

struct MintRequest {
    uint256 collectionId;
    uint256[] pieceIds;
    uint256 index;
    uint256 amount;
    bytes32[] proof;
    bool autostake;
}

contract SoulCafeOriginalsV2 is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ERC721LockerUpgradeable
{
    using StringsUpgradeable for uint256;
    using AutoStaking for uint256;
    using AutoStaking for StakeAction;
    using AutoStaking for StakeRequest;

    // - constants, errors, events -
    event CollectionDeploy(
        uint256 indexed collectionId,
        uint256 indexed starts,
        uint256 indexed ends
    );
    event CollectionToggle(uint256 indexed collectionId, bool indexed newState);
    event MerkleRootUpdate(
        uint256 indexed collectionId,
        bytes32 indexed merkleRoot
    );
    event OriginalMint(
        uint256 indexed collectionId,
        uint256 indexed tokenId,
        uint32 indexed pieceId
    );
    event OwnerReclaim(uint256 indexed collectionId, uint256 indexed pieces);
    event OpenSalePriceSet(uint256 indexed collectionId, uint256 indexed price);
    event CommunityPriceSet(
        uint256 indexed collectionId,
        uint256 indexed price
    );
    event QuotaSet(uint256 indexed collectionId, uint256 indexed newQuota);
    event PhaseAdvance(uint256 indexed collectionId, Phase indexed newPhase);
    event CollectionURISet(uint256 indexed collectionId, string indexed newURI);

    address private constant CAFE_TEAM_WALLET =
        0x9cD59CD50625C7E2994BA6a2cf9b70c5a775E8db;
    address private constant TW = 0x78Cd6C571DeA180529C86ed42689dBDd0e5319ce;
    address private constant DW = 0x3497fC59721596c1cCD2eE68f1295C7C2D602F88;

    address private constant GENESIS =
        0xDb8F52d04F9156dd2167D2503a5a2CeEf3125B09;
    address private constant CARDS = 0xADEfddE659D620Deaf3d007F060DA324d216c2bc;

    uint256 private constant GENESIS_TRACK = 0;

    /* ========== STORAGE, APPEND-ONLY ========== */
    mapping(uint256 => Collection) public collections;
    uint256 public collectionsCount;

    mapping(uint32 => bytes32) public merkles;
    uint32 public merklesCount;
    uint256 public totalSupply;

    ICafeStaking _staking;
    uint256 _stakingTrack;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __ERC721_init("Soul Cafe Originals", "SCO");
        __Ownable_init();
        ERC721LockerUpgradeable.__init();
    }

    /* ========== VIEWS ========== */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function quotaUsed(
        uint256 collectionId,
        address account,
        bool wl
    ) external view returns (uint256) {
        _collectionExists(collectionId);
        if (wl) {
            return collections[collectionId].quotaWLMints[account];
        } else {
            return collections[collectionId].quotaOSMints[account];
        }
    }

    function isCommunityMember(address account) external view returns (bool) {
        return _isCommunityMember(account);
    }

    function tokensOfOwner(uint256 collectionId, address account)
        external
        view
        returns (uint256[] memory ids)
    {
        _collectionExists(collectionId);

        Collection storage coll = collections[collectionId];

        uint256[] memory tokenIds = new uint256[](coll.cap);
        uint256 counter;

        for (uint256 t = coll.starts; t <= coll.ends; t++) {
            if (_exists(t) && ownerOf(t) == account) {
                tokenIds[counter] = t;
                counter++;
            }
        }

        uint256[] memory tokenIds_ = new uint256[](counter);
        for (uint256 t = 0; t < counter; t++) {
            tokenIds_[t] = tokenIds[t];
        }

        return tokenIds_;
    }

    function stats(uint256 collectionId)
        external
        view
        returns (uint256 left, uint256 supply)
    {
        _collectionExists(collectionId);
        Collection storage coll = collections[collectionId];
        return (coll.cap - coll.supply, coll.supply);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert UnknownToken();

        uint256 collectionId;

        for (uint256 c = 0; c < collectionsCount; c++) {
            Collection storage coll = collections[c];
            if (coll.starts >= tokenId && tokenId <= coll.ends) {
                collectionId = c;
                break;
            }
        }

        Collection storage coll = collections[collectionId];

        if (bytes(coll.uri).length > 0) {
            return
                string(abi.encodePacked(coll.uri, tokenId.toString(), ".json"));
        } else {
            return coll.placeholder;
        }
    }

    /* ========== PUBLIC MUTATORS ========== */
    function mint(MintRequest calldata mr) external payable {
        _collectionExists(mr.collectionId);
        Collection storage coll = collections[mr.collectionId];
        if (coll.paused) revert CollectionPaused();
        _validPieceIds(coll.pieces, mr.pieceIds);

        Phase phase = coll.phase;

        bool isCommunityMember_ = (phase == Phase.Whitelist)? false : _isCommunityMember(msg.sender);
        bool isProofPresented = (mr.proof.length > 0);
        bool isProofPresentAndValid = isProofPresented &&
                _validateMerkleProof(
                    msg.sender,
                    mr.index,
                    mr.amount,
                    mr.proof,
                    merkles[coll.merkleIndex]
                );

        if (isProofPresented && !isProofPresentAndValid) revert InvalidMerkleProof();

        uint256 qt = mr.pieceIds.length;
        uint256 price = (isProofPresentAndValid || isCommunityMember_)? coll.communityPrice : coll.price;
        if (qt + coll.supply > coll.cap) revert MintingExceedsSupply(coll.cap);
        if (qt * price != msg.value) revert InvalidETHAmount();

        if (isProofPresentAndValid) {
            if (qt + coll.quotaWLMints[msg.sender] > mr.amount) revert MintingExceedsQuota();

            _mintN(msg.sender, mr.collectionId, coll, mr.pieceIds, true);
        } else {
            if (phase == Phase.Whitelist) revert InvalidMerkleProof();
            // community or open sale from here on
            if (!isCommunityMember_ && phase != Phase.OpenSale) revert NotInOpenSale(); 
            if (qt + coll.quotaOSMints[msg.sender] > coll.quota) revert MintingExceedsQuota();
            
            _mintN(msg.sender, mr.collectionId, coll, mr.pieceIds, false);
        }

        if (mr.autostake) {
            _autostake(msg.sender, qt);
        }
    }

    /* ========== ADMIN MUTATORS ========== */

    function configureStaking(address staking, uint256 trackId) external {
        _onlyOwner();
        _setLockerAdmin(staking);
        _staking = ICafeStaking(staking);
        _stakingTrack = trackId;
    }

    function deployCollection(
        uint256 cPrice,
        uint256 price,
        uint256 cap,
        uint256 pieces,
        bytes32 merkleRoot,
        uint256 quota,
        bool paused,
        string calldata placeholder
    ) external {
        _onlyOwner();

        if (cap == 0 || pieces == 0 || quota == 0)
            revert CantCreateZeroTokens();
        if (cPrice == 0 || price == 0) revert ZeroPrice();

        Collection storage coll = collections[collectionsCount];
        coll.communityPrice = uint128(cPrice);
        coll.price = uint128(price);
        coll.starts = (collectionsCount > 0)
            ? collections[collectionsCount - 1].ends + 1
            : 0;
        coll.ends = coll.starts + uint32(cap) - 1;
        coll.cap = uint32(cap);
        coll.pieces = uint32(pieces);

        merkles[merklesCount] = merkleRoot;
        coll.merkleIndex = merklesCount;
        merklesCount++;

        coll.quota = uint32(quota);
        coll.paused = paused;
        coll.placeholder = placeholder;

        _mintTeam(collectionsCount, coll);

        emit CollectionDeploy(collectionsCount, coll.starts, coll.ends);

        collectionsCount++;
    }

    function toggleCollection(uint256 collectionId) external {
        _onlyOwner();
        _collectionExists(collectionId);

        Collection storage coll = collections[collectionId];

        coll.paused = !coll.paused;

        emit CollectionToggle(collectionId, coll.paused);
    }

    function setCommunityPrice(uint256 collectionId, uint256 price) external {
        _onlyOwner();
        _collectionExists(collectionId);

        emit CommunityPriceSet(collectionId, price);

        Collection storage coll = collections[collectionId];
        coll.communityPrice = uint128(price);
    }

    function setOpenSalePrice(uint256 collectionId, uint256 price) external {
        _onlyOwner();
        _collectionExists(collectionId);

        emit OpenSalePriceSet(collectionId, price);

        Collection storage coll = collections[collectionId];
        coll.price = uint128(price);
    }

    function setQuota(uint256 collectionId, uint256 newQuota) external {
        _onlyOwner();
        _collectionExists(collectionId);

        emit QuotaSet(collectionId, newQuota);

        Collection storage coll = collections[collectionId];
        coll.quota = uint32(newQuota);
    }

    function nextPhase(uint256 collectionId) external {
        _onlyOwner();
        _collectionExists(collectionId);

        Collection storage coll = collections[collectionId];
        if (coll.phase == Phase.OpenSale) revert NoMorePhases();

        if (coll.phase == Phase.Whitelist) coll.phase = Phase.Community;
        else coll.phase = Phase.OpenSale;

        emit PhaseAdvance(collectionId, coll.phase);
    }

    function updateMerkleRoot(uint256 collectionId, bytes32 root) external {
        _onlyOwner();
        _collectionExists(collectionId);

        Collection storage coll = collections[collectionId];

        emit MerkleRootUpdate(collectionId, root);
        merkles[merklesCount] = root;
        coll.merkleIndex = merklesCount;
        merklesCount++;
    }

    function reclaim(uint256 collectionId, uint256[] calldata pieceIds)
        external
    {
        _onlyOwner();
        _collectionExists(collectionId);

        uint256 pieces = pieceIds.length;
        Collection storage coll = collections[collectionId];

        if (coll.supply + pieces > coll.cap)
            revert MintingExceedsSupply(coll.cap);

        emit OwnerReclaim(collectionId, pieces);

        for (uint256 p = 0; p < pieces; p++) {
            emit OriginalMint(collectionId, totalSupply + p, uint32(pieceIds[p]));
            _safeMint(CAFE_TEAM_WALLET, totalSupply + p);
        }
        totalSupply += pieces;
        coll.supply += uint32(pieces);
    }

    function setCollectionURI(uint256 collectionId, string calldata newURI)
        external
    {
        _onlyOwner();
        _collectionExists(collectionId);

        emit CollectionURISet(collectionId, newURI);
        Collection storage coll = collections[collectionId];
        coll.uri = newURI;
    }

    function withdraw() external {
        payable(DW).transfer(address(this).balance / 5);
        payable(TW).transfer(address(this).balance);
    }

    /* ========== INTERNALS/MODIFIERS ========== */
    function _mintTeam(uint256 collectionId, Collection storage coll) internal {
        for (uint256 p = 0; p < coll.pieces; p++) {
            emit OriginalMint(collectionId, totalSupply + p, uint32(p));
            _safeMint(CAFE_TEAM_WALLET, totalSupply + p);
        }
        totalSupply += coll.pieces;
        coll.supply += coll.pieces;
    }

    function _mintN(
        address to,
        uint256 collectionId,
        Collection storage coll,
        uint256[] calldata pieceIds,
        bool wlQuota
    ) internal {
        uint256 pieces = pieceIds.length;
        coll.supply += uint32(pieces);
        if (wlQuota) {
            coll.quotaWLMints[msg.sender] += pieces;
        } else {
            coll.quotaOSMints[msg.sender] += pieces;
        }

        for (
            uint256 tokenId = totalSupply;
            tokenId < totalSupply + pieces;
            tokenId++
        ) {
            emit OriginalMint(
                collectionId,
                tokenId,
                uint32(pieceIds[tokenId - totalSupply])
            );
            _safeMint(to, tokenId);
        }

        totalSupply += pieces;
    }

    function _validPieceIds(uint32 pieces, uint256[] calldata pieceIds)
        internal
        view
    {
        if (pieceIds.length == 0) revert ZeroTokensRequested();

        uint256[] memory counters = new uint256[](pieces);

        for (uint256 p = 0; p < pieceIds.length; p++) {
            if (pieceIds[p] >= pieces) revert InvalidPieceId();
            if (counters[pieceIds[p]] == 0) counters[pieceIds[p]] += 1;
            else revert DuplicatePieceId();
        }
    }

    function _isCommunityMember(address account) internal view returns (bool) {
        if (IERC1155Upgradeable(CARDS).balanceOf(account, 0) > 0) return true;
        if (IERC721Upgradeable(GENESIS).balanceOf(account) > 0) return true;

        (, uint256 balance) = ICafeStakingInfo(address(_staking))
            .stakeInfoERC721(GENESIS_TRACK, account, 0, 0);

        if (balance > 0) return true;
        return false;
    }

    function _collectionExists(uint256 collectionId) internal view {
        if (collectionId >= collectionsCount) revert CollectionNotFound();
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override(ERC721Upgradeable, IERC721Upgradeable)
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(OS_PROXY_REGISTRY_ADDRESS);
        if (address(proxyRegistry.proxies(owner_)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner_, operator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        to;

        if (from == address(0)) return;

        if (isLocked(tokenId)) {
            _autounstake(from, tokenId);   
        }
    }

    function _autostake(address account, uint256 tokenCount) internal {
        uint256[] memory ids = new uint256[](tokenCount);
        uint256 from = totalSupply - tokenCount;
        uint256 to = totalSupply;
        for (uint256 t = from; t < to; t++) {
            ids[t - from] = t;
        }

        uint256[] memory amounts;

        StakeRequest[] memory msr = StakeRequest(_stakingTrack, ids, amounts)
            .arrayify();

        StakeAction[][] memory actions = new StakeAction[][](1);
        actions[0] = StakeAction.Stake.arrayify();

        _staking.execute4(account, msr, actions);
    }

    function _autounstake(address account, uint256 tokenId) internal {
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;
        uint256[] memory amounts;
        StakeRequest[] memory msr = StakeRequest(_stakingTrack, ids, amounts).arrayify();

        StakeAction[][] memory actions = new StakeAction[][](1);
        actions[0] = StakeAction.Unstake.arrayify();

        _staking.execute4(account, msr, actions);
    }

    function _validateMerkleProof(
        address account,
        uint256 index,
        uint256 amount,
        bytes32[] calldata proof,
        bytes32 merkleRoot
    ) internal returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));

        return MerkleProofUpgradeable.verify(proof, merkleRoot, node);
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) {
            revert Unauthorized();
        }
    }
}
