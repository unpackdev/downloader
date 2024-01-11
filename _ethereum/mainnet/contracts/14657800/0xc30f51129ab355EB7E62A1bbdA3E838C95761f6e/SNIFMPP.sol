// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721AQueryableUUPSUpgradeable.sol";
import "./ERC721ABurnableUUPSUpgradeable.sol";
import "./ERC721AGoverenedUUPSUpgradeable.sol";
import "./ISNIF.sol";

error FailedToWithdraw();
error FromFlaggedAddress();
error ToFlaggedAddress();
error PassIsFlagged();
error Unauthorized();

/// @title SNIF
/// @author @KfishNFT
/// @notice SNIF Marketplace Pass
/** @dev Any function which updates state will require a signature from an address with the correct role
    This is an upgradeable contract using UUPSUpgradeable (IERC1822Proxiable / ERC1967Proxy) from OpenZeppelin */
contract SNIFMPP is
    Initializable,
    AccessControlUpgradeable,
    ERC721AQueryableUUPSUpgradeable,
    ERC721ABurnableUUPSUpgradeable,
    ERC721AGoverenedUUPSUpgradeable
{
    /// @notice Role assigned to an address that can perform upgrades to the contract
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice Role assigned to addresses that can perform managemenet actions
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /// @notice Role assigned to addresses that can mint
    /// @dev role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice a way to keep track of flagged passes that are untransferable
    uint256[] private flaggedPasses;
    /// @notice a way to keep track of flagged addresses that are unable to transfer passes
    address[] private flaggedAddresses;
    /// @notice base URI used to retrieve metadata
    /// @dev tokenURI will use .json at the end for each token starting from 1
    string public baseURI;
    /// @notice setting an owner in order to comply with ownable interfaces
    /// @dev this variable was only added for compatibility with contracts that request an owner
    address public owner;
    /// @notice Calling
    /// @dev this variable was only added for compatibility with contracts that request an owner
    ISNIF public snif;

    event PassFlagged(address indexed sender, uint256 tokenId);
    event PassUnflagged(address indexed sender, uint256 tokenId);
    event AddressFlagged(address indexed sender, address flaggedAddress);
    event AddressUnflagged(address indexed sender, address unflaggedAddress);
    event AdminTransfer(address indexed sender, address from, address to, uint256 tokenId);
    event PassBurned(address indexed sender, uint256 tokenId);
    event OwnershipTransferred(address indexed sender, address previousOwner, address newOwner);
    event BaseURIChanged(address indexed sender, string previousURI, string newURI);

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called at deploy time
    function initialize() public initializer {
        __ERC721A_init("SNIFMPP", "SNIFMPP");
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, 0x1980c5a48909811200977D41C1E28a4bA32537F6);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        snif = ISNIF(0x1D0EC4a86AC39FEF4485169B4D14dC39D0ea64Cd);
        baseURI = "ipfs://QmXEeFZHQGY1gYdWztKrfbtVF2cvj5CvmTmTVrNxhtpm7p";
        owner = msg.sender;
    }

    /*
        Functions that require authorized roles
    */

    /// @notice Airdrop!
    function airdrop(address[] calldata recipients_) external onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < recipients_.length; i++) {
            _mint(recipients_[i], 1, "", false);
        }
    }

    /// @notice Used to set the baseURI for metadata
    /// @dev The baseURI should end in '/'
    /// @param baseURI_ the base URI
    function setBaseURI(string memory baseURI_) external managed {
        baseURI = baseURI_;
    }

    /// @notice Used to set a new owner value
    /// @dev This is not the same as Ownable and was only added for compatibility
    /// @param newOwner_ The new owner
    function transferOwnership(address newOwner_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        owner = newOwner_;
    }

    /// @notice Check whether a key has been flagged
    /// @param tokenId_ the key's token id
    function isPassFlagged(uint256 tokenId_) public view returns (bool) {
        for (uint256 i = 0; i < flaggedPasses.length; i++) {
            if (flaggedPasses[i] == tokenId_) return true;
        }
        return false;
    }

    /// @notice Retrieve list of flagged passes
    function getFlaggedPasses() external view returns (uint256[] memory) {
        return flaggedPasses;
    }

    /// @notice Check whether an address has been flagged
    /// @param address_ the address
    function isAddressFlagged(address address_) public view returns (bool) {
        for (uint256 i = 0; i < flaggedAddresses.length; i++) {
            if (flaggedAddresses[i] == address_) return true;
        }
        return false;
    }

    /// @notice Get list of flagged addresses
    function getFlaggedAddresses() external view returns (address[] memory) {
        return flaggedAddresses;
    }

    /// @notice used to flag an address and remove the ability for it to transfer passes
    /// @dev callable by admin or manager
    /// @param address_ the address that will be flagged
    function flagAddress(address address_) external managed {
        flaggedAddresses.push(address_);
        emit AddressFlagged(msg.sender, address_);
    }

    /// @notice used to remove the flag of an address and restore the ability for it to transfer passes
    /// @dev callable by admin or manager
    /// @param address_ the address that will be unflagged
    function unflagAddress(address address_) external managed {
        for (uint256 i = 0; i < flaggedAddresses.length; i++) {
            if (flaggedAddresses[i] == address_) {
                flaggedAddresses[i] = flaggedAddresses[flaggedAddresses.length - 1];
                flaggedAddresses.pop();
                break;
            }
        }
        emit AddressUnflagged(msg.sender, address_);
    }

    /// @notice used to flag a key and make it untransferrable
    /// @dev callable by admin or manager
    /// @param tokenId_ the key that will be flagged
    function flagPass(uint256 tokenId_) external managed {
        flaggedPasses.push(tokenId_);
        emit PassFlagged(msg.sender, tokenId_);
    }

    /// @notice used to remove the flag of a key and restore the ability for it to be transferred
    /// @dev callable by admin or manager
    /// @param tokenId_ the key that will be unflagged
    function unflagPass(uint256 tokenId_) external managed {
        for (uint256 i = 0; i < flaggedPasses.length; i++) {
            if (flaggedPasses[i] == tokenId_) {
                flaggedPasses[i] = flaggedPasses[flaggedPasses.length - 1];
                flaggedPasses.pop();
                break;
            }
        }
        emit PassUnflagged(msg.sender, tokenId_);
    }

    /// @notice this function will burn passes minted from this address
    /// @dev it will not work with legacy passes
    /// @param tokenId_ the key's tokenId
    function burn(uint256 tokenId_) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(tokenId_, false);
        emit PassBurned(msg.sender, tokenId_);
    }

    /// @notice Hook to check whether a key is transferrable
    /// @dev admins can always transfer regardless of whether passes are flagged
    /// @param from address that holds the tokenId
    /// @param to address that will receive the tokenId
    /// @param startTokenId index of first tokenId that will be transferred
    /// @param quantity amount that will be transferred
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            if (isAddressFlagged(from)) revert FromFlaggedAddress();
            if (isAddressFlagged(to)) revert ToFlaggedAddress();
            for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
                if (isPassFlagged(i)) revert PassIsFlagged();
            }
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /*
        Admin Functions
    */
    /// @notice admin transfer of token from one address to another and meant to be used with extreme care
    /// @dev only callable from an address with the admin role
    /// @param from_ the address that holds the tokenId
    /// @param to_ the address which will receive the tokenId
    /// @param tokenId_ the key's tokenId
    function adminTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _adminTransferFrom(from_, to_, tokenId_);
        emit AdminTransfer(msg.sender, from_, to_, tokenId_);
    }

    /// @notice Withdraw function in case anyone sends ETH to contract by mistake
    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert FailedToWithdraw();
    }

    /*
        ERC721A Overrides
    */
    /// @notice Override of ERC721A start token ID
    /// @return The initial tokenId
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice Override of ERC721A tokenURI(uint256)
    /// @param tokenId the tokenId without offsets
    /// @return The tokenURI with metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length > 0 ? baseURI : "";
    }

    /// @notice Override of ERC721A and AccessControlUpgradeable supportsInterface function
    /// @param interfaceId the interfaceId
    /// @return bool if interfaceId is supported or not
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721AUUPSUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(AccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice UUPS Upgradeable authorization function
    /// @dev Only the UPGRADER_ROLE can upgrade the contract
    /// @param newImplementation The address of the new implementation
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /*
        Modifiers
    */
    /// @notice Modifier that ensures the function is being called by an address that is either a manager or a default admin
    modifier managed() {
        if (!hasRole(MANAGER_ROLE, msg.sender) && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert Unauthorized();
        _;
    }
}
