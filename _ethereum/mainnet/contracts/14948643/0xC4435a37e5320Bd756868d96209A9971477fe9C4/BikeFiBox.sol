// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// [Contract] Token Standard
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";

// [Contract] Utils
import "./Context.sol";
import "./Counters.sol";

// [Contract] Security & Access
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

contract BikeFiBox is Context, AccessControl, ERC721, ERC721Burnable, ERC721Enumerable, ReentrancyGuard {
    // [Contract] Variable
    string constant TOKEN_NAME = "BikeFiBox";
    string constant TOKEN_SYMBOL = "BFB";
    bytes32 public constant BOX_CREATOR_PERMISSION = keccak256("BOX_CREATOR_PERMISSION");

    // [Contract] Counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    // [Contract] Parameter
    string private _metaDataURI;
    struct Campaign {
        uint256 totalBox;
        uint256 openBox;
    }
    mapping(address => Campaign) private _campaign;

    // [Contract] Constructor
    constructor() ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BOX_CREATOR_PERMISSION, _msgSender());
        _metaDataURI = "https://api.bikefi.io/boxes/";
    }

    // [Contract] Public
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "[Box] Could not find this tokenId");
        return string(abi.encodePacked(_metaDataURI, Strings.toString(tokenId), ".json"));
    }

    // [Contract] Required
    function createCampaign(address _address, uint256 _totalBox) public nonReentrant onlyAdminRole {
        _campaign[_address] = Campaign(_totalBox, 0);
        grantRole(BOX_CREATOR_PERMISSION, _address);
    }

    function updateCampaign(address _address, uint256 _totalBox) public onlyAdminRole {
        require(hasRole(BOX_CREATOR_PERMISSION, _address), "[Box] Creator Permission required");
        _campaign[_address].totalBox = _totalBox;
    }

    function mint(address to) public virtual onlyAdminRole {
        _mint(to, _tokenId.current());
        _tokenId.increment();
    }

    function setMetaDataURI(string memory metaDataURI) external onlyAdminRole {
        _metaDataURI = metaDataURI;
    }

    function boxMint(address to) public virtual onlyBoxCreatorPermission {
        require(_campaign[_msgSender()].openBox < _campaign[_msgSender()].totalBox, "[Box] Can not mint over allowance");
        _safeMint(to, _tokenId.current());
        _campaign[_msgSender()].openBox += 1;
        _tokenId.increment();
    }

    // [Contract] Modifier
    modifier onlyAdminRole() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "[Box] Permission Denied");
        _;
    }
    modifier onlyBoxCreatorPermission() {
        require(hasRole(BOX_CREATOR_PERMISSION, _msgSender()), "[Box] Permission Denied");
        _;
    }

    // [Contract] SupportsInterface
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // [Contract] Required function to allow receiving ERC-721 - When safeTransferFrom called auto implement this func if (to) is contract address
    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
