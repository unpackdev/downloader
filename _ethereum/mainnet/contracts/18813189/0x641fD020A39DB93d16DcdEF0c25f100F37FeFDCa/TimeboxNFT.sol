// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721SeaDropUpgradeable.sol";
import "./MerkleProof.sol";

/*
 * @notice ERC721SeaDropUpgradeable for 'timeboxes'
 *         - mintSeaDrop
 *         + mintInLab (timebox and meerkat owner or contract owner)
 *         + setRevelLevel (timebox owner or contract owner)
 * Start index must be 1
 */
contract TimeboxNFT is ERC721SeaDropUpgradeable {
    struct MintParams {
        address to;
        uint256 worriedMeerkatID;
        uint256 digitalTimeboxID;
        uint256 potionsNum;
    }

    struct Parents {
        uint256 parentMeerkatNFTId;
        uint256 parentTimeboxDigitalId;
    }

    struct StakeInfo {
        bool staked;
        uint256 stakedAt;
    }

    struct State {
        address owner;
        bool staked;
        uint256 stakedAt;
        uint256 level;
    }

    bytes32 public merkleRootForLabMint; // (owner address, Digital Timebox id, potions num)
    bytes32 public merkleRootForLevels; // (id, maxLevel)
    mapping(uint256 => uint256) public levels; // tokenId => level

    address private _worriedMeerkatContract; // WorriedMeerkat contract address
    address private _updateManager;

    mapping(uint256 => uint256) private _digitalToTokenId; // timeboxDigitalId => tokenId
    mapping(uint256 => Parents) private _parents; // tokenId => Parents
    mapping(address => uint256) private _potionsUsed; // address => num of used potions
    mapping(uint256 => StakeInfo) private _staked; // tokenId => StakeInfo
    mapping(uint256 => uint256) private _meerkatUsage; // tokenId => meerkt id

    event LeveledUp(
        uint256 tokenId,
        uint256 oldLevel,
        uint256 newLevel,
        uint256 maxLevel,
        uint256 revealedAt
    );

    event MintedInLab(
        address to,
        uint256 worriedMeerkatID,
        uint256 digitalTimeboxID,
        uint256 tokenId,
        uint256 mintedAt
    );

    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    /**
     * @notice Initialize the token contract with its name, symbol and allowed SeaDrop addresses.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop,
        address worriedMeerkatContract
    ) external initializer initializerERC721A {
        require(
            address(0) != worriedMeerkatContract,
            'Provide valid Worried Meerkat contract address'
        );
        ERC721SeaDropUpgradeable.__ERC721SeaDrop_init(
            name,
            symbol,
            allowedSeaDrop
        );

        _worriedMeerkatContract = worriedMeerkatContract;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //************************
    // SETTERS
    //************************

    function setMerkleRootForLevels(bytes32 merkleRoot)
        public
        onlyOwnerOrUpdateManager
    {
        merkleRootForLevels = merkleRoot;
    }

    function setMerkleRootForLabMint(bytes32 merkleRoot)
        public
        onlyOwnerOrUpdateManager
    {
        merkleRootForLabMint = merkleRoot;
    }

    function setUpdateManager(address updateManager) public onlyOwner {
        require(
            address(0) != updateManager,
            'Provide valid Worried Meerkat contract address'
        );
        _updateManager = updateManager;
    }

    //***********************
    // ACTIONS
    //***********************

    function mintSeaDrop(address, uint256) external virtual override {
        revert('DISABLED BY DESIGN. USE mintOneDerived');
    }

    function mintInLab(
        MintParams calldata params,
        bytes32[] calldata merkleProof
    ) public nonReentrant {
        require(
            msg.sender == params.to || msg.sender == owner(),
            'UNAUTHORIZED'
        );

        require(
            _digitalToTokenId[params.digitalTimeboxID] == 0,
            'Timebox already used'
        );

        require(
            _potionsUsed[params.to] < params.potionsNum,
            "You don't have enough potions"
        );

        if (_totalMinted() + 1 > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + 1,
                maxSupply()
            );
        }

        _validateMeerkat(params.to, params.worriedMeerkatID);

        require(
            _isLabMintProofValid(params, merkleProof),
            'You must provide a valid merkle proof'
        );

        // also see ERC721AUpgradeable._mint,
        uint256 tokenId = _nextTokenId();
        _safeMint(params.to, 1);
        _digitalToTokenId[params.digitalTimeboxID] = tokenId;
        _parents[tokenId] = Parents(
            params.worriedMeerkatID,
            params.digitalTimeboxID
        );
        _potionsUsed[params.to]++;
        _meerkatUsage[params.worriedMeerkatID] = block.timestamp;

        emit MintedInLab(
            params.to,
            params.worriedMeerkatID,
            params.digitalTimeboxID,
            tokenId,
            block.timestamp
        );
    }

    function stake(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            'You are not the owner of the token'
        );

        require(!_staked[tokenId].staked, 'Token already staked');

        _staked[tokenId] = StakeInfo({
            staked: true,
            stakedAt: block.timestamp
        });

        emit Locked(tokenId);
    }

    function unstake(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            'You are not the owner of the token'
        );

        require(_staked[tokenId].staked, 'Token not staked');

        _staked[tokenId].staked = false;

        emit Unlocked(tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256
    ) internal virtual override {
        if (from != address(0) && to != address(0)) {
            require(!_staked[startTokenId].staked, 'Token staked');
        }
    }

    function revealLevel(
        uint256 tokenId,
        uint256 newLevel,
        uint256 maxLevel,
        bytes32[] calldata merkleProof
    ) public nonReentrant {
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            'UNAUTHORIZED'
        );

        uint256 oldLevel = levels[tokenId];
        require(newLevel <= maxLevel, 'New level is too high');
        require(newLevel > oldLevel, 'New level is too low');
        require(_staked[tokenId].staked, 'Token not staked');
        require(
            _isMaxLevelProofValid(tokenId, maxLevel, merkleProof),
            'You must provide a valid merkle proof'
        );

        levels[tokenId] = newLevel;

        emit LeveledUp({
            tokenId: tokenId,
            oldLevel: oldLevel,
            newLevel: newLevel,
            maxLevel: maxLevel,
            revealedAt: block.timestamp
        });
    }

    function state(uint256 tokenId) public view returns (State memory) {
        return
            State({
                owner: ownerOf(tokenId),
                staked: _staked[tokenId].staked,
                stakedAt: _staked[tokenId].stakedAt,
                level: levels[tokenId]
            });
    }

    //**********************
    // GETTERS
    //**********************

    function getRevealLevel(uint256 tokenId) public view returns (uint256) {
        return levels[tokenId];
    }

    function getParents(uint256 tokenId) public view returns (Parents memory) {
        return _parents[tokenId];
    }

    //**************************
    // PRIVATE
    //**************************

    function _isMaxLevelProofValid(
        uint256 tokenId,
        uint256 maxLevel,
        bytes32[] calldata merkleProof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(tokenId, maxLevel)))
        );

        return MerkleProof.verify(merkleProof, merkleRootForLevels, leaf);
    }

    function _isLabMintProofValid(
        MintParams memory params,
        bytes32[] calldata proof
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(
                        params.to,
                        params.digitalTimeboxID,
                        params.potionsNum
                    )
                )
            )
        );
        return MerkleProof.verify(proof, merkleRootForLabMint, leaf);
    }

    function _validateMeerkat(address owner, uint256 worriedMeerkatID)
        private
        view
    {
        require(
            block.timestamp - _meerkatUsage[worriedMeerkatID] >= 5 days,
            'Worried meerkat already used'
        );

        WorriedMeerkatInterface wm = WorriedMeerkatInterface(
            _worriedMeerkatContract
        );
        WorriedMeerkatInterface.State memory meerkatState = wm.state(
            worriedMeerkatID
        );

        require(
            meerkatState.owner == owner,
            'You are not the owner of the worried meerkat'
        );

        require(
            meerkatState.staked,
            'Worried meerkat should be staked for at least 5 days'
        );

        require(meerkatState.revealed, 'Worried meerkat should be revealed');

        require(
            block.timestamp - meerkatState.stakedAt >= 5 days,
            'Worried meerkat should be staked for at least 5 days'
        );
    }

    modifier onlyOwnerOrUpdateManager() {
        if (_updateManager != address(0) && _updateManager == msg.sender) {
            _;

            return;
        }

        _checkOwner();
        _;
    }
}

contract WorriedMeerkatInterface {
    struct State {
        address owner;
        bool staked;
        uint256 stakedAt;
        bool revealed;
    }

    function state(uint256 tokenId) public view returns (State memory) {}
}
