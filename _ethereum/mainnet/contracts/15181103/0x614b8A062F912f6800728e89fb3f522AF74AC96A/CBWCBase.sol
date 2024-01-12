// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import "./ERC721KFNCUUPSUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC165KFNC.sol";
import "./ICBWC.sol";

/// @title Crypto Bear Watch Club Base
/// @author Kfish n Chips
/// @notice Upgradeable contract base for Pieces and Watch NFTs
/// @dev Upgrades using UUPSUpgradeable Proxy pattern
abstract contract CBWCBase is
    Initializable,
    ERC721KFNCUUPSUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable
{
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// @notice Role assigned to addresses that can perform minted actions
    /// @dev Role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Role assigned to an address that can perform upgrades to the contract
    /// @dev Role can be granted by the DEFAULT_ADMIN_ROLE
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    /// @notice Setting an owner in order to comply with ownable interfaces
    /// @dev This variable was only added for compatibility with contracts that request an owner
    address public owner;
    /// @notice Contract URI with metadata
    string internal _contractURI;
    /// @notice The CryptoBearWatchClub NFT Contract
    /// @dev used to check the ownership of tokens
    ICBWC internal cbwc;

    /// @notice Emitted when ownership transferred.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Initializer function which replaces constructor for upgradeable contracts
    /// @dev This should be called from inheriting contract
    /// @param name_ Contract name
    /// @param symbol_ Contract symbol
    /// @param contractURI_ URI containing contract metadata for marketplaces such as OpenSea
    /// @param baseURI_ Base URI used to fetch token metadata
    /* solhint-disable ordering */
    function __CBWCBase_init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory baseURI_
    ) internal onlyInitializing {
        __AccessControl_init();
        __ERC2981_init();
        __ERC721KFNC_init(name_, symbol_, baseURI_);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _contractURI = contractURI_;
        owner = msg.sender;
        _setDefaultRoyalty(0x99946d4eb4B05165be06caE6A7F7A81095AFFd9D, 1000);
    }
    /* solhint-disable ordering */

    /// @notice Transfers ownership of the contract to a new account (`newOwner`)
    /// @dev Can only be called by an address with DEFAULT_ADMIN_ROLE
    /// @param newOwner_ New Owner of the contract
    /// Emits a {OwnershipTransferred} event
    function transferOwnership(address newOwner_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newOwner_ != address(0), "CBWC: owner cannot be 0 address");
        address previousOwner = owner;
        owner = newOwner_;

        emit OwnershipTransferred(previousOwner, owner);
    }

    /// @notice Used to set the baseURI for metadata
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param baseURI_ The base URI
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(baseURI_).length > 0, "CBWC: invalid URI");
        _setBaseURI(baseURI_);
    }

    /// @notice Used to set the contractURI
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param newContractURI_ The base URI
    function setContractURI(string memory newContractURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(bytes(newContractURI_).length > 0, "CBWC: invalid URI");
        _contractURI = newContractURI_;
    }

    /// @notice Set the default royalties using the ERC2981 NFT Royalty Standard
    /// @dev Callable only by an address with DEFAULT_ADMIN_ROLE
    /// The fee numerator considers a 10000 denominator
    /// meaning that 10% royalties would require a feeNumerator of 1000
    /// @param receiver_ Address that will receive royalty payments
    /// @param feeNumerator_ The number used to calculate the royalty percentage
    function setDefaultRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    /// @notice ContractURI containing metadata for marketplaces
    /// @return The _contractURI
    function contractURI()
        external
        view
        returns (string memory)
    {
        return _contractURI;
    }

    /// @notice Tokens minted
    /// @dev include tokens burned
    /// @return Returns the total amount of tokens minted in the contract.
    function totalMinted()
        external
        view
        returns (uint256)
    {
        return _nextTokenId - 1;
    }

    /// @notice Override of supportsInterface function
    /// @param interfaceId the interfaceId
    /// @return bool if interfaceId is supported or not
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC2981Upgradeable)
        returns (bool)
    {

        return interfaceId == _INTERFACE_ID_ERC165
            || interfaceId == _INTERFACE_ID_ERC721
            || interfaceId == _INTERFACE_ID_ERC721_METADATA
            || interfaceId == _INTERFACE_ID_ERC2981;
    }

    /// @notice UUPS Upgradeable authorization function
    /// @dev Callable only an address with UPGRADER_ROLE
    /// @param newImplementation_ Address of the new implementation
    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation_)
        internal
        virtual
        override
        onlyRole(UPGRADER_ROLE)
    {}
    /* solhint-disable no-empty-blocks */

    /// @notice Used to set the CryptoBearWatchClub contract address
    /// @dev Only callable by an address with DEFAULT_ADMIN_ROLE
    /// @param cbwc_ The CryptoBearWatchClub contract address
    function setCBWC(address cbwc_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        cbwc = ICBWC(cbwc_);
    }

    /// @notice Override ERC2981 {royaltyInfo} to validate whether a token exists
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        if(!_exists(_tokenId)) revert QueryNonExistentToken();
        return super.royaltyInfo(_tokenId, _salePrice);
    }

    /// @notice Overriding in order to start the Token ID
    function startingTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
