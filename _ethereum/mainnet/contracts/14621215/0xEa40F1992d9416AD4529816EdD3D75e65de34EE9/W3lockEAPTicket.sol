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
 * @title Proxy Registry
 * @notice map address to the delegate proxy
 */
contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @author a42
 * @title W3lockEAPTicket
 * @notice ERC721 contract
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
	event SetBaseTokenURI(string baseTokenURI);
	event SetContractURI(string contractURI);
	event SetProxyRegistryAddress(address indexed proxyRegistryAddress);
	event SetOwnersClubNFTAddress(address indexed ownersClubNFTAddress);
	event Burn(address indexed from, uint256 tokenId);
	event SetIsMintingRestricted(bool isRestricted);

	/**
	 * Public Variables
	 */
	address public proxyRegistryAddress;
	bool public isMintingRestricted;
	string public baseTokenURI;
	string public contractURI;
	uint256 public cap;
	uint256 public fee;
	mapping(uint256 => uint256) public batchNumberOf;

	/**
	 * Private Variables
	 */
	Counters.Counter private _nextTokenId;
	Counters.Counter private _nextBatch;
	Counters.Counter private _totalSupply;
	IW3lockEAPOwnersClub private ownersClub;

	/**
	 * Modifiers
	 */
	modifier onlyTokenOwner(uint256 _tokenId) {
		require(ownerOf(_tokenId) == _msgSender(), "Only Token Owner");
		_;
	}
	modifier whenMintingNotRestricted() {
		if (isMintingRestricted)
			require(_msgSender() == owner(), "Only Owner Mint Allowed");
		_;
	}

	/**
	 * Constructor
	 * @notice Owner address will be automatically set to deployer address in the parent contract (Ownable)
	 * @param _baseTokenURI - base uri to be set as a initial baseTokenURI
	 * @param _contractURI - base contract uri to be set as a initial contractURI
	 * @param _proxyRegistryAddress - proxy address to be set as a initial proxyRegistryAddress
	 * @param _ownersClubNFTAddress - owners club contract address to be set as a initial ownersClub
	 */
	constructor(
		string memory _baseTokenURI,
		string memory _contractURI,
		address _proxyRegistryAddress,
		address _ownersClubNFTAddress
	) ERC721("W3lockEAPTicket", "W3LET") {
		baseTokenURI = _baseTokenURI;
		contractURI = _contractURI;
		proxyRegistryAddress = _proxyRegistryAddress;
		ownersClub = IW3lockEAPOwnersClub(_ownersClubNFTAddress);

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
	 * @notice Set new supply cap
	 * @dev onlyOwer
	 * @param _cap - new supply cap
	 */
	function setCap(uint256 _cap) external onlyOwner {
		cap = _cap;
		emit SetCap(_cap);
	}

	/**
	 * @notice Set fee
	 * @dev onlyOwner
	 * @param _fee - fee to be set as a new fee
	 */
	function setFee(uint256 _fee) external onlyOwner {
		fee = _fee;
		emit SetFee(_fee);
	}

	/**
	 * @notice Set new Owners Club NFT contract address
	 * @dev onlyOwner
	 */
	function setOwnersClubNFTAddress(address _ownersClubNFTAddress)
		external
		onlyOwner
	{
		ownersClub = IW3lockEAPOwnersClub(_ownersClubNFTAddress);
		emit SetOwnersClubNFTAddress(_ownersClubNFTAddress);
	}

	/**
	 * @notice Set isMintingRestricted flag
	 * @dev onlyOwner
	 * @param _isRestricted - boolean value to be set as minting restriction mode
	 */
	function setIsMintingRestricted(bool _isRestricted) external onlyOwner {
		isMintingRestricted = _isRestricted;
		emit SetIsMintingRestricted(_isRestricted);
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
	 * @notice Return total minted count
	 * @return uint256
	 */
	function totalMinted() public view returns (uint256) {
		return _nextTokenId.current() - 1;
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
	 * @notice Return current batch
	 * @return uint256
	 */
	function batchNumber() public view returns (uint256) {
		return _nextBatch.current();
	}

	/**
	 * @notice Mint token
	 * @dev whenNotPaused, onlyOwnerMintAllowed
	 */
	function mint() public payable whenNotPaused whenMintingNotRestricted {
		mintTo(_msgSender());
	}

	/**
	 * @notice Mint token to the beneficiary
	 * @dev  whenNotPaused, onlyOwnerMintAllowed
	 * @param _beneficiary - address eligible to get the token
	 */
	function mintTo(address _beneficiary)
		public
		payable
		whenNotPaused
		whenMintingNotRestricted
	{
		require(msg.value >= fee, "Insufficient Fee");
		require(totalMinted() < cap, "Capped");

		uint256 tokenId = _nextTokenId.current();

		_safeMint(_beneficiary, tokenId);

		_nextTokenId.increment();
		_totalSupply.increment();
		batchNumberOf[tokenId] = batchNumber();
	}

	/**
	 * @notice Burn token and mint owners nft to the msg sender
	 * @dev onlyTokenOwner, whenNotPaused
	 * @param _tokenId - tokenId
	 */
	function burn(uint256 _tokenId)
		public
		onlyTokenOwner(_tokenId)
		whenNotPaused
	{
		uint256 tokenBatchNumber = batchNumberOf[_tokenId];
		_burn(_tokenId);
		ownersClub.mintTo(_tokenId, tokenBatchNumber, _msgSender());
		delete batchNumberOf[_tokenId];
		_totalSupply.decrement();
		emit Burn(_msgSender(), _tokenId);
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

	/**
	 * @notice See {ERC721-_baseURI}
	 * @dev Override to return baseTokenURI set by the owner
	 * @return string memory
	 */
	function _baseURI() internal view override returns (string memory) {
		return baseTokenURI;
	}
}
