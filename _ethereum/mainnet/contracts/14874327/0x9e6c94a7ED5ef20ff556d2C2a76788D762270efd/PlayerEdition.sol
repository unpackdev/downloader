// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

/// @title Player Edition
/// @notice The official membership token for PlayerDAO
/// @author swa.eth

/////////////////////////////////////////////////////////////////////////////////////////
///                                                                                   ///
///                                                                                   ///
///     ██████╗░██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░██████╗░░█████╗░░█████╗░     ///
///     ██╔══██╗██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗     ///
///     ██████╔╝██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝██║░░██║███████║██║░░██║     ///
///     ██╔═══╝░██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗██║░░██║██╔══██║██║░░██║     ///
///     ██║░░░░░███████╗██║░░██║░░░██║░░░███████╗██║░░██║██████╔╝██║░░██║╚█████╔╝     ///
///     ╚═╝░░░░░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░     ///
///                                                                                   ///
///                                                                                   ///
/////////////////////////////////////////////////////////////////////////////////////////

import "./ERC721URIStorage.sol";
import "./AccessControl.sol";

contract PlayerEdition is ERC721URIStorage, AccessControl {
    /// Interface identifier for on-chain royalty standard
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /// ======================
    /// ===== USER ROLES =====
    /// ======================
    bytes32 private constant ADMIN_ROLE  = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// Base URI of token metadata
    string private baseURI = "ar://";
    /// Address of contract admin
    address public immutable GNOSIS_SAFE;
    /// Token ID of next mint
    uint256 public nextTokenId;

    /// ========================
    /// ===== ROYALTY INFO =====
    /// ========================
    address public beneficiary;
    uint256 public percentage;

    /// =======================
    /// ===== EVENT LOGS ======
    /// =======================
    event AuctionMint(uint256 indexed _tokenId, address indexed _to);
    event PlayerMint (uint256 indexed _tokenId, address indexed _to);

    /// @notice Initializes contract state and sets up user roles.
    constructor(address _admin) ERC721("Player Edition", "PE") {
        nextTokenId = 1;
        percentage  = 10;
        beneficiary = _admin;
        GNOSIS_SAFE = _admin;

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);

        _setupRole(ADMIN_ROLE, GNOSIS_SAFE);
        _setupRole(MINTER_ROLE, GNOSIS_SAFE);
    }

    /// ============================
    /// ===== MINTER FUNCTIONS =====
    /// ============================

    /// @notice Mints single auction token to sender.
    function auctionMint(string calldata _arweaveId) external onlyRole(MINTER_ROLE) {
        _mintPE(msg.sender, nextTokenId, _arweaveId);
        emit AuctionMint(nextTokenId, msg.sender);
        unchecked {
            ++nextTokenId;
        }
    }

    /// @notice Batch mints list of tokens to list of players.
    function playerMint(address[] calldata _players, string[] calldata _arweaveIds) external onlyRole(MINTER_ROLE) {
        uint256 length = _players.length;
        unchecked {
            for (uint256 i; i < length; ++i) {
                _mintPE(_players[i], nextTokenId, _arweaveIds[i]);
                emit PlayerMint(nextTokenId, _players[i]);
                ++nextTokenId;
            }
        }
    }

    /// @notice Creates token, transfers to sender and sets tokenURI.
    function _mintPE(address _to, uint256 _tokenId, string calldata _tokenURI) private {
        _safeMint(_to, _tokenId, "");
        _setTokenURI(_tokenId, _tokenURI);
    }

    /// ===========================
    /// ===== ADMIN FUNCTIONS =====
    /// ===========================

    /// @notice Repairs metadata for list of tokens.
    function repairMetadata(uint256[] calldata _tokenIds, string[] calldata _tokenURIs) external onlyRole(ADMIN_ROLE) {
        uint256 length = _tokenIds.length;
        unchecked {
            for (uint256 i; i < length; ++i) {
                _setTokenURI(_tokenIds[i], _tokenURIs[i]);
            }
        }
    }

    /// @notice Sets prefix URI for all tokens.
    function setBaseURI(string calldata _uri) external onlyRole(ADMIN_ROLE) {
        baseURI = _uri;
    }

    /// @notice Sets royalty info for on-chain royalties.
    function setRoyaltyInfo(address _beneficiary, uint256 _percent) external onlyRole(ADMIN_ROLE) {
        beneficiary = _beneficiary;
        percentage  = _percent;
    }

    /// ==========================
    /// ===== VIEW FUNCTIONS =====
    /// ==========================

    /// @notice Returns how much royalty is owed and to whom.
    /// @dev See {IERC2981-royaltyInfo}.
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
        return (beneficiary, (_salePrice * percentage) / 100);
    }

    /// @notice Checks support of interface identifier for on-chain royalties.
    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    /// @notice Returns total number of tokens existing on this contract.
    function totalSupply() public view returns (uint256) {
        return nextTokenId - 1;
    }

    /// @notice Returns prefix URI used for each token.
    /// @dev See {ERC721-baseURI}.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
