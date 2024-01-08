// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC165Spec.sol";
import "./ERC721Spec.sol";
import "./AletheaERC721Spec.sol";
import "./StringUtils.sol";
import "./AccessControl.sol";

/**
 * @title OpenSea ERC721 Factory interface
 *
 * @notice In order to mint items only when they're purchased, OpenSea provides a Factory interface
 *      that is used to define how the items will be minted.
 *      See https://docs.opensea.io/docs/2-custom-item-sale-contract
 *
 * @notice This is a generic factory contract that can be used to mint tokens. The configuration
 *      for minting is specified by an _optionId, which can be used to delineate various
 *      ways of minting.
 *
 * @dev Copy of the OpenSea interface:
 *      https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/IFactoryERC721.sol
 */
interface OpenSeaFactoryERC721 is ERC165 {
	/**
	 * @dev Returns the name of this factory.
	 */
	function name() external view returns (string memory);

	/**
	 * @dev Returns the symbol for this factory.
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev Number of options the factory supports.
	 */
	function numOptions() external view returns (uint256);

	/**
	 * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
	 *      restrict a total supply per option ID (or overall).
	 */
	function canMint(uint256 _optionId) external view returns (bool);

	/**
	 * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
	 *      same structure as the ERC721 metadata.
	 */
	function tokenURI(uint256 _optionId) external view returns (string memory);

	/**
	 * @dev Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
	 */
	function supportsFactoryInterface() external view returns (bool);

	/**
	 * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
	 *      callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
	 *      Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
	 * @param _optionId the option id
	 * @param _toAddress address of the future owner of the asset(s)
	 */
	function mint(uint256 _optionId, address _toAddress) external;
}

/**
 * @dev An OpenSea delegate proxy interface which we use in ProxyRegistry.
 *      We use it to give compiler a hint that ProxyRegistry.proxies() needs to be
 *      converted to the address type explicitly
 */
interface OwnableDelegateProxy {}

/**
 * @dev OpenSea Proxy Registry determines which address (wrapped as OwnableDelegateProxy)
 *      is allowed to mint an option at any given time
 * @dev OpenSea takes care to set it properly when an option is being bought
 */
interface ProxyRegistry {
	/**
	 * @dev Maps owner address => eligible option minter address wrapped as OwnableDelegateProxy
	 */
	function proxies(address) external view returns(OwnableDelegateProxy);
}

/**
 * @title OpenSea ERC721 Factory implementation
 *
 * @notice OpenSea Factory interface implementation, NFT minter contract,
 *      powers the OpenSea sale of the 9,900 personalities of the 10k sale campaign
 *
 * @dev Links to PersonalityPodERC721 smart contract on deployment, allows OpenSea to mint
 *      PersonalityPodERC721 from 101 to 10,000 (both bounds inclusive)
 *
 * @dev Each OpenSea Factory option ID is used to signify the minting of one random type of
 *      Personality Pod
 */
contract OpenSeaFactoryImpl is OpenSeaFactoryERC721, AccessControl {
	/**
	 * @dev OpenSea expects Factory to be "Ownable", that is having an "owner",
	 *      we introduce a fake "owner" here with no authority
	 */
	address public owner;

	/**
	 * @dev NFT ERC721 contract address to mint NFTs from and bind to iNFTs created
	 */
	address public immutable nftContract;

	/**
	 * @dev OpenSea Proxy Registry determines which address is allowed to mint
	 *      an option at any given time
	 * @dev OpenSea takes care to set it to the NFT buyer address when they buy an option
	 */
	address public immutable proxyRegistry;

	/**
	 * @dev Number of options the factory supports,
	 *      options start from zero and end at `options` (exclusive)
	 */
	uint32 private options;

	/**
	 * @dev Base URI is used to construct option URI as
	 *      `base URI + option ID`
	 *
	 * @dev For example, if base URI is https://api.com/option/, then option #1
	 *      will have an URI https://api.com/option/1
	 */
	string public baseURI = "";

	/**
	 * @dev Initialized with the tokenId each optionId should start minting from,
	 *      incremented each time the option is minted
	 *
	 * @dev For each option, [currentTokenId[optionId], tokenIdUpperBound[optionId])
	 *      is the range of token IDs left to be minted
	 *
	 * @dev Maps optionId => next available (current) token ID for an option
	 */
	mapping(uint256 => uint256) public currentTokenId;

	/**
	 * @dev At what tokenId each optionId should end minting at (exclusive)
	 *
	 * @dev For each option, [currentTokenId[optionId], tokenIdUpperBound[optionId])
	 *      is the range of token IDs left to be minted
	 *
	 * @dev Maps optionId => final token ID (exclusive) for an option
	 */
	mapping(uint256 => uint256) public tokenIdUpperBound;

	/**
	 * @notice Minter is responsible for creating (minting) iNFTs
	 *
	 * @dev Role ROLE_MINTER allows minting iNFTs (calling `mint` function)
	 */
	uint32 public constant ROLE_MINTER = 0x0001_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      which is used to construct URIs for each option
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0010_0000;

	/**
	 * @notice OpenSea manager is responsible for registering the factory
	 *      in OpenSea via "Transfer" event mechanism
	 *
	 * @dev Role ROLE_OS_MANAGER allows notifying OpenSea about the contract
	 *      "owner" change via emitting "Transfer" events read by the OpenSea
	 *      (executing `fireTransferEvents` function)
	 */
	uint32 public constant ROLE_OS_MANAGER = 0x0040_0000;

	/**
	 * @dev Fired in mint() when Alethea NFT is created
	 *
	 * @param _by an address which executed the mint function
	 * @param _optionId OpenSea option ID
	 * @param _to an address NFT was minted to
	 */
	event Minted(address indexed _by, uint256 _optionId, address indexed _to);

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string _oldVal, string _newVal);

	/**
	 * @dev An event caught by the OpenSea for automatic factory registration
	 *      and assigning option "owner" to `to` address defined in the event
	 * @dev See: OpenSea docs and source code examples,
	 *      https://docs.opensea.io/docs/2-custom-sale-contract-viewing-your-sale-assets-on-opensea
	 */
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	/**
	 * @dev Creates/deploys the factory and binds it to NFT smart contract on construction
	 *
	 * @param _nft deployed NFT smart contract address; factory will mint NFTs of that type
	 * @param _proxyRegistry OpenSea proxy registry address
	 * @param _rangeBounds token ID ranges foreach option - the initial `currentTokenId` and `tokenIdUpperBound`
	 */
	constructor(address _nft, address _proxyRegistry, uint32[] memory _rangeBounds) {
		// verify the inputs are set
		require(_nft != address(0), "NFT contract is not set");
		require(_proxyRegistry != address(0), "OpenSea proxy registry is not set");

		// ensure there is at least one option (2 numbers for 1 range)
		require(_rangeBounds.length > 1, "invalid number of options");

		// verify range bound initial element is greater than 100
		require(_rangeBounds[0] > 100, "invalid range bound initial element");

		// verify inputs are valid smart contracts of the expected interfaces
		require(ERC165(_nft).supportsInterface(type(ERC721).interfaceId), "unexpected NFT type");
		require(ERC165(_nft).supportsInterface(type(ERC721Metadata).interfaceId), "unexpected NFT type");
		require(ERC165(_nft).supportsInterface(type(MintableERC721).interfaceId), "unexpected NFT type");

		// verify that range bounds elements increase (monotonically increasing)
		for(uint256 i = 0; i < _rangeBounds.length - 1; i++) {
			// compare current element and next element
			require(_rangeBounds[i] < _rangeBounds[i + 1], "invalid range bounds");
		}

		// assign the NFT address
		nftContract = _nft;
		// assign owner
		owner = msg.sender;
		// assign OpenSea Proxy Registry address
		proxyRegistry = _proxyRegistry;
		// number of options is derived from the range bounds array
		options = uint32(_rangeBounds.length - 1);

		// assign the appropriate start and upper bound for each optionId
		for(uint256 i = 0; i < _rangeBounds.length - 1; i++) {
			currentTokenId[i] = _rangeBounds[i];
			tokenIdUpperBound[i] = _rangeBounds[i + 1];
		}

		// fire events for each option
		fireTransferEvents(address(0), msg.sender);
	}

	/**
	 * @dev Restricted access function which updates base URI for optionIds
	 *
	 * @param _baseURI new base URI to set
	 */
	function setBaseURI(string memory _baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, _baseURI);

		// and update base URI
		baseURI = _baseURI;
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
		// reconstruct from current interface and super interface
		return interfaceId == type(OpenSeaFactoryERC721).interfaceId;
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function name() public override view returns (string memory) {
		// delegate to super implementation
		return ERC721Metadata(nftContract).name();
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function symbol() public override view returns (string memory) {
		// delegate to super implementation
		return ERC721Metadata(nftContract).symbol();
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function numOptions() public override view returns (uint256) {
		// calculate based on 0-indexed options
		return options;
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function canMint(uint256 _optionId) public override view returns (bool) {
		// check valid optionId, bounds
		return _optionId < options && currentTokenId[_optionId] < tokenIdUpperBound[_optionId];
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function tokenURI(uint256 _optionId) public override view returns (string memory) {
		// concatenate base URI + token ID
		return StringUtils.concat(baseURI, StringUtils.itoa(_optionId, 10));
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function supportsFactoryInterface() public override pure returns (bool) {
		// use ERC165 supportsInterface to return `true`
		return supportsInterface(type(OpenSeaFactoryERC721).interfaceId);
	}

	/**
	 * @inheritdoc OpenSeaFactoryERC721
	 */
	function mint(uint256 _optionId, address _toAddress) public override {
		// verify the access permission
		require(address(ProxyRegistry(proxyRegistry).proxies(owner)) == msg.sender, "access denied");

		// verify option ID can be minted
		require(canMint(_optionId), "cannot mint");

		// do the mint
		MintableERC721(nftContract).mint(_toAddress, currentTokenId[_optionId]);

		// emit an event before increasing
		emit Minted(msg.sender, currentTokenId[_optionId], _toAddress);

		// increment next tokenId
		currentTokenId[_optionId]++;
	}

	/**
	 * @dev Fires transfer events for each option. Used to change contract "owner"
	 *      See: OpenSea docs and source code examples,
	 *      https://docs.opensea.io/docs/2-custom-sale-contract-viewing-your-sale-assets-on-opensea
	 *
	 * @param _from transfer optionIds from
	 * @param _to transfer optionIds to
	 */
	function fireTransferEvents(address _from, address _to) public {
		// verify the access permission
		require(isSenderInRole(ROLE_OS_MANAGER), "access denied");

		// fire events for each option
		for (uint256 i = 0; i < options; i++) {
			emit Transfer(_from, _to, i);
		}
	}

	/**
	 * Hack to get things to work automatically on OpenSea.
	 * Use transferFrom so the frontend doesn't have to worry about different method names.
	 */
	function transferFrom(address _from, address _to, uint256 _tokenId) public {
		// simply delegate to `mint`
		mint(_tokenId, _to);
	}

	/**
	 * Hack to get things to work automatically on OpenSea.
	 * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
	 */
	function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
		// true if called by contract "owner" which is the token owner itself
		if(owner == _owner && _owner == _operator) {
			return true;
		}

		// lookup the registry
		return owner == _owner && address(ProxyRegistry(proxyRegistry).proxies(_owner)) == _operator;
	}

	/**
	 * Hack to get things to work automatically on OpenSea.
	 * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
	 */
	function ownerOf(uint256 _tokenId) public view returns (address _owner) {
		// return smart contract "owner"
		return owner;
	}
}
