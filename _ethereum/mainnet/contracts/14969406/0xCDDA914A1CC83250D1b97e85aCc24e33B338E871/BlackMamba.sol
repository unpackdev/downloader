pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract BlackMamba is ERC721, Ownable, ReentrancyGuard {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string public _tokenURI = "https://ipfs.io/ipfs/QmZob5aVoDUe3Zq3HbqabXfpQztMeaMHJMuxGD5EGn1tKu";
    uint256 public maxSupply = 300;
    bool public saleIsActive = true;

    // codes list
    mapping (bytes32 => bool) private codes;
    // mapping of address to amount
    mapping (address => bool) public purchased;
    // used codes list
    mapping (bytes32 => bool) private usedCodes;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /** ADMIN */

    /// @dev change the base uri
    /// @param uri base uri
    function setTokenURI(string memory uri) public onlyOwner {
        _tokenURI = uri;
    }

    /// @dev add codes
    /// @param _codes string[]
    function addCodes(bytes32[] memory _codes) public onlyOwner {
        for (uint256 i = 0; i < _codes.length; i++) {
            codes[_codes[i]] = true;
        }
    }

    /// @dev Pause sale if active, make active if paused
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURI;
    }

    /// @dev mint number of nfts
    /// @param _code the amount to mint
    function mint(string memory _code)
        public
        nonReentrant
        returns (uint256)
    {
        bytes32 code = keccak256(abi.encodePacked(_code));
        require(saleIsActive, "Sale must be active to mint");
        require(codes[code] && !usedCodes[code], "Invalid code");
        require(!purchased[msg.sender], "User already purchased");
        require(_tokenIds.current() < maxSupply, "Purchase exceeds max supply");

        purchased[msg.sender] = true;
        usedCodes[code] = true;

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        return newItemId;
    }
}