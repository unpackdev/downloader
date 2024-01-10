//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**
 * @title Delegate Proxy
 * @notice delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract OwnableDelegateProxy {

}

/**
 * @title Proxy Registory
 * @notice map address to the delegate proxy
 */
contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @author a42
 * @title W3lockEAPOwnersClub
 * @notice ERC721 contract
 */
contract W3lockEAPOwnersClub is ERC721, Ownable {
	/**
	 * Libraries
	 */
	using Counters for Counters.Counter;

	/**
	 * Events
	 */
	event Withdraw(address indexed operator);
	event SetBaseURI(string baseURI);
	event SetContractURI(string contractURI);
	event SetProxyAddress(address indexed proxyAddress);
	event SetMinterAddress(address indexed proxyAddress);

	/**
	 * Public Variables
	 */
	address public minterAddress;
	address public proxyRegistryAddress;
	string public baseURI;
	mapping(uint256 => uint256) public batchNumberOf;

	/**
	 * Private Variables
	 */
	Counters.Counter private _totalSupply;
	string private _contractURI;

	/**
	 * Constructor
	 * @notice Owner address will be automatically set to deployer address in the parent contract (Ownable)
	 * @param _baseUri - base uri to be set as a initial baseURI
	 * @param _baseContractUri - base contract uri to be set as a initial _contractURI
	 * @param _proxyAddress - proxy address to be set as a initial proxyRegistryAddress
	 */
	constructor(
		string memory _baseUri,
		string memory _baseContractUri,
		address _proxyAddress
	) ERC721("W3lockEAPOwnersClub", "W3LEOC") {
		baseURI = _baseUri;
		_contractURI = _baseContractUri;
		proxyRegistryAddress = _proxyAddress;

		// _totalSupply is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
		_totalSupply.increment();
	}

	/**
	 * Receive function
	 */
	receive() external payable {}

	/**
	 * Fallback function
	 */
	fallback() external payable {}

	/**
	 * @notice update contractUri
	 * @param contractUri - contract uri to be set as a new _contractURI
	 */
	function setContractURI(string memory contractUri) external onlyOwner {
		_contractURI = contractUri;
		emit SetContractURI(contractUri);
	}

	/**
	 * @notice Set base uri for this contract
	 * @dev onlyOwner
	 * @param baseUri - string to be set as a new baseURI
	 */
	function setBaseURI(string memory baseUri) external onlyOwner {
		baseURI = baseUri;
		emit SetBaseURI(baseUri);
	}

	/**
	 * @notice Register proxy registry address
	 * @dev onlyOwner
	 * @param newAddress - address to be set as a new proxyRegistryAddress
	 */
	function setRegistryAddress(address newAddress) external onlyOwner {
		proxyRegistryAddress = newAddress;
		emit SetProxyAddress(newAddress);
	}

	/**
	 * @notice Transfer balance in contract to the owner address
	 * @dev onlyOwner
	 */
	function withdraw() external onlyOwner {
		require(address(this).balance > 0, "Not Enough Balance Of Contract");
		(bool success, ) = owner().call{ value: address(this).balance }("");
		require(success, "Transfer Failed");
		emit Withdraw(msg.sender);
	}

	/**
	 * @notice Register minterAddress address
	 * @dev onlyOwner
	 * @param newAddress - address to be set as a new minterAddress
	 */
	function setMinterAddress(address newAddress) external onlyOwner {
		minterAddress = newAddress;
		emit SetMinterAddress(newAddress);
	}

	/**
	 * @notice Return totalSuply
	 * @return uint256
	 */
	function totalSupply() public view returns (uint256) {
		return _totalSupply.current() - 1;
	}

	/**
	 * @notice Return bool if the token exists
	 * @param tokenId - tokenId to be check if exists
	 * @return bool
	 */
	function exists(uint256 tokenId) public view returns (bool) {
		return _exists(tokenId);
	}

	/**
	 * @notice Return contract uri
	 * @dev OpenSea implementation
	 * @return string memory
	 */
	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	/**
	 * @notice Return base uri
	 * @dev OpenSea implementation
	 * @return string memory
	 */
	function baseTokenURI() public view returns (string memory) {
		return baseURI;
	}

	/**
	 * @notice Mint token to the beneficiary
	 * @dev onlyMinterOrOwner
	 * @param tokenId - tokenId
	 * @param batchNumber - batch number
	 * @param beneficiary - address eligible to get the token for tokenId
	 */
	function mintTo(
		uint256 tokenId,
		uint256 batchNumber,
		address beneficiary
	) public {
		require(_msgSender() == minterAddress, "Only Minter");
		_safeMint(beneficiary, tokenId);
		_totalSupply.increment();
		batchNumberOf[tokenId] = batchNumber;
	}

	/**
	 * @notice Check if the owner approve the operator address
	 * @dev Override to allow proxy contracts for gas less approval
	 * @param owner - owner address
	 * @param operator - operator address
	 * @return bool
	 */
	function isApprovedForAll(address owner, address operator)
		public
		view
		override
		returns (bool)
	{
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}

		return super.isApprovedForAll(owner, operator);
	}

	/**
	 * @notice See {ERC721-_baseURI}
	 * @dev Override to return baseURI set by the owner
	 * @return string memory
	 */
	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}
}
