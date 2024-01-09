// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Initializable.sol";

/// @author MTCrypto Team
/// @title The smart contract for the Galaget GA-NFT
contract Galaget is
    Context,
    Ownable,
    ERC721,
    ERC721Enumerable,
    ERC721Pausable {

    string private _baseTokenURI;

    // For EIP-2981 support.
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint16 public constant TOKEN_LIMIT = 4444;

    /// @dev Initializes a Galaget contract using {ERC721} as a base.
    /// @param name The name for the token
    /// @param symbol The symbol for the token
    /// @param baseTokenURI The base URI that will be prepended to all tokenURIs
    constructor (string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    /// @notice Withdraws the funds of this contract to the specified recipient. The caller must be the contract owner.
    /// @param recipient The address the funds will be withdrawn to
    function withdraw(address recipient) external payable onlyOwner {
        (bool sent,) = payable(recipient).call{value : address(this).balance}("");
        require(sent);
    }

    /// @notice Changes the base token URI for all tokens. Only to be used in-case a critical bug is found in the game.
    /// @param newBaseURI The new base token URI to be set
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /// @notice Provides a 4% royalty calculation for token sales.
    /// @dev Needs to be implemented for EIP-2981 compliance
    /// @dev tokenId Ignored, all tokens will calculate with a 4% royalty.
    /// @param _salePrice The price of the token sale which will be used to calculate to 4% royalty.
    function royaltyInfo(uint256 , uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (owner(), (_salePrice * 400) / 10000);
    }

    /// @notice Returns the URI for this contract's metadata.
    function contractURI() external pure returns (string memory) {
        return "https://galaget.com/galaget-contract-metadata.json";
    }

    /// @notice Mints a single Galaget GA-NFT in incremental order. If caller is not the contract owner, they must
    ///  include the required amount of ETH returned by getMintPrice().
    function mintToken() public payable virtual {
        uint256 tokenId = totalSupply();
        require(tokenId <= TOKEN_LIMIT, "Limit");
        if (_msgSender() != owner()) {
            require(msg.value >= getMintPrice(tokenId));
        }
        _mint(_msgSender(), tokenId);
    }

    /// @notice Pauses all token transfers. The caller must be the contract owner.
    function pause() public virtual onlyOwner {
        _pause();
    }

    /// @notice Unpauses all token transfers. The caller must be the contract owner.
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /// @notice Returns the token URI for the given token ID.
    /// @param tokenId The token id for which to retrieve the URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    /// @dev See {IERC165-supportsInterface}. Also includes interface ID for EIP-2981.
    /// @param interfaceId The ID of interface to test for
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /// @dev The price of minting depends on how many tokens are minted. The price starts at 0.02 ETH and as each
    ///  quarter of the total tokens are minted the price increases by 0.02 ETH until 0.08 ETH.
    /// @param tokenId The token Id to retrieve minting pricing for
    function getMintPrice(uint256 tokenId) public pure returns (uint256) {
        if (tokenId < 1111) {
            return 20000000 gwei;
        } else if (tokenId < 2222) {
            return 40000000 gwei;
        } else if (tokenId < 3333) {
            return 60000000 gwei;
        } else {
            return 80000000 gwei;
        }
    }

    /// @dev Returns the base URI which is prepended to every token Id.
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Overrides _beforeTokenTransfer for ERC721, ERC721Enumerable, ERC721Pausable.
    /// @inheritdoc ERC721
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
