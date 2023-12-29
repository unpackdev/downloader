// SPDX-License-Identifier: MIT

//               .-+*#%@@@                    %-                      :+*#%%@@@@@#+-.
//           .  %@@@@@@@@#                    %-                    =@@@@@@@@@@@@@@@@#:
//          =@: @@@@@@@@@.                    %-                  :%@@@@@@@@@@@@@@@@@@@+
//       -* +@: @@@@@@@@:                     %-                 *@@@@@@@@@@@@@@@@@@@@@@#
//       @# +@: @@@@@@%.                      %-               :#@@@@%=+++=-:-+#@@@@@@@@@#
//    =: @# +@: @@@@@+                        %-               @@@@%:           .%@@@@@@@@#
//   +@: @# +@: @@@*.                         %-              :@@@@+ .::------=+#@@@@@@@@@@*
//  =@@: @# +@: %+.                           %-             .@@@@@@@@@@%#%@@@@@@@@@@@@@@@@@:
// .@@@: @# +@: ======-:.                     %-             :@@@@@=%@*.   .*@@@@@@@@@@@@@@@=
// +@@%. @# +@: @@@@@@@@@@@#+-.               %-              %@@@@+=# ---=..-%@@@@@@@@@@@@@.
//   =#. @# +@: @@@@@@@@@@@@@@@%+.            %-              @@@@@@@*     =@#%@@@@@@@@@@@@@
// =@@@: @# +@: @@@@@@@@@@@@@@@@@@*           %-             -@@@@@@@@*=--*@@@@@@@@@@@@@@@@@
//  .=#: @# +@: @@@@@@@@@@@@@@@@*:            %-             -@@@@@@@@@%**@@@@@@@@@@@@@@@@@@
// +%%#. @# +@: @@@@@@@@@@@%*=.               %-             .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
// .@@@: @# +@: =++++==-:.                    %-              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
//  +@@: @# +@: #=.                           %-              #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#
//   *@: @# +@: @@@*.                         %-              -@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%
//    +: @# +@: @@@@@=                        %-              -@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
//       @# +@: @@@@@@#.                      %-              .@@@@@@@@@@@@@@@@@@@@@@@@@@@#.
//       =# +@: @@@@@@@%.                     %-               -#@@@@@@@@@@@@@@@@@@@@@@@#:
//          =@: @@@@@@@@%                     %-                 -@@@@@@@@@@@@@@@@@@@%+.
//           .. @@@@@@@@@*                    %-                   =%@%@@@@@@@@@@@@#:
//               :=+#%@@@@                    %-                        =%%@@@@@@=
//                                            %-
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./ERC2981.sol";

interface IERC1155Migration {
    function burn(address account, uint256 id, uint256 value) external;
}

/**
 * @title AdidasBapeFreshForum
 * @notice This contract enables adidas x BAPE® auction winners to mint their digital twin and claim the physical product
 * @dev Uses ERC721A, enables one mint per ERC1155, one at a time to support physical claim logic
 */
contract AdidasBapeFreshForum is ERC721ABurnable, ERC721AQueryable, ERC2981, Ownable, Pausable {
    /// @dev Metadata base URI
    string public baseUri;
    /// @dev Token name
    string private _name;
    /// @dev Token symbol
    string private _symbol;
    /// @dev 1155 contract
    IERC1155Migration public erc1155;
    /// @dev contractURI
    string private _contractURI;
    /// @dev mapping of tokenIds to sizes
    mapping(uint256 => uint256) private _tokenSizes;

    constructor(
        string memory __name,
        string memory __symbol,
        address _ERC1155address,
        string memory _baseUri,
        string memory _uri,
        address _royaltyReceiver,
        uint96 _royaltyValue
    ) ERC721A(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
        erc1155 = IERC1155Migration(_ERC1155address);
        baseUri = _baseUri;
        _contractURI = _uri;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyValue);
    }

    /**
     * @notice Returns the name of the ERC721 token.
     * @return The name of the token.
     */
    function name() public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the ERC721 token.
     * @return The symbol of the token.
     */
    function symbol() public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Allows the owner to change the name and symbol of the ERC721 token.
     * @dev Only callable by the owner.
     * @param newName The new name for the token.
     * @param newSymbol The new symbol for the token.
     */
    function setNameAndSymbol(string calldata newName, string calldata newSymbol) public onlyOwner {
        _name = newName;
        _symbol = newSymbol;
    }

    /**
     * @notice Returns the base URI for the token's metadata.
     * @return The current base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    /**
     * @notice Changes the base URI for the token metadata.
     * @dev Only callable by the owner.
     * @param _baseUri The new base URI.
     */
    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    /**
     * @notice Returns the contract's metadata URI.
     * @return The URI of the contract.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Changes the contract's URI.
     * @dev Only callable by the owner.
     * @param newContractURI The new contract URI.
     */
    function setContractUri(string calldata newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    /**
     * @notice Burns an ERC1155 access pass and mints an ERC721 digital twin.
     * @dev Only callable when contract is not paused.
     * @param size The size (or id) of the ERC1155 token to be burned.
     */
    function burnAndMint(uint256 size) external whenNotPaused {
        erc1155.burn(msg.sender, size, 1);
        _mint(msg.sender, 1);
        uint256 mintedTokenId = _totalMinted();
        _tokenSizes[mintedTokenId] = size;
    }

    /**
     * @notice Mints multiple ERC721 tokens.
     * @dev Only callable by the owner.
     * @param to An array of addresses to mint the tokens to.
     * @param sizes An array of sizes (or ids) corresponding to each minted token.
     */
    function mintMany(address[] calldata to, uint256[] calldata sizes) external onlyOwner {
        uint256 count = to.length;
        require(count == sizes.length, "Mismatched lengths");
        unchecked {
            for (uint256 i = 0; i < count; i++) {
                _mint(to[i], 1);
                uint256 mintedTokenId = _totalMinted();
                _tokenSizes[mintedTokenId] = sizes[i];
            }
        }
    }

    /**
     * @notice Retrieves the sizes (or ids) of multiple ERC721 tokens.
     * @param tokenIds An array of tokenIds to retrieve sizes for.
     * @return sizes An array of sizes corresponding to the given tokenIds.
     */
    function getTokenSizes(uint256[] calldata tokenIds) external view returns (uint256[] memory) {
        uint256[] memory sizes = new uint256[](tokenIds.length);
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                sizes[i] = _tokenSizes[tokenIds[i]];
            }
        }
        return sizes;
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @dev Overrides supportsInterface from multiple inherited contracts.
     * @param interfaceId The id of the interface to check.
     * @return bool True if the interface is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
