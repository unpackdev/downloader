// SPDX-License-Identifier: GPL-3.0

/// @title The Sunrises ERC-721 token

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Enumerable.sol";
import "./IERC165.sol";
import "./ISunriseToken.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IProxyRegistry.sol";

contract SunriseToken is ISunriseToken, Ownable, ERC721Enumerable {
    using Strings for uint256;

    // The Sunrise Art Club address (creator)
    address public sunriseArtClub;

    // An address who has permissions to mint Sunrises
    address public minter;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // The internal sunrise ID tracker
    uint256 private _currentSunriseId;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash;

    // Max supply of Sunrises
    uint256 private maxSupply = 365;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the sender is the Sunrise Art Club.
     */
    modifier onlySunriseArtClub() {
        require(msg.sender == sunriseArtClub, 'Sender is not the Sunrise Art Club');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    constructor(
        address _sunriseArtClub,
        address _minter,
        IProxyRegistry _proxyRegistry,
        string memory contractURIHash
    ) ERC721('Sunrise Art Club', 'SUNRISE') {
        sunriseArtClub = _sunriseArtClub;
        minter = _minter;
        proxyRegistry = _proxyRegistry;
        _contractURIHash = contractURIHash;
    }

    function getMaxSupply() external view override returns (uint256) {
        return maxSupply;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Override isApprovedForAll to include user's OpenSea proxy accounts to enable gasless listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Include OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Mint a Sunrise to the minter, along with a possible team reward
     * Sunrise. Sunrise Art Club reward sunrises are minted every 10 Sunrises, starting after the first
     * auction, until 36 Sunrises have been minted (1 year w/ daily auctions).
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        require(_currentSunriseId <= maxSupply, 'Max supply reached');
        if (_currentSunriseId <= 365 && _currentSunriseId % 10 == 0) {
            _mintTo(sunriseArtClub, _currentSunriseId++);
        }
        return _mintTo(minter, _currentSunriseId++);
    }

    /**
     * @notice Burn a Sunrise.
     */
    function burn(uint256 sunriseId) public override onlyMinter {
        _burn(sunriseId);
        emit SunriseBurned(sunriseId);
    }

    /**
     * @dev overrides default base url
     */
    function _baseURI() internal pure override returns (string memory) {
        return 'ipfs://';
    }

    /**
     * @notice Set the Sunrise Art Club.
     * @dev Only callable by the Sunrise Art Club when not locked.
     */
    function setSunriseArtClub(address _sunriseArtClub) external override onlySunriseArtClub {
        sunriseArtClub = _sunriseArtClub;

        emit SunriseArtClubUpdated(_sunriseArtClub);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Mint a Sunrise with `sunriseId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 sunriseId) internal returns (uint256) {
        _mint(owner(), to, sunriseId);
        emit SunriseCreated(sunriseId);

        return sunriseId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'SunriseToken: URI query for nonexistent token');
        return string(abi.encodePacked('ipfs://', _contractURIHash, '/', tokenId.toString()));
    }
}
