// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: BLOCKS
/// @author: manifold.xyz
 
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./AdminControl.sol";

import "./ABDKMath64x64.sol";
import "./ERC721SingleCreatorExtensionBase.sol";

import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

/**
 * BlocksERC721LazyAllowlistBase v1.1 - ERC721 Lazy Mint with Allowlist interface + additional Blocks functions
 */

abstract contract BlocksERC721LazyAllowlistBase is ERC721SingleCreatorExtensionBase, ICreatorExtensionTokenURI, ReentrancyGuard {
    using Strings for uint256;
    using ABDKMath64x64 for uint;

    string private _tokenPrefix;
    uint256 private _tokensMinted;
    mapping(uint256 => uint256) private _tokenEdition;
    bytes32 _merkleRoot;

    uint256 private _mintPrice;
    uint256 private _maxMints;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId;
    }

    function _initialize(address creator, string memory prefix, uint256 mintPrice, uint256 maxMints) internal {
      require(_creator == address(0), "Already initialized");
      _setCreator(creator);
      _tokenPrefix = prefix;
      
      _mintPrice = mintPrice;
      _maxMints = maxMints;
    }

    function onAllowList(address claimer, bytes32[] memory proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    function _setAllowList(bytes32 merkleRoot) internal {
        _merkleRoot = merkleRoot;
    }

    /**
     * @dev Premint direct to addresses
     */
    function _premint(address[] memory to) internal {
        for (uint i = 0; i < to.length; i++) {
            _tokenEdition[IERC721CreatorCore(_creator).mintExtension(to[i])] = _tokensMinted + i + 1;
        }
        _tokensMinted += to.length;
        _maxMints += to.length; // Extend max mints when preminting
    }
    
    /**
     * @dev Mint token if you are on the whitelist
     */
    function _mint(bytes32[] memory merkleProof) internal {
        require(_tokensMinted < _maxMints, "Not enough mints left");
        require(_mintPrice == msg.value, "Not enough ETH");
        require(onAllowList(msg.sender, merkleProof), "Not on allowlist");

        _tokenEdition[IERC721CreatorCore(_creator).mintExtension(msg.sender)] = _tokensMinted + 1;
        _tokensMinted += 1;
    }

    /**
     * Set the token URI prefix
     */
    function _setTokenURIPrefix(string calldata prefix) internal {
        _tokenPrefix = prefix;
    }

    /**
     * Set the token mint price
     */
    function _setMintPrice(uint256 mintPrice) internal {
        _mintPrice = mintPrice;
    }

    /**
     * Set the token max mints
     */
    function _setMaxMints(uint256 maxMints) internal {
        _maxMints = maxMints;
    }    

    function _withdraw(address to, uint amount) internal {
        payable(to).transfer(amount);
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _tokenEdition[tokenId] != 0, "Invalid token");
        return  string(abi.encodePacked(_tokenPrefix, _tokenEdition[tokenId].toString()));
    }
    
}
