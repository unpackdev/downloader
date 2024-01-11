// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./ERC721AUpgradeable.sol";
// import "./MerkleDistributor.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


contract Blkpyrmid is
    Initializable,
    ERC721AUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint256 public MAX_SUPPLY;

    string private _baseTokenURI;

    string private unrevealedUrl;
    bytes32 public version;

    function initialize() public initializer {
        __ERC721AUpgradeable_init("Blkpyrmid", "BLK");
        __ReentrancyGuard_init();
        __AccessControl_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        version = "1.0";

        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        MAX_SUPPLY = 229;

        setBaseURI("https://ipfs.io/ipfs/QmPrrzSpPycBjaZzMLDonquaEVbNXXcJD9KsFFMpckKxNf/");
        mint();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : unrevealedUrl;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function setMaxSupply(uint256 number)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MAX_SUPPLY = number;
    }

    function setUnrevealedUrl(string memory _string)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unrevealedUrl = _string;
    }

    /**
     * @notice Allows the CONTRACT_ADMIN_ROLE to set the base token URI
     *
     * Requirements
     * - Only the CONTRACT_ADMIN_ROLE can execute
     *
     * @param baseURI_ The base token URI
     */
    function setBaseURI(string memory baseURI_)
        public
        onlyRole(CONTRACT_ADMIN_ROLE)
    {
        _baseTokenURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Allows users to check the supported interfaces
     *
     * @param interfaceId The id of the interface to check
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint()
        internal
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        require(_totalMinted() == 0, "Cannot mint more than once");
        _safeMint(msg.sender, MAX_SUPPLY);
    }

    /**
     * @notice Allows the DEFAULT_ADMIN_ROLE to withdraw Ether to respective parties
     *
     * Requirements
     * - Only DEFAULT_ADMIN_ROLE can execute
     *
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {

        (bool success, ) = msg.sender.call{value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    function pause() public onlyRole(CONTRACT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(CONTRACT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Burns `tokenId`.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
    }

    /**
     * @notice Allows the contract to receive Ether
     */
    receive() external payable {}

    /**
     * @notice Allows the UPGRADER_ROLE to upgrade the smart contract
     *
     * Requirements
     * - Only the UPGRADER_ROLE can execute
     *
     * @param newImplementation The address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
