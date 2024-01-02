// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./ECDSA.sol";
import "./ERC721.sol";

import "./Ownable.sol";
import "./DutchAuction.sol";
import "./DougTag.sol";
import "./DougBank.sol";
import "./IDougToken.sol";

uint8 constant MAX_SUPPLY_PER_TYPE = 127;
uint8 constant MAX_TOKENS_PER_REQUEST = 5;

/**
 * @title Doug
 * @dev Doug NFT
 */
contract Doug is Ownable, DutchAuction, ERC721, IDougToken {
    string private _uri;
    bool public revealed;
    bool public isFrozen;
    DougBank private _bank;
    DougTag private _tags;
    address private immutable _signer;
    mapping(uint256 => uint8) private _dougTypes;
    mapping(uint256 => uint8) private _dougRanks;
    mapping(uint256 => uint8) private _dougSeqNos;
    uint8[MAX_SUPPLY_PER_TYPE] private _tumblers;
    uint8[DOUG_TYPES][7] private _dougCounts;

    uint256 private _reserveMax;
    uint256 private _mergeCounter = 12700;
    uint256 private _mintCounter;
    uint256 private _invitePrice;
    uint256 private _inviteStartTime;

    constructor(
        string memory baseURI,
        address signer,
        uint256 invitePrice,
        uint256 reserveMax,
        uint256 initialPrice,
        uint256 minPrice,
        uint256 step,
        uint256 inviteStartTime,
        uint256 startTime
    )
        payable
        ERC721("Doug", "DOUG")
        DutchAuction(initialPrice, minPrice, step, startTime)
        Ownable(msg.sender)
    {
        _uri = baseURI;
        _signer = signer;
        _invitePrice = invitePrice;
        _reserveMax = reserveMax;
        _inviteStartTime = inviteStartTime;
        _tags = new DougTag(msg.sender);
        _bank = (new DougBank){value: msg.value}(address(this), msg.sender);
    }

    function dougsMinted() public view returns (uint256) {
        return _mintCounter;
    }

    function dougsRemaining() public view returns (uint256) {
        return 12700 - _mintCounter;
    }

    function getInviteStartTime() public view returns (uint256) {
        return _inviteStartTime;
    }

    function getInvitePrice() public view returns (uint256) {
        return _invitePrice;
    }

    function mintWithInvite(bytes memory nonce, bytes memory signature) public payable {
        require(msg.value >= _invitePrice, "Doug: incorrect price");
        require(_mintCounter >= _reserveMax, "Doug: reserve mint is incomplete");
        require(block.timestamp >= _inviteStartTime, "Doug: invites are not open");
        require(block.timestamp < startedAt, "Doug: auction already started");
        bytes memory message = abi.encodePacked(msg.sender, nonce);
        require(_signatureValid(message, signature), "Doug: invalid signature");
        _mint();
    }

    function mint(uint8 amount) public payable {
        require(amount <= MAX_TOKENS_PER_REQUEST, "Doug: unable to mint that many");
        require(msg.value >= currentPrice() * amount, "Doug: incorrect price");
        require(_mintCounter >= _reserveMax, "Doug: reserve mint is incomplete");
        require(block.timestamp >= startedAt, "Doug: auction has not started");

        for (uint8 i = 0; i < amount; i++) {
            _mint();
        }
    }

    function _mint() internal {
        require(_mintCounter < 12700, "Doug: no more supply");
        _mintCounter++;
        _dougRanks[_mintCounter] = 0;
        _safeMint(msg.sender, _mintCounter);
    }

    function merge(uint256 tokenA, uint256 tokenB) public {
        require(isFrozen, "Doug: merge not allowed");
        require(tokenA != tokenB, "Doug: can't merge with itself");
        require(ownerOf(tokenA) == msg.sender, "Doug: not owner of 1st token");
        require(ownerOf(tokenB) == msg.sender, "Doug: not owner of 2nd token");
        uint8 _dougRank = _dougRanks[tokenA];
        require(_dougRank == _dougRanks[tokenB], "Doug: rank mismatch");
        uint8 _dougType = dougType(tokenA);
        require(_dougType == dougType(tokenB), "Doug: type mismatch");
        uint8 _newRank = _dougRank + 1;

        uint8 tokenASequenceNumber = dougSequenceNumber(tokenA);
        uint8 tokenBSequenceNumber = dougSequenceNumber(tokenB);

        _burn(tokenA);
        _burn(tokenB);
        _mergeCounter++;
        uint256 tokenId = _mergeCounter;
        _dougRanks[tokenId] = _newRank;
        _dougTypes[tokenId] = _dougType;
        _dougSeqNos[tokenId] = _dougCounts[_newRank][_dougType];
        _dougCounts[_newRank][_dougType]++;

        _safeMint(msg.sender, tokenId);
        _tags.mint(msg.sender, _dougType, _dougRank, tokenASequenceNumber);
        _tags.mint(msg.sender, _dougType, _dougRank, tokenBSequenceNumber);

        _bank.onTokenMerged(_dougType, _newRank, tokenA, tokenB, tokenId);
    }

    function _signatureValid(bytes memory message, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
        return _signer == ECDSA.recover(messageHash, signature);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();

        // If post reveal
        if (revealed) {
            string memory seqNo = Strings.toString(dougSequenceNumber(tokenId));
            string memory rank = Strings.toString(_dougRanks[tokenId]);
            string memory tokenType = Strings.toString(dougType(tokenId));
            bytes memory fullUri = abi.encodePacked(
                baseURI,
                "doug_",
                tokenType,
                "_",
                rank,
                "_",
                seqNo,
                ".json"
            );
            return bytes(baseURI).length > 0 ? string(fullUri) : "";
        }

        // pre-reveal
        string memory tokenStr = Strings.toString(tokenId);
        bytes memory placeholderUri = abi.encodePacked(baseURI, "pre_doug_", tokenStr, ".json");
        return bytes(baseURI).length > 0 ? string(placeholderUri) : "";
    }

    function ownerOf(uint256 tokenId) public view override(ERC721, IDougToken) returns (address) {
        return ERC721.ownerOf(tokenId);
    }

    function randomNumber(uint8 max, uint8 index) internal view returns (uint8) {
        uint256 k = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, index)));
        return uint8(k % max);
    }

    function dougType(uint256 tokenId) public view returns (uint8) {
        if (_dougRanks[tokenId] > 0) {
            return _dougTypes[tokenId];
        }

        uint8 tumblerNumber = uint8(tokenId % MAX_SUPPLY_PER_TYPE);
        uint8 offset = _tumblers[tumblerNumber];
        uint8 tokenType = (uint8(tokenId / MAX_SUPPLY_PER_TYPE) + offset) % DOUG_TYPES;
        return tokenType;
    }

    function dougRank(uint256 tokenId) public view returns (uint8) {
        return _dougRanks[tokenId];
    }

    function dougSequenceNumber(uint256 tokenId) public view returns (uint8) {
        if (_dougRanks[tokenId] > 0) {
            return _dougSeqNos[tokenId];
        }

        return uint8(tokenId % MAX_SUPPLY_PER_TYPE);
    }

    // Admin utilities
    function mintReserve(uint16 amount, address to) public isOwner {
        require(_mintCounter + amount <= _reserveMax, "Doug: amount exceeds reserve max");
        require(_mintCounter + amount <= 12700, "Doug: no more supply");
        uint256 newTokenId = _mintCounter;
        unchecked {
            for (uint16 i = 0; i < amount; i++) {
                newTokenId++;
                _mint(to, newTokenId);
            }
        }

        _mintCounter = newTokenId;
    }

    function reveal(string memory baseURI) public isOwner {
        require(!isFrozen, "Doug: Cannot reveal after freeze");

        _uri = baseURI;
        revealed = true;

        // Assign Doug Type Tumblers
        for (uint8 i = 0; i < MAX_SUPPLY_PER_TYPE; i++) {
            _tumblers[i] = randomNumber(MAX_SUPPLY_PER_TYPE, i);
        }

        _tags.reveal(baseURI);
    }

    function mergeAllowed() public view returns (bool) {
        return isFrozen;
    }

    function withdrawAll() public isOwner {
        address payable _to = payable(_owner);
        uint256 _balance = address(this).balance;
        _to.transfer(_balance);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function tagsContract() external view returns (address) {
        return address(_tags);
    }

    function bankContract() external view returns (address) {
        return address(_bank);
    }

    function freeze() public isOwner {
        isFrozen = true;
    }

    function setInviteStartTime(uint256 inviteStartTime) public isOwner {
        _inviteStartTime = inviteStartTime;
    }

    function setAuctionDetails(
        uint256 initialPrice,
        uint256 minPrice,
        uint256 step,
        uint256 startTime
    ) public isOwner {
        _initialPrice = initialPrice;
        _minPrice = minPrice;
        _step = step;
        startedAt = startTime;
    }
}
