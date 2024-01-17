pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract KeysToTheMetaverse is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    ERC721Burnable,
    Ownable,
    AccessControl
{

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 private tokenIdTracker = 1;

    // NFT list
    string[] public nftList;

    // NFT status
    mapping(string => bool) nftExists;

    // NFT word.
    string[] public nftWords;

    // Max token can be minted.
    // uint256 public constant MAX_SUPPLY = 4000;

    mapping(address => bool) public _isBlacklisted;

    string public baseTokenURI;

    // Event
    event welcomeToK2M(uint256 indexed id);

    constructor(string memory name, string memory symbol,address ownerAddress, string memory _baseURL)
        ERC721(name, symbol)
    {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        transferOwnership(ownerAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        _setupRole(MINTER_ROLE, ownerAddress);
        _setupRole(BURNER_ROLE, ownerAddress);
        baseTokenURI = _baseURL;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        require(account != owner(), "Shouldn't be owner address");
        _isBlacklisted[account] = value;
    }

    function grandRole(string memory role, address account) public onlyOwner {
        bytes32 roleName = keccak256(abi.encodePacked(role));
        _setupRole(roleName, account);
    }

    function revokeAccess(string memory role, address account)
        public
        onlyOwner
    {
        bytes32 roleName = keccak256(abi.encodePacked(role));
        require(
            roleName != DEFAULT_ADMIN_ROLE,
            "ModifiedAccessControl: cannot revoke default admin role"
        );
        require(
            hasRole(roleName, account),
            "Couldn't find this address in the roles. "
        );
        revokeRole(roleName, account);
    }

    function publicMinting(
        address _to,
        string memory _tokenURI,
        string memory _nftWord
    ) external onlyRole(MINTER_ROLE) {
        require(!nftExists[_tokenURI]);
        nftList.push(_tokenURI);
        
        uint256 tokenId = tokenIdTracker;
        _safeMint(_to, tokenId);
        
        tokenIdTracker = tokenIdTracker + 1;
        nftExists[_tokenURI] = true;

        // setting the token tokenURI
        _setTokenURI(tokenId, _tokenURI);
        nftWords.push(_nftWord);

        emit welcomeToK2M(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenID
    ) internal override whenNotPaused {        
        require(from != address(0), "ERC721: transfer from the zero address");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "Blacklisted address"
        );
        super._transfer(from, to, tokenID);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
        onlyOwner
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable,AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}