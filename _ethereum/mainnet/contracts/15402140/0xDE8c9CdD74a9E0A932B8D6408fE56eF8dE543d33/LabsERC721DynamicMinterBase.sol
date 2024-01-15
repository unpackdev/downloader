// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: PuppetSamurai
/// @author: manifold.xyz
 
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./ABDKMath64x64.sol";
import "./ERC721SingleCreatorExtensionBase.sol";

import "./Strings.sol";

/*

*/

abstract contract LabsERC721DynamicMinterBase is ERC721SingleCreatorExtensionBase, ICreatorExtensionTokenURI {
    using Strings for uint256;
    using ABDKMath64x64 for uint;

    string private _tokenPrefix;
    uint256 private _tokensMinted;
    mapping(uint256 => uint256) private _tokenEdition;

    uint256 private _mintPrice;
    uint256 private _maxMints;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId;
    }

    function _initialize(address creator, string memory prefix, uint256 mintPrice, uint256 mintMax) internal {
      require(_creator == address(0), "Already initialized");
      _setCreator(creator);
      _tokenPrefix = prefix;
      
      _mintPrice = mintPrice;
      _maxMints = mintMax;
    }

    /**
     * @dev Premint direct to addresses
     */
    function _premint(address[] memory to) internal {
        for (uint i = 0; i < to.length; i++) {
            _tokenEdition[IERC721CreatorCore(_creator).mintExtension(to[i])] = _tokensMinted + i + 1;
        }

        _tokensMinted += to.length;
    }    
    
    /**
     * @dev Mint token(s)
     */
	function _mint(uint256 quantity) internal {
		require(quantity <= 3, "Too many mints per batch");
		require(_tokensMinted + quantity <= _maxMints, "Not enough mints left");
        require((_mintPrice * quantity) == msg.value, "Not enough ETH");
		
		for (uint256 i = 0; i < quantity; i++) {			
	        _tokenEdition[IERC721CreatorCore(_creator).mintExtension(msg.sender)] = _tokensMinted + i + 1;
		}

        _tokensMinted += quantity;
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
    function _setMaxMints(uint256 mintMax) internal {
        _maxMints = mintMax;
    }    

    function _getMaxMints() internal view returns (uint256) {
        return _maxMints;
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
