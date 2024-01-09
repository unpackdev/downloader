// SPDX-License-Identifier: GPL-3.0

/// @title The YQC ERC-721 token

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721Checkpointable.sol";
import "./IYQCToken.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IProxyRegistry.sol";
import "./Strings.sol";

contract YQCToken is IYQCToken, Ownable, ERC721Checkpointable {
    using Strings for uint256;

    // The queeners DAO address (creators org)
    address public queenersDAO;

    // An address who has permissions to mint Nouns
    address public minter;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = 'QmT7hZcvtiZToFUukbF277N1ZQ3m3dd6jP7ABbLyR8tVAW';

    string private _baseURIHash = 'QmdcR6KG13G6QW5RakD5btVn1jpVuWQRh7ojiVwDgTzqd9';

    uint256 private _maxSupply = 13000;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the sender is the queeners DAO.
     */
    modifier onlyQueenersDAO() {
        require(msg.sender == queenersDAO, 'Sender is not the queeners DAO');
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
        address _queenersDAO,
        address _minter,
        IProxyRegistry _proxyRegistry
    ) ERC721('Yes Queen Club', 'YQC') {
        queenersDAO = _queenersDAO;
        minter = _minter;
        proxyRegistry = _proxyRegistry;
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
     * @notice Set the _baseURIHash.
     * @dev Only callable by the owner.
     */
    function setBaseURIHash(string memory newBaseURIHash) external onlyOwner {
        _baseURIHash = newBaseURIHash;
    }

    /**
     * @notice Set the _maxSupply.
     * @dev Only callable by the owner.
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        _maxSupply = newMaxSupply;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Mint a Queen to the minter.
     * @dev Call _mintTo with the to address(es).
     */
    function mint(uint256 queenId, address to) external override onlyMinter returns (uint256) {
        require(!isQueenersQueen(queenId) || to == queenersDAO, 'Cannot mint Queener Queen to others');
        return _mintTo(to, queenId);
    }

    function isQueenersQueen(uint256 queenId) public pure override returns (bool) {
        uint256 rem = queenId % 13;
        return rem == 0 || rem == 1 || rem == 2;
    }

    /**
     * @notice Burn a queen.
     */
    function burn(uint256 queenId) public override onlyMinter {
        _burn(queenId);
        emit QueenBurned(queenId);
    }

    /**
     * @notice Check if a queen exists.
     */
    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked('ipfs://', _baseURIHash, '/', tokenId.toString(), '.json'));
    }

    /**
     * @notice Set the queeners DAO.
     * @dev Only callable by the queeners DAO when not locked.
     */
    function setQueenersDAO(address _queenersDAO) external override onlyQueenersDAO {
        queenersDAO = _queenersDAO;

        emit QueenersDAOUpdated(_queenersDAO);
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
     * @notice Mint a Queen with `queenId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 queenId) internal returns (uint256) {
        require(queenId < _maxSupply, "No more queens available");
        _mint(owner(), to, queenId);
        emit QueenCreated(queenId);

        return queenId;
    }
}
