// SPDX-License-Identifier: UNLICENSED

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./IGiveaway.sol";

pragma solidity ^0.8.0;

contract CodeMakesArt is ERC721Enumerable, Ownable {
    enum State {
        Paused,
        Presale,
        Active,
        Locked
    }

    struct Drop {
        // General info
        string name;
        string description;
        address payable artist;
        // art
        uint256 lib;
        string script;
        // Price, supply & minting
        uint256 price;
        uint256 royalty;
        uint256 minted;
        uint256 maxSupply;
        uint256 maxPerMint;
        IGiveaway giveaway;
        // State
        State state;
    }

    mapping(uint256 => Drop) private drops;
    mapping(address => string) private artistNames;
    mapping(address => string) private artistURLs;

    mapping(uint256 => uint256) private creationBlocks;
    mapping(uint256 => uint256) private creationTimestamps;
    mapping(uint256 => string) private libIpfsHashes;

    string private metadataBaseURI = 'https://codemakes.art/token/';

    constructor() ERC721('Code Makes Art', 'CMA') {}

    // Creation

    function mint(uint256 dropId, uint256 count) public payable {
        Drop storage drop = drops[dropId];
        require(drop.state == State.Active, 'Sale is not active');
        require(count > 0 && count <= drop.maxPerMint, 'Too many at once');
        require(msg.value == drop.price * count, 'Wrong ether value');

        _splitReward(dropId);
        _mintDrop(dropId, count);
    }

    function claimFree(uint256 dropId, uint256 count) public {
        Drop storage drop = drops[dropId];
        require(drop.state == State.Presale || drop.state == State.Active, 'Sale is not active');
        require(address(drop.giveaway) != address(0), 'Giveaway not supported');
        drop.giveaway.onClaimFree(msg.sender, dropId, count);

        _mintDrop(dropId, count);
    }

    function _mintDrop(uint256 dropId, uint256 count) internal {
        Drop storage drop = drops[dropId];
        require(drop.minted + count <= drop.maxSupply, 'Not enough left');

        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = (dropId * 1_000_000) + drop.minted + i + 1;
            creationBlocks[tokenId] = block.number;
            creationTimestamps[tokenId] = block.timestamp;
            _safeMint(msg.sender, tokenId);
        }

        drop.minted += count;
    }

    // Reading data

    function tokenHash(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), 'nonexistent token');
        return
            keccak256(abi.encodePacked(address(this), creationBlocks[tokenId], creationTimestamps[tokenId], tokenId));
    }

    function dropDetails(uint256 dropId)
        public
        view
        returns (
            string memory name,
            string memory description,
            string memory artistName,
            string memory artistUrl,
            uint256 price,
            uint256 minted,
            uint256 maxSupply,
            uint256 maxPerMint,
            State state
        )
    {
        name = drops[dropId].name;
        description = drops[dropId].description;
        artistName = artistNames[drops[dropId].artist];
        artistUrl = artistURLs[drops[dropId].artist];
        price = drops[dropId].price;
        minted = drops[dropId].minted;
        maxSupply = drops[dropId].maxSupply;
        maxPerMint = drops[dropId].maxPerMint;
        state = drops[dropId].state;
    }

    function renderTokenHtml(uint256 tokenId) public view returns (string memory) {
        bytes32 hash = tokenHash(tokenId);
        uint256 dropId = tokenId / 1000000;
        require(bytes(drops[dropId].script).length != 0 || drops[dropId].lib > 0, 'Not available');

        string memory dependency = drops[dropId].lib > 0
            ? string(
                abi.encodePacked('<script src="https://ipfs.io/ipfs/', libIpfsHashes[drops[dropId].lib], '"></script>')
            )
            : '';

        string memory prelude = string(
            abi.encodePacked(
                "var HASH='",
                Strings.toHexString(uint256(hash)),
                "',ID='",
                Strings.toString(tokenId),
                "',N=",
                Strings.toString(tokenId % 1000000),
                ',BLOCK_N=',
                Strings.toString(creationBlocks[tokenId]),
                ',BLOCK_TS=',
                Strings.toString(creationTimestamps[tokenId]),
                ',OWNER="',
                Strings.toHexString(uint160(ownerOf(tokenId))),
                '";\n'
            )
        );

        return
            string(
                abi.encodePacked(
                    '<title>',
                    drops[dropId].name,
                    ' #',
                    Strings.toString(tokenId % 1000000),
                    '</title>',
                    dependency,
                    '<script>',
                    prelude,
                    drops[dropId].script,
                    '</script>'
                )
            );
    }

    // Drops management

    function setDrop(
        uint256 dropId,
        string memory name,
        string memory description,
        address payable artist,
        uint256 price,
        uint256 royalty,
        uint256 maxSupply,
        uint256 maxPerMint,
        IGiveaway giveaway,
        State state
    ) public onlyOwner {
        require(drops[dropId].state != State.Locked, 'Drop locked');

        drops[dropId].name = name;
        drops[dropId].description = description;
        drops[dropId].artist = artist;
        drops[dropId].price = price;
        drops[dropId].royalty = royalty;
        drops[dropId].maxSupply = maxSupply;
        drops[dropId].maxPerMint = maxPerMint;
        drops[dropId].giveaway = giveaway;
        drops[dropId].state = state;
    }

    function setScript(
        uint256 dropId,
        uint256 lib,
        string memory script
    ) public onlyOwner {
        require(drops[dropId].state != State.Locked, 'Drop locked');
        drops[dropId].lib = lib;
        drops[dropId].script = script;
    }

    function setState(uint256 dropId, State state) public onlyOwner {
        require(drops[dropId].state != State.Locked, 'Drop locked');
        drops[dropId].state = state;
    }

    function setArtist(
        address artist,
        string memory name,
        string memory url
    ) public onlyOwner {
        artistNames[artist] = name;
        artistURLs[artist] = url;
    }

    function setLibIpfsHash(uint256 lib, string memory hash) public onlyOwner {
        libIpfsHashes[lib] = hash;
    }

    function _splitReward(uint256 dropId) internal {
        if (msg.value == 0) {
            return;
        }

        uint256 royalty = drops[dropId].royalty;
        address payable artist = drops[dropId].artist;

        uint256 artistReward = 0;

        if (artist != address(0)) {
            artistReward = (msg.value / 100) * royalty;
            if (artistReward > 0) {
                artist.transfer(artistReward);
            }
        }

        uint256 rest = msg.value - artistReward;
        if (rest > 0) {
            payable(owner()).transfer(rest);
        }
    }

    // Metadata

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        metadataBaseURI = baseURI;
    }
}
