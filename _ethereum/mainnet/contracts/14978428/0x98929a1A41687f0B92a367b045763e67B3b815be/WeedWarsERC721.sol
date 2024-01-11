// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./OwnerOrAdmin.sol";
import "./Counters.sol";
import "./IWeedERC20.sol";

abstract contract WeedWarsERC721 is ERC721Burnable, OwnerOrAdmin {
    using Counters for Counters.Counter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable() {
        genesisTokenIdCounter._value = 556; // accounting for reserve
        genesisReserveTokenIdCounter._value = 0;
    }

    struct WeedWarsNft {
        uint16 face; // 0
        uint16 hat; // 1
        uint16 trousers; // 2
        uint16 tshirt; // 3
        uint16 boots; // 4
        uint16 jacket; // 5
        uint16 weapon; // 6
        uint16 background; // 7
        uint16 mergeCount; // 8
    }

    event Merge(
        address indexed _address,
        uint256 indexed _generation,
        uint256 _tokenId1,
        uint256 _tokenId2
    );

    event Resurrection(
        uint256 indexed _tokenId,
        address indexed _address,
        uint256 indexed _generation
    );

    Counters.Counter public generationCounter;
    Counters.Counter public genesisTokenIdCounter;
    Counters.Counter public genesisReserveTokenIdCounter;

    uint256 public constant GENESIS_MAX_SUPPLY = 4444;
    uint256 public constant RESERVE_QTY = 556;
    bool public IS_MERGE_ON;

    string public preRevealUrl;
    string public apiUrl;
    address public weedContractAddress;
    address public saleContractAddress;
    address public stakingContractAddress;

    // When warriors are minted for the first time this contract generates a random looking DNA mapped to a tokenID.
    // The actual uint16 properties of the warrior are later derived by decoding it with the
    // information that's inside of the generationRanges and generationRarities mappings.
    // Each generation of warriors will have its own set of rarities and property ranges
    // with a provenance hash uploaded ahead of time.
    // It gurantees that the actual property distribution is hidden during the pre-reveal phase since decoding depends on
    // the unknown information.
    // Property ranges are stored inside of a uint16[6] array per each property.
    // These 6 numbers are interpreted as buckets of traits. Traits are just sequential numbers.
    // For example [1, 100, 200, 300, 400, 500] value inside of generationRanges for the face property will be interpreted as:
    // - Common: 1-99
    // - Unusual: 100-199
    // - Rare: 200 - 299
    // - Super Rare: 300 - 399
    // - Legendary: 400 - 599
    //
    // The last two pieces of data are located inside of generationRarities mapping which holds uint16[4] arrays of rarities.
    // For example, if our rarities were defined as [40, 25, 20, 10], combined with buckets from above they will result in:
    // - Common: 1-99 [40% chance]
    // - Unusual: 100-199 [25% chance]
    // - Rare: 200 - 299 [20% chance]
    // - Super Rare: 300 - 399 [10% chance]
    // - Legendary: 400 - 599 [5% chance]
    //
    // This framework helps us to keep our trait generation random and hidden while still allowing for
    // clearly defined rarity categories.
    mapping(uint256 => mapping(uint256 => uint16[6])) public generationRanges;
    mapping(uint256 => uint16[4]) public generationRarities;
    mapping(uint256 => bool) public isGenerationRevealed;
    mapping(uint256 => uint256) public generationSeed;
    mapping(uint256 => uint256) public generationResurrectionChance;
    mapping(address => mapping(uint256 => uint256)) public resurrectionTickets;
    mapping(uint256 => uint256) private tokenIdToNft;
    mapping(uint256 => bool) public locked;

    // This mapping is going to be used to connect our ww store implementation and potential future
    // mechanics that will enhance this collection.
    mapping(address => bool) public authorizedToEquip;
    // Kill switch for the mapping above, if community decides that it's too dangerous to have this
    // list extendable we can prevent it from being modified.
    bool public isAuthorizedToEquipLocked;

    function _isTokenOwner(uint256 _tokenId) private view {
        require(
            ownerOf(_tokenId) == msg.sender,
            "WW: you don't own this token"
        );
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        _isTokenOwner(_tokenId);
        _;
    }

    modifier onlyAuthorizedToEquip() {
        require(authorizedToEquip[msg.sender], "WW: unauthorized");
        _;
    }

    modifier onlySaleContract() {
        require(saleContractAddress == msg.sender, "WW: only sale contract");
        _;
    }

    modifier onlyStakeContract() {
        require(stakingContractAddress == msg.sender, "WW: only staking contract");
        _;
    }

    function setAuthorizedToEquip(address _address, bool _isAuthorized) external onlyOwnerOrAdmin {
        require(!isAuthorizedToEquipLocked);
        authorizedToEquip[_address] = _isAuthorized;
    }

    function lockAuthorizedToEquip() external onlyOwnerOrAdmin {
        isAuthorizedToEquipLocked = true;
    }

    function setApiUrl(string calldata _apiUrl) external onlyOwnerOrAdmin {
        apiUrl = _apiUrl;
    }

    function setPreRevealUrl(string calldata _preRevealUrl) external onlyOwnerOrAdmin {
        preRevealUrl = _preRevealUrl;
    }

    function setWeedContractAddress(address _address) external onlyOwner {
        weedContractAddress = _address;
    }

    function setSaleContractAddress(address _address) external onlyOwner {
        saleContractAddress = _address;
    }

    function setStakingContractAddress(address _address) external onlyOwner {
        stakingContractAddress = _address;
    }

    function setIsMergeOn(bool _isMergeOn) external onlyOwnerOrAdmin {
        IS_MERGE_ON = _isMergeOn;
    }

    function setIsGenerationRevealed(uint256 _gen, bool _isGenerationRevealed) external onlyOwnerOrAdmin {
        require(!isGenerationRevealed[_gen]);
        isGenerationRevealed[_gen] = _isGenerationRevealed;
    }

    function setGenerationRanges(
        uint256 _gen,
        uint16[6] calldata _face,
        uint16[6] calldata _hat,
        uint16[6] calldata _trousers,
        uint16[6] calldata _tshirt,
        uint16[6] calldata _boots,
        uint16[6] calldata _jacket,
        uint16[6] calldata _weapon,
        uint16[6] calldata _background
    ) external onlyOwnerOrAdmin {
        require(!isGenerationRevealed[_gen]);

        generationRanges[_gen][0] = _face;
        generationRanges[_gen][1] = _hat;
        generationRanges[_gen][2] = _trousers;
        generationRanges[_gen][3] = _tshirt;
        generationRanges[_gen][4] = _boots;
        generationRanges[_gen][5] = _jacket;
        generationRanges[_gen][6] = _weapon;
        generationRanges[_gen][7] = _background;
    }

    function setGenerationRarities(
        uint256 _gen,
        uint16 _common,
        uint16 _unusual,
        uint16 _rare,
        uint16 _superRare
    ) external onlyOwnerOrAdmin {
        require(!isGenerationRevealed[_gen]);
        generationRarities[_gen] = [_common, _unusual, _rare, _superRare];
    }

    function startNextGenerationResurrection(uint256 _resurrectionChance) external onlyOwnerOrAdmin {
        require(!IS_MERGE_ON);
        generationCounter.increment();
        uint256 gen = generationCounter.current();
        generationSeed[gen] = _getSeed();
        generationResurrectionChance[gen] = _resurrectionChance;
    }

    function mintReserveBulk(address[] memory _addresses, uint256[] memory _claimQty) external onlyOwner {

        require(
            _addresses.length == _claimQty.length
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            mintReserve(_addresses[i], _claimQty[i]);
        }
    }

    function mintReserve(address _address, uint256 _claimQty) public onlyOwner {

        require(
            genesisReserveTokenIdCounter.current() + _claimQty <= RESERVE_QTY
        );

        for (uint256 i = 0; i < _claimQty; i++) {
            genesisReserveTokenIdCounter.increment();
            _mint(_address, genesisReserveTokenIdCounter.current(), 0);
        }
    }

    function mint(uint256 _claimQty, address _reciever) external onlySaleContract {
        require(
            genesisTokenIdCounter.current() + _claimQty <= GENESIS_MAX_SUPPLY,
            "WW: exceeds max warriors supply"
        );

        for (uint256 i = 0; i < _claimQty; i++) {
            genesisTokenIdCounter.increment();
            _mint(_reciever, genesisTokenIdCounter.current(), 0);
        }
    }

    function _mint(
        address _address,
        uint256 _tokenId,
        uint256 _gen
    ) private {
        uint256 dna = uint256(
            keccak256(abi.encodePacked(_address, _tokenId, _getSeed()))
        );

        // When warriors are generated for the first time
        // the last 9 bits of their DNA will be used to store the generation number (8 bit)
        // and a flag that indicates whether the dna is in its encoded
        // or decoded state (1 bit).

        // Generation number will help to properly decode properties based on
        // property ranges that are unknown during minting.

        // ((dna >> 9) << 9) clears the last 9 bits.
        // _gen * 2 moves generation information one bit to the left and sets the last bit to 0.
        dna = ((dna >> 9) << 9) | (uint8(_gen) * 2);
        tokenIdToNft[_tokenId] = dna;
        _safeMint(_address, _tokenId);
    }

    function canResurrect(address _address, uint256 _tokenId) public view returns (bool) {
        // Check if resurrection ticket was submitted
        uint256 currentGen = generationCounter.current();
        uint256 resurrectionGen = resurrectionTickets[_address][_tokenId];
        if (resurrectionGen == 0 || resurrectionGen != currentGen) {
            return false;
        }

        // Check if current generation was seeded
        uint256 seed = generationSeed[currentGen];
        if (seed == 0) {
            return false;
        }

        // Check if this token is lucky to be reborn
        if (
            (uint256(keccak256(abi.encodePacked(_tokenId, seed))) % 100) >
            generationResurrectionChance[currentGen]
        ) {
            return false;
        }

        return true;
    }

    function resurrect(uint256 _tokenId) external {
        require(canResurrect(msg.sender, _tokenId), "WW: cannot be resurrected");

        delete resurrectionTickets[msg.sender][_tokenId];

        uint256 gen = generationCounter.current();
        _mint(msg.sender, _tokenId, gen);
        emit Resurrection(_tokenId, msg.sender, gen);
    }

    function setLock(uint256 _tokenId, address _owner, bool _isLocked) external onlyStakeContract {
        require(ownerOf(_tokenId) == _owner, "WW: not own NFT");
        locked[_tokenId] = _isLocked;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal view override {
        require(locked[tokenId] == false, "WW: token is locked");
    }

    function merge(
        uint256 _tokenId1,
        uint256 _tokenId2,
        uint16[8] calldata _w
    ) external onlyTokenOwner(_tokenId1) onlyTokenOwner(_tokenId2) {
        require(
            weedContractAddress != address(0) && IS_MERGE_ON,
            "WW: merge is not active"
        );
        require(locked[_tokenId1] == false, "WW: token is locked");
        require(locked[_tokenId2] == false, "WW: token is locked");

        WeedWarsNft memory w1 = get(_tokenId1);
        WeedWarsNft memory w2 = get(_tokenId2);

        require(
            (_w[0] == w1.face || _w[0] == w2.face) &&
                (_w[1] == w1.hat || _w[1] == w2.hat) &&
                (_w[2] == w1.trousers || _w[2] == w2.trousers) &&
                (_w[3] == w1.tshirt || _w[3] == w2.tshirt) &&
                (_w[4] == w1.boots || _w[4] == w2.boots) &&
                (_w[5] == w1.jacket || _w[5] == w2.jacket) &&
                (_w[6] == w1.weapon || _w[6] == w2.weapon) &&
                (_w[7] == w1.background || _w[7] == w2.background),
            "WW: invalid property transfer"
        );

        _burn(_tokenId2);

        // Once any composability mechanic is used warrior traits become fully decoded
        // for the ease of future trait transfers between generations.
        tokenIdToNft[_tokenId1] = _generateDecodedDna(
            WeedWarsNft(
                _w[0],
                _w[1],
                _w[2],
                _w[3],
                _w[4],
                _w[5],
                _w[6],
                _w[7],
                w1.mergeCount + w2.mergeCount + 1
            )
        );

        uint256 gen = generationCounter.current();

        // Burned token has a chance of resurrection during the next generation.
        resurrectionTickets[msg.sender][_tokenId2] = gen + 1;
        emit Merge(msg.sender, gen, _tokenId1, _tokenId2);
    }

    function equipProperties(
        address _originalCaller,
        uint256 _tokenId,
        uint16[8] calldata _w
    ) external onlyAuthorizedToEquip {
        require(
            ownerOf(_tokenId) == _originalCaller,
            "WW: you don't own this token"
        );
        require(locked[_tokenId] == false, "WW: token is locked");

        WeedWarsNft memory w = get(_tokenId);

        w.face = _w[0] == 0 ? w.face : _w[0];
        w.hat = _w[1] == 0 ? w.hat : _w[1];
        w.trousers = _w[2] == 0 ? w.trousers : _w[2];
        w.tshirt = _w[3] == 0 ? w.tshirt : _w[3];
        w.boots = _w[4] == 0 ? w.boots : _w[4];
        w.jacket = _w[5] == 0 ? w.jacket : _w[5];
        w.weapon = _w[6] == 0 ? w.weapon : _w[6];
        w.background = _w[7] == 0 ? w.background : _w[7];

        tokenIdToNft[_tokenId] = _generateDecodedDna(w);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "WW: warrior doesn't exist");


        if (bytes(apiUrl).length == 0 || !_isDnaRevealed(tokenIdToNft[_tokenId])) {
            return string(
                abi.encodePacked(
                    preRevealUrl,
                    _toString(_tokenId)
                ));
        }

        WeedWarsNft memory w = get(_tokenId);
        string memory separator = "-";
        return
            string(
                abi.encodePacked(
                    apiUrl,
                    abi.encodePacked(
                        _toString(_tokenId),
                        separator,
                        _toString(w.face),
                        separator,
                        _toString(w.hat),
                        separator,
                        _toString(w.trousers)
                    ),
                    abi.encodePacked(
                        separator,
                        _toString(w.tshirt),
                        separator,
                        _toString(w.boots),
                        separator,
                        _toString(w.jacket)
                    ),
                    abi.encodePacked(
                        separator,
                        _toString(w.weapon),
                        separator,
                        _toString(w.background),
                        separator,
                        _toString(w.mergeCount)
                    )
                )
            );
    }

    function _getSeed() private view returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }

    function _generateDecodedDna(WeedWarsNft memory _w) private pure returns (uint256) {
        uint256 dna = _w.mergeCount; // 8
        dna = (dna << 16) | _w.background; // 7
        dna = (dna << 16) | _w.weapon; // 6
        dna = (dna << 16) | _w.jacket; // 5
        dna = (dna << 16) | _w.boots; // 4
        dna = (dna << 16) | _w.tshirt; // 3
        dna = (dna << 16) | _w.trousers; // 2
        dna = (dna << 16) | _w.hat; // 1
        dna = (dna << 16) | _w.face; // 0
        dna = (dna << 1) | 1; // flag indicating whether this dna was decoded
        // Decoded DNA won't have a generation number anymore.
        // These traits will permanently look decoded and no further manipulation will be needed
        // apart from just extracting it with a bitshift.

        return dna;
    }

    function _isDnaRevealed(uint256 _dna) private view returns (bool) {
        // Check the last bit to see if dna is decoded.
        if (_dna & 1 == 1) {
            return true;
        }

        // If dna wasn't decoded we wanna look up whether the generation it belongs to was revealed.
        return isGenerationRevealed[(_dna >> 1) & 0xFF];
    }

    function get(uint256 _tokenId) public view returns (WeedWarsNft memory) {
        uint256 dna = tokenIdToNft[_tokenId];
        require(_isDnaRevealed(dna), "WW: warrior is not revealed yet");

        WeedWarsNft memory w;
        w.face = getProperty(dna, 0);
        w.hat = getProperty(dna, 1);
        w.trousers = getProperty(dna, 2);
        w.tshirt = getProperty(dna, 3);
        w.boots = getProperty(dna, 4);
        w.jacket = getProperty(dna, 5);
        w.weapon = getProperty(dna, 6);
        w.background = getProperty(dna, 7);
        w.mergeCount = getProperty(dna, 8);

        return w;
    }

    function getMergeCount(uint256 _tokenId) public view returns (uint) {
        uint256 dna = tokenIdToNft[_tokenId];
        return getProperty(dna, 8);
    }

    function getProperty(uint256 _dna, uint256 _propertyId) private view returns (uint16) {
        // Property right offset in bits.
        uint256 bitShift = _propertyId * 16;

        // Last bit shows whether the dna was already decoded.
        // If it was we can safely return the stored value after bitshifting and applying a mask.
        // Decoded values don't have a generation number, so only need to shift by one bit to account for the flag.
        if (_dna & 1 == 1) {
            return uint16(((_dna >> 1) >> bitShift) & 0xFFFF);
        }

        // Every time warriors get merged their DNA will be decoded.
        // If we got here it means that it wasn't decoded and we can safely assume that their mergeCount counter is 0.
        if (_propertyId == 8) {
            return 0;
        }

        // Minted generation number is stored inside of 8 bits after the encoded/decoded flag.
        uint256 gen = (_dna >> 1) & 0xFF;

        // Rarity and range values to decode the property (specific to generation)
        uint16[4] storage _rarity = generationRarities[gen];
        uint16[6] storage _range = generationRanges[gen][_propertyId];

        // Extracting the encoded (raw) property (also shifting by 9bits first to account for generation metadata and a flag).
        // This property is just a raw value, it will get decoded with _rarity and _range information from above.
        uint256 encodedProp = (((_dna >> 9) >> bitShift) & 0xFFFF);

        // A value that will dictate from which pool of properties we should pull (common, uncommon, rare)
        uint256 rarityDecider = (uint256(
            keccak256(abi.encodePacked(_propertyId, _dna, _range))
        ) % 100) + 1;

        uint256 rangeStart;
        uint256 rangeEnd;

        // There is an opportunity to optimize for SLOAD operations here by byte packing all
        // rarity/range information and loading it in get before this function
        // is called to minimize state access.
        if (rarityDecider <= _rarity[0]) {
            // common
            rangeStart = _range[0];
            rangeEnd = _range[1];
        } else if (rarityDecider <= _rarity[1] + _rarity[0]) {
            // unusual
            rangeStart = _range[1];
            rangeEnd = _range[2];
        } else if (rarityDecider <= _rarity[2] + _rarity[1] + _rarity[0]) {
            // rare
            rangeStart = _range[2];
            rangeEnd = _range[3];
        } else if (rarityDecider <= _rarity[3] + _rarity[2] + _rarity[1] + _rarity[0]) {
            // super rare
            rangeStart = _range[3];
            rangeEnd = _range[4];
        } else {
            // legendary
            rangeStart = _range[4];
            rangeEnd = _range[5];
        }

        // Returns a decoded property that will fall within one of the rarity buckets.
        return uint16((encodedProp % (rangeEnd - rangeStart)) + rangeStart);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
