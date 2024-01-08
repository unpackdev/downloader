// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract Barrry is Context, ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 private constant MEMBERSHIP_TYPE_OG = 0;
    uint256 private constant MEMBERSHIP_TYPE_SPACESHIP_CAPTAIN = 1;
    uint256 private constant MEMBERSHIP_TYPE_FIGHTER_PILOT = 2;
    uint256 private constant MEMBERSHIP_TYPE_PAPERPLANE_EXPERT = 3;

    uint256[4] private _priceSteps = [
        50 ether,
        3 ether,
        0.75 ether,
        0.1 ether
    ];

    uint256[4] private _maxSupply = [
        4,
        10,
        100,
        2500
    ];

    struct TokenInfo {
        uint256 membershipType;
    }

    mapping(uint256 => TokenInfo) private _tokenInfos;

    mapping(uint256 => Counters.Counter) private _tokenSupply;


    function _baseURI() internal pure override returns (string memory) {
        return "https://barrry.app/api/token/";
    }

    constructor() ERC721("BARRRY App - NFT Portfolio Manager", "BRRRY") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenMembershipType(uint256 tokenIndex) public view returns (uint256) {
        return _tokenInfos[tokenIndex].membershipType;
    }

    function safeMint(address to, uint256 membershipType) public onlyOwner {
        uint256 tokenSupply = _tokenSupply[membershipType].current();
        uint256 tokenMaxSupply = _maxSupply[membershipType];
        require(tokenSupply < tokenMaxSupply, 'Max supply of token type reached');

        uint256 tokenId = _tokenIdCounter.current();
        _tokenSupply[membershipType].increment();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _tokenInfos[tokenId] = TokenInfo(membershipType);
    }

    function mint(address to, uint256 membershipType) public payable {
        require(membershipType <= 3, 'You are a dreamer you');
        require(msg.value >= _priceSteps[membershipType], 'Price too low for membership type');

        uint256 tokenSupply = _tokenSupply[membershipType].current();
        uint256 tokenMaxSupply = _maxSupply[membershipType];
        require(tokenSupply < tokenMaxSupply, 'Max supply of token type reached');

        uint256 tokenId = _tokenIdCounter.current();
        _tokenSupply[membershipType].increment();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _tokenInfos[tokenId] = TokenInfo(membershipType);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
