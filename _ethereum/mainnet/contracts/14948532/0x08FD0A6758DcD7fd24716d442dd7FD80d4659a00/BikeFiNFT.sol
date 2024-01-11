// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// [Contract] Token Standard
import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721Enumerable.sol";

// [Contract] Utils
import "./Counters.sol";
import "./Context.sol";

// [Contract] Security & Access
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

// AccessControl, ReentrancyGuard
contract BikeFiNFT is ERC721, ERC721Enumerable, AccessControl, Pausable {
    // [Contract] Variable
    string constant TOKEN_NAME = "BikeFiNFT";
    string constant TOKEN_SYMBOL = "BFN";
    bytes32 public constant BIKE_CREATOR_PERMISSION = keccak256("BIKE_CREATOR_PERMISSION");

    // [Contract] Counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    // [Contract] Parameter
    string private _metaDataURI;

    // [Contract] Constructor
    constructor() ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BIKE_CREATOR_PERMISSION, _msgSender());
        _metaDataURI = "https://api.bikefi.io/bikes/";
    }

    // [Contract] Public
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "[Bike] Could not find this tokenId");
        return string(abi.encodePacked(_metaDataURI, Strings.toString(tokenId), ".json"));
    }

    // [Contract] Required
    function setMetaDataURI(string memory metaDataURI) external onlyAdminRole {
        _metaDataURI = metaDataURI;
    }

    function createBike(address to) external whenNotPaused onlyBikeCreatorPermission {
        _mint(to, _tokenId.current());
        _tokenId.increment();
    }

    // [Contract] Modifier
    modifier onlyAdminRole() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "[Bike] Permission Denied");
        _;
    }
    modifier onlyBikeCreatorPermission() {
        require(hasRole(BIKE_CREATOR_PERMISSION, _msgSender()), "[Bike] Permission Denied");
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
