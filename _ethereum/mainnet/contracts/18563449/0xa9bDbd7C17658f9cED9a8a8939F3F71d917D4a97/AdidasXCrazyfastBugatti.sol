// SPDX-License-Identifier: MIT
//                                            .
//                                            .
//                                            .
//                   .:-                      .           :====================-.
//                .-+++++.                    .           -++========++++=====+++=
//                ++++++++.                   .           .::.      :+++-      -++-
//             .:  =+++++++:                  .               .==-  -+++-    ..+++-
//          :-+++-  =+++++++-                 .               .++++++++++++++++++=
//        .+++++++=  -+++++++-                .               .+++--=+++=-----=+++:
//         .+++++++=  :+++++++=               .                ..   :+++-      :+++
//   .-=++. .++++++++. .++++++++              .           :==.      :+++-      -++=
// :+++++++:  =+++++++. .++++++++.            .           -++++++++++++++++++++++-
//  ::::::::   ::::::::   ::::::::            .           .::::::::::::::::::::.
//                                            .
//                                            .
pragma solidity ^0.8.23;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721.sol";
import "./ERC2981.sol";

interface IERC1155Migration {
    function burn(address account, uint256 id, uint256 value) external;
}

/**
 * @title AdidasXCrazyfastBugatti
 * @notice This contract enables adidas X Crazyfast Bugatti auction winners to mint their digital twin and claim the physical product
 * @dev Uses ERC721, enables one mint per ERC1155, one at a time to support physical claim logic
 */
contract AdidasXCrazyfastBugatti is ERC721, ERC2981, Ownable, Pausable {
    /// @dev Metadata base URI
    string public baseUri;
    /// @dev Token name
    string private _name;
    /// @dev Token symbol
    string private _symbol;
    /// @dev 1155 contract
    IERC1155Migration public erc1155;
    /// @dev Keep track of total supply
    uint256 private _totalSupply;

    constructor(
        string memory __name,
        string memory __symbol,
        address _ERC1155address,
        string memory _baseUri,
        address _royaltyReceiver,
        uint96 _royaltyValue
    ) ERC721(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
        erc1155 = IERC1155Migration(_ERC1155address);
        baseUri = _baseUri;
        _setDefaultRoyalty(_royaltyReceiver, _royaltyValue);
    }

    /**
     * @notice Returns the name of the ERC721 token.
     * @return The name of the token.
     */
    function name() public view virtual override(ERC721) returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the ERC721 token.
     * @return The symbol of the token.
     */
    function symbol() public view virtual override(ERC721) returns (string memory) {
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

    /// @dev Mint override for totalSupply
    function _mint(address to, uint256 tokenId) internal virtual override {
        super._mint(to, tokenId);
        _totalSupply += 1;
    }

    /**
     * @notice Burns one ERC1155 access pass and mints one ERC721 digital twin.
     * @dev Only callable when contract is not paused.
     * @param id The id (box #) of the ERC1155 token to be burned.
     */
    function burnAndMint(uint256 id) external whenNotPaused {
        erc1155.burn(msg.sender, id, 1);
        _mint(msg.sender, id);
    }

    /**
     * @notice Mints multiple ERC721 tokens.
     * @dev Only callable by the owner.
     * @param to An array of addresses to mint the tokens to.
     * @param ids An array of ids corresponding to each minted token.
     */
    function mintMany(address[] calldata to, uint256[] calldata ids) external onlyOwner {
        uint256 count = to.length;
        require(count == ids.length, "Mismatched lengths");
        unchecked {
            for (uint256 i = 0; i < count; i++) {
                _mint(to[i], ids[i]);
            }
        }
    }

    /**
     * @notice Returns an array of tokenIds held by the given wallet address.
     * @dev Alternative to using ERC721Enumerable given small batch size.
     * @param owner The address to query.
     * @param start The starting index for the token range.
     * @param end The ending index for the token range.
     * @return tokenIds An array of token IDs owned by the given address.
     */
    function tokensOfOwner(
        address owner,
        uint256 start,
        uint256 end
    ) public view returns (uint256[] memory) {
        require(end >= start, "End index must be greater than or equal to start index");

        uint256 maxCount = end - start + 1;
        uint256[] memory tokenIds = new uint256[](maxCount);
        uint256 count = 0;

        unchecked {
            for (uint256 i = start; i <= end; i++) {
                try this.ownerOf(i) returns (address tokenOwner) {
                    if (tokenOwner == owner) {
                        tokenIds[count++] = i;
                    }
                } catch {
                    continue;
                }
            }
        }

        if (count != maxCount) {
            uint256[] memory n = new uint256[](count);
            unchecked {
                for (uint256 j = 0; j < count; j++) {
                    n[j] = tokenIds[j];
                }
                return n;
            }
        }

        return tokenIds;
    }

    /**
     * @notice The total supply of all minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Pauses the contract, blocking all state-changing operations
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing state-changing operations
    function unpause() external onlyOwner {
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
