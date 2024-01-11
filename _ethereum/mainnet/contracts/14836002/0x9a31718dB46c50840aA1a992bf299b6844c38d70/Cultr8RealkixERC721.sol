pragma solidity 0.8.11;
pragma abicoder v2;

import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./Counters.sol";

contract Cultr8RealkixERC721 is ERC721Pausable, Ownable, AccessControl
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ====================================================
    // ROLES
    // ====================================================
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");

    // ====================================================
    // EVENTS
    // ====================================================
    event TokenMinted(uint256 tokenIndex, address recipient);
    event Redeemed(uint256 tokenIndex, address owner);
    event CustodyTaken(uint256 tokenIndex, address holder);
    event Burned(uint256 tokenIndex);

    // ====================================================
    // STATE
    // ====================================================
    // metadata
    string private _baseURIExtended;
    mapping (uint256 => string) private _tokenURIs;

    // workflow
    mapping(uint256 => address) public initialOwners;
    address public redeemedPool;
    address public claimsPool;

    // general vars, counter, etc
    Counters.Counter private _tokenIdCounter;

    // ====================================================
    // CONSTRUCTOR
    // ====================================================
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    )
        ERC721(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(CUSTODIAN_ROLE, msg.sender);

        _baseURIExtended = _baseUri;
    }

    // ====================================================
    // OVERRIDES
    // ====================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ====================================================
    // GATED CONTROLS
    // ====================================================
    function setBaseUri(string memory newBaseUri)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseURIExtended = newBaseUri;
    }

    function setTokenURI(uint256 tokenId, string memory newTokenURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tokenURIs[tokenId] = newTokenURI;
    }

    function setRedeemedPool(address addr)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        redeemedPool = addr;
    }

    function setClaimsPool(address addr)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        claimsPool = addr;
    }

    function togglePaused()
        public
        onlyRole(PAUSER_ROLE)
    {
        if(paused()) {
            _unpause();
        }
        else {
             _pause();
        }
    }

    function mint(address recipient)
        public
        payable
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(recipient, tokenId);

        initialOwners[tokenId] = recipient;

        emit TokenMinted(tokenId, recipient);
    }

    function takeCustody(uint256 tokenId)
        public
        onlyRole(CUSTODIAN_ROLE)
    {
        require(claimsPool != address(0), "Claims pool not set");
        
        address holder = ownerOf(tokenId);
        _safeTransfer(holder, claimsPool, tokenId, "");
        
        emit CustodyTaken(tokenId, holder);
    }

    function burnToken(uint256 tokenId)
        public
        onlyRole(CUSTODIAN_ROLE)
    {
        require(ownerOf(tokenId) == claimsPool || ownerOf(tokenId) == redeemedPool , "Token must be in custody or redeemed pool in order to burn");

        _burn(tokenId);

        emit Burned(tokenId);
    }

    // ====================================================
    // INTERNAL UTILS
    // ====================================================
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _baseURIExtended;
    }

    // ====================================================
    // PUBLIC API
    // ====================================================
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // if a custom tokenURI has not been set, return base + tokenId
        if(bytes(_tokenURI).length == 0) {
            return string(abi.encodePacked(base, tokenId.toString()));
        }

        // a custom tokenURI has been set - likely after metadata IPFS migration
        return _tokenURI;
    }

    function redeemAsset(uint256 tokenId)
        public
    {
        require(redeemedPool != address(0), "Redeemed Pool not set");
        
        safeTransferFrom(msg.sender, redeemedPool, tokenId);

        emit Redeemed(tokenId, msg.sender);
    }
}
