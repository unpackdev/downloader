//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";

/**
 * @title Delegate Proxy
 * @notice delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract OwnableDelegateProxy {

}

/**
 * @title Proxy Registry
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
contract W3lockEAPOwnersClub is ERC721, Ownable, Pausable {
	/**
	 * Libraries
	 */
	using Counters for Counters.Counter;

	/**
	 * Events
	 */
	event Withdraw(address indexed operator);
	event SetBaseTokenURI(string baseTokenURI);
	event SetContractURI(string contractURI);
	event SetProxyRegistryAddress(address indexed proxyRegistryAddress);
	event SetMinterAddress(address indexed minterAddress);

	/**
	 * Public Variables
	 */
	address public minterAddress;
	address public proxyRegistryAddress;
	string public baseTokenURI;
	string public contractURI;
	mapping(uint256 => uint256) public batchNumberOf;

	/**
	 * Private Variables
	 */
	Counters.Counter private _totalSupply;

	/**
	 * Constructor
	 * @notice Owner address will be automatically set to deployer address in the parent contract (Ownable)
	 * @param _baseTokenURI - base uri to be set as a initial baseTokenURI
	 * @param _contractURI - base contract uri to be set as a initial contractURI
	 * @param _proxyRegistryAddress - proxy address to be set as a initial proxyRegistryAddress
	 */
	constructor(
		string memory _baseTokenURI,
		string memory _contractURI,
		address _proxyRegistryAddress
	) ERC721("W3lockEAPOwnersClub", "W3LEOC") {
		baseTokenURI = _baseTokenURI;
		contractURI = _contractURI;
		proxyRegistryAddress = _proxyRegistryAddress;

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
	 * @notice Set contractURI
	 * @dev onlyOwner
	 * @param _contractURI - URI to be set as a new contractURI
	 */
	function setContractURI(string memory _contractURI) external onlyOwner {
		contractURI = _contractURI;
		emit SetContractURI(_contractURI);
	}

	/**
	 * @notice Set baseTokenURI for this contract
	 * @dev onlyOwner
	 * @param _baseTokenURI - URI to be set as a new baseTokenURI
	 */
	function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
		baseTokenURI = _baseTokenURI;
		emit SetBaseTokenURI(_baseTokenURI);
	}

	/**
	 * @notice Register proxy registry address
	 * @dev onlyOwner
	 * @param _proxyRegistryAddress - address to be set as a new proxyRegistryAddress
	 */
	function setProxyRegistryAddress(address _proxyRegistryAddress)
		external
		onlyOwner
	{
		proxyRegistryAddress = _proxyRegistryAddress;
		emit SetProxyRegistryAddress(_proxyRegistryAddress);
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
	 * @param _minterAddress - address to be set as a new minterAddress
	 */
	function setMinterAddress(address _minterAddress) external onlyOwner {
		minterAddress = _minterAddress;
		emit SetMinterAddress(_minterAddress);
	}

	/**
	 * @notice Pause this contract
	 * @dev onlyOwner
	 */
	function pause() external onlyOwner {
		_pause();
	}

	/**
	 * @notice Unpause this contract
	 * @dev onlyOwner
	 */
	function unpause() external onlyOwner {
		_unpause();
	}

	/**
	 * @notice Return totalSupply
	 * @return uint256
	 */
	function totalSupply() public view returns (uint256) {
		return _totalSupply.current() - 1;
	}

	/**
	 * @notice Return bool if the token exists
	 * @param _tokenId - tokenId to be check if exists
	 * @return bool
	 */
	function exists(uint256 _tokenId) public view returns (bool) {
		return _exists(_tokenId);
	}

	/**
	 * @notice Mint token to the beneficiary
	 * @dev onlyMinterOrOwner, whenNotPaused
	 * @param _tokenId - tokenId
	 * @param _batchNumber - batch number
	 * @param _beneficiary - address eligible to get the token for tokenId
	 */
	function mintTo(
		uint256 _tokenId,
		uint256 _batchNumber,
		address _beneficiary
	) public whenNotPaused {
		require(_msgSender() == minterAddress, "Only Minter");
		_safeMint(_beneficiary, _tokenId);
		_totalSupply.increment();
		batchNumberOf[_tokenId] = _batchNumber;
	}

	/**
	 * @notice Check if the owner approve the operator address
	 * @dev Override to allow proxy contracts for gas less approval
	 * @param _owner - owner address
	 * @param _operator - operator address
	 * @return bool
	 */
	function isApprovedForAll(address _owner, address _operator)
		public
		view
		override
		returns (bool)
	{
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(_owner)) == _operator) {
			return true;
		}

		return super.isApprovedForAll(_owner, _operator);
	}

	/**
	 * @notice See {ERC721-_baseURI}
	 * @dev Override to return baseTokenURI set by the owner
	 * @return string memory
	 */
	function _baseURI() internal view override returns (string memory) {
		return baseTokenURI;
	}

	/**
	 * @notice See {ERC721-_beforeTokenTransfer}
	 * @dev Override to check paused status
	 * @param _from - address which wants to transfer the token by tokenId
	 * @param _to - address eligible to get the token
	 * @param _tokenId - tokenId
	 */
	function _beforeTokenTransfer(
		address _from,
		address _to,
		uint256 _tokenId
	) internal virtual override {
		super._beforeTokenTransfer(_from, _to, _tokenId);
		require(!paused(), "ERC721Pausable: token transfer while paused");
	}
}
