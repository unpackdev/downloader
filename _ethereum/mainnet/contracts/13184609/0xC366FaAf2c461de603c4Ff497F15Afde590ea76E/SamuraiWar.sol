// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract SamuraiWar is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    address private shogun = 0xd02c9b5AD40BFeEAB337eb75c1A60f514Cd70776;
    string private _baseTokenURI;

    uint256 private _summonPrice = 0.055 ether;
    bool private _startPreSummon = false;
    bool private _startSummon = false;

    uint256 public constant GIVE_AWAY = 50;
    uint256 public constant PRE_SUMMONS = 650;
    uint256 public constant SUMMON = 7000;
    uint256 public constant TOTAL_SAMURAI = GIVE_AWAY + PRE_SUMMONS + SUMMON;

    // ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,%@@@,@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    // ,,,,,,,,,,@,@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    // ,,,,,,,,,,@@@@@@@@@@,@@@@@@@@@,,,,,,,,,,,,,,,,,,,,
    // ,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@,@@@@,,,,,,,,,,,,,
    // ,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,@,,,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@,*@@@@,,,,,,,,,,,,,,
    // ,,,,,,,,,,,,,@@@@@@   @@@@@@@@@@@@@@@,,,,,,,,,,,,,
    // ,,,,,,,,,,,,@@@@@@@@@   @@ /@@@ /@@@@&,,,,,,,,,,,,
    // ,,,,,,,,,,@@@@@@@@ / /@ @@@@@@,/@@@@@@,,,,,,,,,,,,
    // ,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,
    // ,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,
    // ,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,
    constructor() ERC721("Samurai War", "SAMURAI") {
        transferOwnership(shogun);
    }

    function price() public view returns (uint256) {
        return _summonPrice;
    }

    function giveaway(uint256 num) public onlyOwner {
        uint256 summoned = totalSupply();
        require(summoned + num < GIVE_AWAY + 1, "Giveaways are limited to 50.");
        for (uint256 i; i < num; i++) {
            _safeMint(shogun, summoned + i);
        }
    }

    function preSummon(uint256 num) public payable nonReentrant {
        uint256 summoned = totalSupply();
        require(isStartPreSummon(), "No Pre summons yet.");
        require(msg.value == price() * num, "No Value");
        require(
            summoned + num < PRE_SUMMONS + GIVE_AWAY + 1,
            "PreSummon are limited to 650."
        );
        require(num <= 20, "");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, summoned + i);
        }

        require(payable(shogun).send(address(this).balance));
    }

    function summon(uint256 num) public payable nonReentrant {
        uint256 summoned = totalSupply();
        require(isStartSummon(), "No Summons yet.");
        require(msg.value == price() * num, "No Value");
        require(
            summoned + num < TOTAL_SAMURAI + 1,
            "Summon are limited to 7700."
        );
        require(num <= 20, "");

        for (uint256 i; i < num; i++) {
            _safeMint(msg.sender, summoned + i);
        }

        require(payable(shogun).send(address(this).balance));
    }

    function listOfSamurai(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    // instead Of NFT Token URI (Metadatas)
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "https://ipfs.io/ipfs/QmYBJbEybfPZi2Tv9gQJNbPPpeV1uyH5eF1UwmCdKHgCxg";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Mint Start & End Functions
    function isStartPreSummon() public view returns (bool) {
        return _startPreSummon;
    }

    function isStartSummon() public view returns (bool) {
        return _startSummon;
    }

    function startPreSummon() public onlyOwner {
        _startPreSummon = true;
    }

    function startSummon() public onlyOwner {
        _startSummon = true;
    }

    function endPreSummon() public onlyOwner {
        _startPreSummon = false;
    }

    function entSummon() public onlyOwner {
        _startSummon = false;
    }
}
