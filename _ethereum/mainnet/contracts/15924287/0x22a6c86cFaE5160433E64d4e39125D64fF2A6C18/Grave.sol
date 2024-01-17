// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Counters.sol";

contract Grave is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PEOPLE_ROLE = keccak256("PEOPLE_ROLE");
    Counters.Counter private _tokenIdCounter;

    struct TokenInfo {
        uint256 tokenId;
        bool exist;
    }
    struct Coordinates {
        bool exist;
        uint256 x;
        uint256 y;
    }

    struct LockState {
        uint256 tokenId;
        bool locked;
        uint256 expTime;
    }

    mapping(uint256 => mapping(uint256=>TokenInfo)) public ctMapping;
    mapping(uint256 =>Coordinates) public tcMapping;
    mapping(uint256 =>bool) public isBuryMap;
    mapping(uint256 =>LockState) public lockStateMap;

    constructor() ERC721("Grave", "Grave") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PEOPLE_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function isbury(uint256 tokenId) public view returns(bool){
       return isBuryMap[tokenId];
    }

    function bury(uint256 tokenId) public onlyRole(PEOPLE_ROLE) whenNotBury(tokenId){
       isBuryMap[tokenId] = true;
    }
    function unbury(uint256 tokenId) public onlyRole(PEOPLE_ROLE) whenBury(tokenId){
       isBuryMap[tokenId] = false;
    }

    function isLocked(uint256 tokenId) public view returns(bool){
        return lockStateMap[tokenId].locked && lockStateMap[tokenId].expTime>block.timestamp;
    }

    modifier whenNotBury(uint256 tokenId) {
      require(!isBuryMap[tokenId], "it has bean used");
      _;
    }
    modifier whenBury(uint256 tokenId) {
      require(isBuryMap[tokenId], "it has not bean used");
      _;
    }

    modifier whenNotLocked(uint256 tokenId) {
      require(!isLocked(tokenId), "locked");
      _;
    }

    function _mint(address to, uint256 x, uint256 y) internal {
        require(x>0 && x<500000, "er x");
        require(y>0 && y<500000, "er y");
        TokenInfo memory exist = ctMapping[x][y];
        require(!exist.exist, "coordinates is exist");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(x.toString(), "_", y.toString(),".json")));

        TokenInfo memory tokenInfo = TokenInfo(tokenId, true);
        ctMapping[x][y] = tokenInfo;

        Coordinates memory coordinates = Coordinates(true, x, y);
        tcMapping[tokenId] = coordinates;
    }

    function _mintWithLock(address to, uint256 x, uint256 y, uint256 expTime) internal {
        require(x>0 && x<500000, "er x");
        require(y>0 && y<500000, "er y");
        TokenInfo memory exist = ctMapping[x][y];
        require(!exist.exist, "coordinates is exist");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        TokenInfo memory tokenInfo = TokenInfo(tokenId, true);
        ctMapping[x][y] = tokenInfo;

        Coordinates memory coordinates = Coordinates(true, x, y);
        tcMapping[tokenId] = coordinates;
        lockStateMap[tokenId] = LockState(tokenId, true, expTime);
    }

    function safeMint(address to, uint256 x, uint256 y) public onlyRole(MINTER_ROLE) {
        _mint(to, x, y);
    }

    function safeMintWithLock(address to, uint256 x, uint256 y, uint256 expTime) public onlyRole(MINTER_ROLE) {
        _mintWithLock(to, x, y, expTime);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        whenNotBury(tokenId)
        whenNotLocked(tokenId)
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.metagrave.co/grave/";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getTokenInfoByXY(uint256 x, uint256 y) public view returns(TokenInfo memory){
        TokenInfo memory tokenInfo = ctMapping[x][y];
        require(tokenInfo.exist,"not exist");
        return ctMapping[x][y];
    }

    function getXYByTokenId(uint256 tokenId) public view returns(Coordinates memory){
        Coordinates memory coordinates = tcMapping[tokenId];
        require(coordinates.exist,"not exist");
        return coordinates;
    }
}
    