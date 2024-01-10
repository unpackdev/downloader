//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./IW3lockEAPOwnersClub.sol";

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
 * @title Bertram
 * @notice ERC721 contract that allows users to trade assets, and has minting, burning, pausing, permitting functionalities
 */
contract W3lockEAPTicket is ERC721, Ownable, Pausable {
	/**
	 * Libraries
	 */
	using Counters for Counters.Counter;

	/**
	 * Events
	 */
	event Withdraw(address indexed operator);
	event SetFee(uint256 fee);
	event SetCap(uint256 cap);
	event IncrementBatch(uint256 batch);
	event SetBaseURI(string baseURI);
	event SetContractURI(string contractURI);
	event SetProxyAddress(address indexed proxyAddress);
	event SetOwnersNFTAddress(address indexed ownersNFTAddress);

	/**
	 * Public Variables
	 */
	uint256 public cap;
	uint256 public fee;
	address public proxyRegistryAddress;
	string public baseURI;
	mapping(uint256 => uint256) public batchNumberOf;

	/**
	 * Private Variables
	 */
	Counters.Counter private _nextTokenId;
	Counters.Counter private _nextBatch;
	Counters.Counter private _totalSupply;
	string private _contractURI;
	IW3lockEAPOwnersClub private ownersClub;

	/**
	 * Modifiers
	 */
	modifier onlyTokenOwner(uint256 tokenId) {
		require(ownerOf(tokenId) == _msgSender(), "Only Token Owner");
		_;
	}

	/**
	 * Constructor
	 * @notice Owner address will be automatically set to deployer address in the parent contract (Ownable)
	 * @param _baseUri - base uri to be set as a initial baseURI
	 * @param _baseContractUri - base contract uri to be set as a initial _contractURI
	 * @param _proxyAddress - proxy address to be set as a initial proxyRegistryAddress
	 * @param _ownersNFTAddress - owners nft contract address to be set as a initial ownersClub
	 */
	constructor(
		string memory _baseUri,
		string memory _baseContractUri,
		address _proxyAddress,
		address _ownersNFTAddress
	) ERC721("W3lockEAPTicket", "W3LET") {
		baseURI = _baseUri;
		_contractURI = _baseContractUri;
		proxyRegistryAddress = _proxyAddress;
		ownersClub = IW3lockEAPOwnersClub(_ownersNFTAddress);

		// nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
		_nextTokenId.increment();
		_nextBatch.increment();
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
	 * @notice Set new supply cap
	 * @dev onlyOwer
	 * @param newCap - new supply cap
	 */
	function setCap(uint256 newCap) external onlyOwner {
		cap = newCap;
		emit SetCap(newCap);
	}

	/**
	 * @notice Set new fee
	 * @dev onlyOwner
	 * @param newFee - new fee
	 */
	function setFee(uint256 newFee) external onlyOwner {
		fee = newFee;
		emit SetFee(newFee);
	}

	/**
	 * @notice Set new Owners NFT contract address
	 * @dev onlyOwner
	 */
	function setOwnersNFTAddress(address newAddress) external onlyOwner {
		ownersClub = IW3lockEAPOwnersClub(newAddress);
		emit SetOwnersNFTAddress(newAddress);
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
	 * @notice Register proxy registry address
	 * @dev onlyOwner
	 * @param newAddress - address to be set as a new proxyRegistryAddress
	 */
	function setRegistryAddress(address newAddress) external onlyOwner {
		proxyRegistryAddress = newAddress;
		emit SetProxyAddress(newAddress);
	}

	/**
	 * @notice increment batch
	 * @dev onlyOwner
	 */
	function incrementBatch() external onlyOwner {
		_nextBatch.increment();
		emit IncrementBatch(_nextBatch.current());
	}

	/**
	 * @notice Return totalSuply
	 * @return uint256
	 */
	function totalSupply() public view returns (uint256) {
		return _totalSupply.current() - 1;
	}

	/**
	 * @notice Return total minted count
	 * @return uint256
	 */
	function totalMinted() public view returns (uint256) {
		return _nextTokenId.current() - 1;
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
	 * @notice Return current batch
	 */
	function batchNumber() public view returns (uint256) {
		return _nextBatch.current();
	}

	/**
	 * @notice Mint token afeter verifying tokenId and signature
	 * @dev whenNotPaused
	 */
	function mint() public payable whenNotPaused {
		mintTo(_msgSender());
	}

	/**
	 * @notice Mint token to the beneficiary afeter verifying tokenId and signature
	 * @dev whenNotPaused
	 * @param beneficiary - address eligible to get the token for tokenId
	 */
	function mintTo(address beneficiary) public payable whenNotPaused {
		require(msg.value >= fee, "Insufficient Fee");
		require(totalSupply() < cap, "Capped");

		uint256 tokenId = _nextTokenId.current();
		_safeMint(beneficiary, tokenId);

		_nextTokenId.increment();
		_totalSupply.increment();
		batchNumberOf[tokenId] = batchNumber();
	}

	/**
	 * @notice Burn token and mint owners nft to the msg sender
	 * @dev onlyTokenOwner, whenNotPaused
	 * @param tokenId - tokenId
	 */
	function burn(uint256 tokenId)
		public
		onlyTokenOwner(tokenId)
		whenNotPaused
	{
		uint256 tokenBatchNumber = batchNumberOf[tokenId];
		_burn(tokenId);
		ownersClub.mintTo(tokenId, tokenBatchNumber, _msgSender());
		delete batchNumberOf[tokenId];
		_totalSupply.decrement();
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
	 * @notice See {ERC721-_beforeTokenTransfer}
	 * @dev Override to check paused status
	 * @param from - address which want to transfer the token by tokenId
	 * @param to - address eligible to get the token
	 * @param tokenId - tokenId
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);
		require(!paused(), "ERC721Pausable: token transfer while paused");
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
