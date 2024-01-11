// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./AccessControl.sol";
import "./Counters.sol";

contract Thisabled1155 is ERC1155, ERC1155Supply, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant STOREFRONT_ROLE = keccak256("STOREFRONT_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    string private baseURI;
    string private _contractURI;
    Counters.Counter private tokenIdCounter;
    mapping (uint256 => string) private tokenURIs;
    mapping (uint256 => uint256) maxPrints;

    event ArtworkAdded (
    	uint256 indexed tokenId,
    	string uri,
    	uint256 maxPrints
    );

    constructor() ERC1155("") {
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      baseURI = "https://ipfs.io/ipfs/";
      _contractURI = "QmckKdyqRghAd6dTiZgj6DWH8ARVu1pZ5TjzmhQgatjbT8";
      //Skip token ID 0 for record keeping purposes
      tokenIdCounter.increment();
    }

    function contractURI()
    	public
    	view
    	returns (string memory)
    {
      return string(abi.encodePacked(baseURI, _contractURI));
    }

    function updateContractURI(string memory newContractURI)
    	public
    	onlyRole(URI_SETTER_ROLE)
    {
       _contractURI = newContractURI;
    }

    function baseTokenURI()
    	public
    	view
    	returns (string memory)
    {
      return baseURI;
    }

    function updateBaseURI(string memory newBaseURI)
    	public
    	onlyRole(URI_SETTER_ROLE)
    {
      baseURI = newBaseURI;
    }

    function uri(uint256 tokenId)
    	public
    	view
    	override
    	returns (string memory)
    {
      return(string(abi.encodePacked(baseURI, tokenURIs[tokenId])));
    }

    function tokenURI(uint256 tokenId)
      public
      view
      returns (string memory)
    {
      return uri(tokenId);
    }

    function addArtwork(string memory _uri, uint256 printCount)
    	public
    	onlyRole(STOREFRONT_ROLE)
    	returns (uint256)
    {
    	uint256 tokenId = tokenIdCounter.current();
    	tokenIdCounter.increment();
    	tokenURIs[tokenId] = _uri;
    	maxPrints[tokenId] = printCount;
    	emit ArtworkAdded(
    		tokenId,
    		_uri,
    		printCount
    	);
    	return tokenId;
    }

    function batchAddArtwork(string[] memory uris, uint256[] memory printCounts)
    	public
    	onlyRole(STOREFRONT_ROLE)
    	returns (uint256[] memory)
    {
    	require(uris.length == printCounts.length, "Every URI must have a print count");
    	uint256[] memory tokenIds = new uint256[](uris.length);
    	for(uint256 i = 0; i < uris.length; i++){
    		tokenIds[i] = tokenIdCounter.current();
    		tokenIdCounter.increment();
        	tokenURIs[tokenIds[i]] = uris[i];
        	maxPrints[tokenIds[i]] = printCounts[i];
        	emit ArtworkAdded(
	    		tokenIds[i],
	    		uris[i],
	    		printCounts[i]
	    	);
    	}
    	return tokenIds;
    }

    function getMaxPrints(uint256 tokenId)
    	public
    	view
    	returns (uint256)
    {
    	return(maxPrints[tokenId]);
    }

    function getAvailablePrints(uint256 tokenId)
    	public
    	view
    	returns (uint256)
    {
    	return(maxPrints[tokenId] - totalSupply(tokenId));
    }

    function mint(address account, uint256 id, uint256 amount)
      public
      onlyRole(STOREFRONT_ROLE)
    {
    	require(getAvailablePrints(id) >= amount, "Print maximum exceeded");
      _mint(account, id, amount, "0x0");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
      public
      onlyRole(STOREFRONT_ROLE)
    {
    	require(ids.length == amounts.length, "Each ID must have an amount");
    	for(uint256 i = 0; i < ids.length; i++){
    		require(getAvailablePrints(ids[i]) >= amounts[i], "Print maximum exceeded");
    	}
      _mintBatch(to, ids, amounts, "0x0");
    }

    function burn(address account, uint256 id, uint256 value)
      public
    {
      require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not owner nor approved");
      _burn(account, id, value);
      maxPrints[id] -= value;
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values)
      public
    {
      require(account == _msgSender() || isApprovedForAll(account, _msgSender()), "ERC1155: caller is not owner nor approved");
      _burnBatch(account, ids, values);
      for(uint256 i = 0; i < ids.length; i++){
    	  maxPrints[ids[i]] -= values[i];
    	}
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
      internal
      override(ERC1155, ERC1155Supply)
    {
      super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC1155, AccessControl)
      returns (bool)
    {
      return super.supportsInterface(interfaceId);
    }
}
