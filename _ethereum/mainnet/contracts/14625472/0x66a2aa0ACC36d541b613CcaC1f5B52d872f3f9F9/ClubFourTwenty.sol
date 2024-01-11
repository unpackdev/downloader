//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721Royalty.sol";
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
 * @title ClubFourTwenty NFT
 * @notice ERC721 contract
 */
contract ClubFourTwenty is ERC721Royalty, Ownable {
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
    event SetFee(uint256 fee);
    event SetDefaultRoyalty(address indexed receiver, uint96 feeNumerator);
    event SetTokenRoyalty(
        uint256 tokenId,
        address indexed receiver,
        uint96 feeNumerator
    );

    /**
     * Public Variables
     */
    uint256 public MAX_SUPPLY = 420;
    uint256 public fee;
    address public proxyRegistryAddress;
    string public baseTokenURI;
    string public contractURI;

    /**
     * Private Variables
     */
    Counters.Counter private _totalSupply;

    /**
     * Constructor
     * @notice Owner address will be automatically set to deployer address in the parent contract (Ownable)
     * @param _baseTokenURI - base uri to be set as a initial baseURI
     * @param _contractURI - base contract uri to be set as a initial _contractURI
     * @param _proxyRegistryAddress - proxy address to be set as a initial proxyRegistryAddress
     */
    constructor(
        string memory _baseTokenURI,
        string memory _contractURI,
        address _proxyRegistryAddress
    ) ERC721("420Club", "420") {
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
     * @notice update contractURI
     * @param _contractURI - contract uri to be set as a new contractURI
     */
    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
        emit SetContractURI(contractURI);
    }

    /**
     * @notice Set base token uri for this contract
     * @dev onlyOwner
     * @param _baseTokenURI - string to be set as a new baseTokenURI
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
     * @notice Set fee
     * @dev onlyOwner
     * @param _fee - fee to be set as a new fee
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit SetFee(_fee);
    }

    /**
     * @notice Set Defualt Royalty
     * @dev onlyOwner
     * @param _receiver - address, cannot be the zero address
     * @param _feeNumerator - fee numerator, can not be greater then 10000
     */
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
        emit SetDefaultRoyalty(_receiver, _feeNumerator);
    }

    /**
     * @notice Sets the royalty information for a specific token id, overriding the global default.
     * @dev onlyOwner
     * @param _tokenId - tokenId, must be already minted.
     * @param _receiver - address, cannot be the zero address
     * @param _feeNumerator - cannot be greater than 10000
     */
    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
        emit SetTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /**
     * @notice Transfer balance in contract to the owner address
     * @dev onlyOwner
     */
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Not Enough Balance Of Contract");
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer Failed");
        emit Withdraw(msg.sender);
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
     * @notice Mint token to msg.sender
     */
    function mint() public payable {
        mintTo(_msgSender());
    }

    /**
     * @notice Mint token to the beneficiary
     * @param _beneficiary - address eligible to get the token
     */
    function mintTo(address _beneficiary) public payable {
        require(msg.value >= fee, "Insufficient Fee");
        require(totalSupply() < MAX_SUPPLY, "Max Supply");
        uint256 tokenId = _totalSupply.current();
        _safeMint(_beneficiary, tokenId);
        _totalSupply.increment();
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
        // Whitelist OpenSea proxy contract for easy trading.
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
}
