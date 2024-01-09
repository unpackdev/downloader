// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5 <0.9.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract FRNFT is Ownable, ERC721URIStorage {
	// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
	bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;
	address marketplaceAddress;
	mapping(bytes4 => bool) private _supportedInterfaces;

	struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

	mapping(uint256 => RoyaltyInfo) internal _royalties;
	

	constructor(address _marketplaceAddress) ERC721("Franklin NFT", "FRNFT") {
		marketplaceAddress = _marketplaceAddress;
	}

    event Burned(uint256 nftID);


	/**
	 * Creates a new token
	 */
	function mintNFT(string memory tokenURI, address royaltyRecipient, uint256 royaltyValue) public returns (uint) {
		_tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(marketplaceAddress, true);

		if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue);
        }

		return newItemId;
	}

	function mintBatch(
        string[] memory tokenURI,
		address[] memory royaltyRecipient,
		uint256[] memory royaltyValue,
        uint256[] memory quantity
    ) public {

        for (uint256 i = 0; i < tokenURI.length; i++) {
            for (uint256 j = 0; j < quantity[i]; j++) {
                _tokenIds.increment();
                uint256 newItemId = _tokenIds.current();
                _mint(msg.sender, newItemId);
                _setTokenURI(newItemId, tokenURI[i]);
				if (royaltyValue[i] > 0) {
            		_setTokenRoyalty(newItemId, royaltyRecipient[i], royaltyValue[i]);
        		}
            }
        }
        setApprovalForAll(marketplaceAddress, true);

    }

	//burn nft
    function removeNFT(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
            
        _burn(_tokenId);
        emit Burned(_tokenId);

    }


	/**
	 * Sets token royalties recipient and percentage value (with two decimals) for a certain token
	 */
	function _setTokenRoyalty(uint256 tokenId, address recipient, uint256 value) internal {
        require(value <= 5000, 'Franklin NFT: Royalties value cannot be higher than 5000.');
        _royalties[tokenId] = RoyaltyInfo(recipient, uint24(value));
    }


	/**
	 * Returns royalties recipient and amount for a certain token and sale value,
	 * following EIP-2981 guidelines (https://eips.ethereum.org/EIPS/eip-2981).
	 */
    function royaltyInfo(uint256 tokenId, uint256 saleValue) external view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalty = _royalties[tokenId];
        return (royalty.recipient, (saleValue * royalty.amount) / 10000);
    }


	/**
	 * Overrides supportsInterface method to include EIP-2981 support for interface.
	 */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ERC2981;
    }

}