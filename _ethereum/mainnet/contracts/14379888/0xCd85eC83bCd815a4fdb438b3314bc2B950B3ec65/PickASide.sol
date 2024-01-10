// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";

/**
 * $$$$$$$\  $$\           $$\              $$$$$$\         $$$$$$\  $$\       $$\
 * $$  __$$\ \__|          $$ |            $$  __$$\       $$  __$$\ \__|      $$ |
 * $$ |  $$ |$$\  $$$$$$$\ $$ |  $$\       $$ /  $$ |      $$ /  \__|$$\  $$$$$$$ | $$$$$$\
 * $$$$$$$  |$$ |$$  _____|$$ | $$  |      $$$$$$$$ |      \$$$$$$\  $$ |$$  __$$ |$$  __$$\
 * $$  ____/ $$ |$$ /      $$$$$$  /       $$  __$$ |       \____$$\ $$ |$$ /  $$ |$$$$$$$$ |
 * $$ |      $$ |$$ |      $$  _$$<        $$ |  $$ |      $$\   $$ |$$ |$$ |  $$ |$$   ____|
 * $$ |      $$ |\$$$$$$$\ $$ | \$$\       $$ |  $$ |      \$$$$$$  |$$ |\$$$$$$$ |\$$$$$$$\
 * \__|      \__| \_______|\__|  \__|      \__|  \__|       \______/ \__| \_______| \_______|
 *
 */
contract PickASide is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public constant MIN_PRICE = 0.01 ether;
    uint256 public ukraineSideAmount = 0;
    uint256 public russiaSideAmount = 0;
    uint256 public pureEvilSideAmount = 0;
    Counters.Counter public ukraineMintCounter;
    Counters.Counter public russiaMintCounter;
    Counters.Counter public pureEvilMintCounter;

    struct Stats {
        uint256 amount;
        string side;
        string id;
        string cid;
    }

    mapping(uint256 => Stats) public tokenStats;
    mapping(address => bool) public addressStore;
    mapping(string => bool) public idStore;

    bool public saleOpen = false;

    constructor() ERC721("Pick A Side", "SIDE") {
    }

    function mint(
        string memory id,
        uint256 amount,
        string memory side,
        string memory cid
    )
    external
    payable {
        require(saleOpen, "Minting is closed");
        require(msg.value >= MIN_PRICE, "Insufficient payment");
        require(msg.value >= amount, "Dishonesty payment");
        require(!idStore[id], "You already picked a side. You can not change that.");
        require(!addressStore[msg.sender], "You already picked a side. You can not change that.");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        if (_stringEquals(side, "0")) {
            ukraineMintCounter.increment();
            ukraineSideAmount = ukraineSideAmount + amount;
        }
        if (_stringEquals(side, "1")) {
            russiaMintCounter.increment();
            russiaSideAmount = russiaSideAmount + amount;
        }
        if (_stringEquals(side, "2")) {
            pureEvilMintCounter.increment();
            pureEvilSideAmount = pureEvilSideAmount + amount;
        }

        Stats memory stats = Stats(amount, side, id, cid);
        tokenStats[tokenId] = stats;
        addressStore[msg.sender] = true;
        idStore[id] = true;

        _safeMint(msg.sender, tokenId);
    }


    function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(_tokenId), "Token doesn't exist");
        Stats memory _stats = tokenStats[_tokenId];

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Pick A Side #',
                                Strings.toString(_tokenId),
                                '", "description": "Pick A Side is a social experiment during the Russia-Ukraine conflict, the main goal of this project is to enable people to pick side in person and provide proof for that.", "image": "',
                                string(abi.encodePacked("https://", _stats.cid, ".ipfs.nftstorage.link")),
                                '","attributes":', _getAttributes(_stats), "}"
                            )
                        )
                    )
                )
            )
        );
    }

    function _getAttributes(Stats memory _stats) internal pure returns(string memory) {

        string memory realSide;

        if (_stringEquals(_stats.side, "0")) {
            realSide = "StandWithUkraine";
        }
        if (_stringEquals(_stats.side, "1")) {
            realSide = "StandWithRussia";
        }
        if (_stringEquals(_stats.side, "2")) {
            realSide = "Pure Evil";
        }

        string memory attributes = "[";

        // Amount object
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Contribution Amount",',
                '"value": "',
                Strings.toString(_stats.amount),
                ' Wei"},'
            )
        );

        // id object
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"id",',
                '"value": "',
                _stats.id,
                '"},'
            )
        );

        // Side object
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Side",',
                '"value": "',
                realSide,
                '"}'
            )
        );

        attributes = string(
            abi.encodePacked(
                attributes,
                ']'
            )
        );

        return attributes;
    }


    function setSaleOpen(bool _saleOpen) external onlyOwner {
        saleOpen = _saleOpen;
    }

    function _stringEquals(string memory _a, string memory _b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}