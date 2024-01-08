// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.4;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Cryptopaka.sol";

//******************************//
//                              //
//    https://cryptopaka.com    //
//                              //
//******************************//

contract CryptopakaV2 is ERC721Enumerable, Ownable {
    string private _baseTokenURI = "https://api.cryptopaka.com/token/";

    // if the contract is paused
    bool public paused = true;

    // if you can still adopt founder pakas
    bool public adoptable = true;

    // check if the given paka is part of the 6969 founder pakas
    mapping(uint256 => bool) public isFounder;

    // the token id of MoonCats that has been used
    mapping(uint256 => bool) public usedMoonCats;

    // the address of MoonCat owners that has claimed
    mapping(address => bool) public claimedOwners;

    // the number of pakas that can be claimed by MoonCat holders
    uint16 public moonCatGiftCount = 500;

    // Adoption fee of a single paka
    uint256 public constant price = .08 ether;

    // Contract of Cryptopaka V1
    Cryptopaka private immutable v1Contract;

    // Contract of MoonCatAcclimator
    IERC721 private constant mca =
        IERC721(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69);

    // Search seed from Cryptopaka V1 used to prevent premining
    bytes32 public immutable searchSeed;

    // SHA-256 hash of the JavaScript parser
    bytes32 public immutable jsSHA256;

    constructor(address v1Address) ERC721("CryptopakaV2", "CPK") {
        Cryptopaka c = Cryptopaka(v1Address);
        v1Contract = c;
        searchSeed = c.searchSeed();
        jsSHA256 = c.jsSHA256();
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    /**
     * @dev Make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function pause() public whenNotPaused onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() public whenPaused onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);

        // v2 contract must own v1 contract
        require(v1Contract.owner() == address(this));

        // v1 contract must be paused forever
        if (!v1Contract.paused()) {
            v1Contract.pause();
        }
    }

    function setAdoptable(bool v) public onlyOwner {
        adoptable = v;
    }

    modifier canAdopt() {
        require(adoptable, "adoption has ended");
        _;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function _mintFounderSeed(address to, bytes32 seed) private {
        bytes32 h = keccak256(abi.encodePacked(seed, searchSeed));
        require((h[30] | h[31] == 0x0) && uint8(h[29]) < 8, "invalid seed");
        uint256 tokenId = uint256(h >> 216);

        // genesis paka are not adoptable
        require(!isGenesis(tokenId));

        try v1Contract.ownerOf(tokenId) {
            revert("paka already adopted");
        } catch {
            // paka not owned in v1, can mint safely
            isFounder[tokenId] = true;
            _mint(to, tokenId);
        }
    }

    function adopt(address to, bytes32 seed) public payable canAdopt {
        require(totalSupply() <= 6969 - 16); // exclude 16 genesis pakas
        require(price == msg.value, "incorrect ether value");

        _mintFounderSeed(to, seed);
    }

    function claimWithMoonCat(uint256 tokenId, bytes32 seed) public canAdopt {
        require(totalSupply() <= 6969 - 16); // exclude 16 genesis pakas
        require(moonCatGiftCount > 0, "airdrop has ended");
        require(mca.ownerOf(tokenId) == msg.sender, "not the owner");
        require(!usedMoonCats[tokenId], "this MoonCat has already been used");
        require(!claimedOwners[msg.sender], "you have already claimed");

        usedMoonCats[tokenId] = true;
        claimedOwners[msg.sender] = true;
        --moonCatGiftCount;
        _mintFounderSeed(msg.sender, seed);
    }

    function migrate(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(v1Contract.ownerOf(tokenId) == from, "not the owner");
        require(from == msg.sender || msg.sender == owner(), "not the owner");
        isFounder[tokenId] = true;
        _mint(to, tokenId);
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        if (totalSupply() <= 6969) {
            isFounder[tokenId] = true;
        }
        _mint(to, tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function isGenesis(uint256 tokenId) public pure returns (bool) {
        return
            tokenId == 1099511562240 ||
            tokenId == 1099511566336 ||
            tokenId == 1099511570432 ||
            tokenId == 1099511574528 ||
            tokenId == 1099511578624 ||
            tokenId == 1099511582720 ||
            tokenId == 1099511586816 ||
            tokenId == 1099511590912 ||
            tokenId == 1099511595008 ||
            tokenId == 1099511599104 ||
            tokenId == 1099511603200 ||
            tokenId == 1099511607296 ||
            tokenId == 1099511611392 ||
            tokenId == 1099511615488 ||
            tokenId == 1099511619584 ||
            tokenId == 1099511623680;
    }
}
