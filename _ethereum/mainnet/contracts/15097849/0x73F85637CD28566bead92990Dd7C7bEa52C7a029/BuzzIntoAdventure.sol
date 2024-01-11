//SPDX-License-Identifier: MIT
/// @author OPTEN AG
/// Website: https://www.opten.ch

pragma solidity >=0.8.10 <0.9.0;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

error ExceedsMaximumSupply();

contract BuzzIntoAdventure is ERC721, AccessControl, Ownable {
    string private _baseTokenURI;
    uint256 private _currentTokenId;

    uint256 public constant MAX_SUPPLY = 50;

    constructor() ERC721("Buzz into adventure", "ABIA") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Safely mints token and transfers them to `to`.
    function drop(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 nextTokenId = totalSupply();
        if (nextTokenId >= MAX_SUPPLY) revert ExceedsMaximumSupply();
        unchecked {
            // Overflows are unrealistic due to the above check for `nextTokenId` to be below the supply.
            _currentTokenId++;
        }
        _safeMint(to, nextTokenId);
    }

    /// @notice Returns the total number of tokens in existence.
    function totalSupply() public view returns (uint256) {
        unchecked {
            return _currentTokenId;
        }
    }

    /**
     * @notice Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i; tokenIdsIdx != tokenIdsLength; ++i) {
                if (!_exists(i)) {
                    continue;
                }
                if (ownerOf(i) == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Sets the base token URI prefix.
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}