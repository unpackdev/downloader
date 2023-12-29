//
//
//                                   ██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓██
//                            ██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓██
//                        █▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█
//                    █▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█
//                ████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓███
//             ██████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓██████
//          █████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██████████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█████████
//       ███████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█████████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓███████████
//     █████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█████████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████████████
//   ███████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓███████████████
//   ███████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓███████████████
//     █████████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████████████
//       ████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█████████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████████████
//          █████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████████
//             ███████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████
//                ████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█████████▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓████
//                   ██▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓██
//                       ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
//                            █▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓█
//                                  ███▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓███
//
//
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC4906.sol";
import "./IERC165.sol";
import "./IERC721Enumerable.sol";
import "./IPanopticonRenderer.sol";
import "./INFT.sol";
import "./Freezable.sol";

error TokenNotFound();
error NotMinter();
error NoSupplyLeft();
error InvalidAmount();

contract Panopticon is ERC721, IERC721Enumerable, IERC4906, Freezable, INFT {
    uint16 public nextTokenId;
    uint16 public maxSupply;
    uint16 public maxReserveSupply;
    address public minter;
    mapping(uint256 => uint256) public tokenHash;
    IPanopticonRenderer public renderer;

    constructor(uint16 _maxSupply, uint16 _maxReserveSupply, address _renderer) ERC721("Panopticon", "PAN") {
        require(_maxSupply >= _maxReserveSupply);

        maxSupply = _maxSupply;
        maxReserveSupply = _maxReserveSupply;
        renderer = IPanopticonRenderer(_renderer);
    }

    modifier tokenExists(uint256 tokenId) {
        if (tokenHash[tokenId] == 0) {
            revert TokenNotFound();
        }
        _;
    }

    modifier hasSupplyLeft() {
        if (nextTokenId >= maxSupply) {
            revert NoSupplyLeft();
        }
        _;
    }

    modifier hasReserveSupplyLeft(uint256 amount) {
        if (nextTokenId + amount > maxReserveSupply) {
            revert NoSupplyLeft();
        }
        _;
    }

    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert NotMinter();
        }
        _;
    }

    function tokenURI(uint256 tokenId) public view override tokenExists(tokenId) returns (string memory) {
        return renderer.tokenURI(tokenId, tokenHash[tokenId]);
    }

    function tokenHTML(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        return renderer.getHTML(tokenId, tokenHash[tokenId]);
    }

    function tokenImageURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        return renderer.getImage(tokenId, tokenHash[tokenId]);
    }

    function totalSupply() external view returns (uint256) {
        return nextTokenId;
    }

    function currentTokenId() external view returns (uint16) {
        return nextTokenId;
    }

    function tokenIdMax() external view returns (uint16) {
        return maxSupply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < nextTokenId, "ERC721Enumerable: global index out of bounds");
        return _index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * @dev Can use up to 200k gas with one call. Should not be called from on-chain
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        uint256 _currentOwnerIndex = 0;
        uint256 _nextTokenId = nextTokenId;
        uint256 i = 0;

        while (i < _nextTokenId) {
            if (_ownerOf(i) == _owner) {
                if (_currentOwnerIndex == _index) {
                    return i;
                }

                unchecked {
                    ++_currentOwnerIndex;
                }
            }

            unchecked {
                ++i;
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    // @dev Minter must check for reentrancy
    function mint(address to) external override onlyMinter hasSupplyLeft {
        _mint(to);
    }

    function mintReserve(address to, uint256 amount) external onlyOwner hasReserveSupplyLeft(amount) {
        for (uint256 i = 0; i < amount;) {
            _mint(to);

            unchecked {
                ++i;
            }
        }
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setRenderer(IPanopticonRenderer _renderer) external onlyOwner notFrozen {
        renderer = _renderer;
        _emitMetadataUpdated();
    }

    function refreshMetadata() external onlyOwner notFrozen {
        _emitMetadataUpdated();
    }

    function endMint() external onlyOwner hasSupplyLeft {
        maxSupply = nextTokenId;
    }

    function _mint(address to) internal {
        uint256 _nextTokenId = nextTokenId;
        tokenHash[_nextTokenId] = _generateTokenHash(_nextTokenId);
        _safeMint(to, _nextTokenId);
        unchecked {
            ++nextTokenId;
        }
    }

    // @dev - Emit ERC-4906 metadata update event if any tokens are minted
    function _emitMetadataUpdated() internal {
        uint256 _nextTokenId = nextTokenId;
        if (_nextTokenId > 0) {
            emit BatchMetadataUpdate(0, _nextTokenId - 1);
        }
    }

    function _generateTokenHash(uint256 _tokenId) internal view returns (uint256) {
        uint256 eyesOnBlock = block.number - (1 + _tokenId % 128);
        return uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(eyesOnBlock),
                    msg.sender,
                    _tokenId
                )
            )
        );
    }
}
