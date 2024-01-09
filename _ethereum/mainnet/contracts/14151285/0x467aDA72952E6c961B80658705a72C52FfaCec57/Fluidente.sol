//SPDX-License-Identifier: MIT


/**
 ______ _       _     _            _       
|  ____| |     (_)   | |          | |      
| |__  | |_   _ _  __| | ___ _ __ | |_ ___ 
|  __| | | | | | |/ _` |/ _ \ '_ \| __/ _ \
| |    | | |_| | | (_| |  __/ | | | ||  __/
|_|    |_|\__,_|_|\__,_|\___|_| |_|\__\___|

by: artofsoul.eth
**/

pragma solidity ^0.8.7;
import "./ERC721B.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";


///@notice FluidenteNFT
///@author iqbalsyamil.eth (github.com/2pai)
contract Fluidente is ERC721B, ERC2981, EIP712, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant PRESALE_PRICE = 0.06 ether;
    uint256 public constant PUBLIC_PRICE = 0.1 ether;
    uint256 public constant LIMIT_MINT = 3;
    uint256 public constant MAX_SUPPLY = 570;
    uint256 public stage; // 1 for presale, 2 for public sale.


    string public baseURI;
    string private previewBaseURI;
    address public signerGroupB;
    address public signerGroupA;

    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;

    bytes32 public constant MINTER_TYPEHASH =
        keccak256("Minter(address recipient,uint256 amount)"); 

    string private constant SIGNING_DOMAIN = "FluidenteNFT";
    string private constant SIGNATURE_VERSION = "1";

    event PresaleMint(address indexed minter, uint256 amount);
    event PublicMint(address indexed minter, uint256 amount);
    
    mapping(address => uint256) public publicMinter;
    mapping(address => uint256) public minterGroupB;
    mapping(address => bool) public minterGroupA;

    constructor(address _signerGroupA, address _signerGroupB, address _royaltyAddress, uint256 _amountRoyalty, address _openSeaProxyRegistryAddress) 
        ERC721B("Fluidente", "FDT")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        previewBaseURI = "ipfs://QmPu5Mao6fMDvxkngcxG7zC8WSJaJVkBtsnKCxSDgT8nnK/";
        stage = 1;
        signerGroupA = _signerGroupA;
        signerGroupB = _signerGroupB;
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress; 
        _setRoyalties(_royaltyAddress, _amountRoyalty);
    }

        
    /// @notice Mint NFT at presale period (only for whitelisted user)  
    /// @param _amount amount of NFT to be minted
    /// @param _signature EIP-712 signature (for whitelisting purpose)
    function mintGroupB(uint256 _amount, bytes calldata _signature) external payable {
        require(stage == 1, "PRESALE_DISABLED");
        require(signerGroupB == _verify(_msgSender(), LIMIT_MINT, _signature), "INVALID_SIGNER");
        require(minterGroupB[msg.sender] + _amount <= LIMIT_MINT, "LIMIT_EXCEEDED");
        require(PRESALE_PRICE * _amount <= msg.value, "INSUFFICIENT_FUNDS"); 

        uint256 tokenId = _owners.length;

        require(
            (totalSupply() + _amount) <= MAX_SUPPLY,
            "MAX_TOKEN_EXCEED"
        );

        minterGroupB[msg.sender] += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            _mint(_msgSender(), tokenId++);
        }

        emit PresaleMint(msg.sender, _amount);
    }

    
    /// @notice Mint NFT for public user 
    /// @param _amount amount of NFT to be minted
    function mint(uint256 _amount) external payable {
        require(stage == 2, "SALE_DISABLED");
        
        require(publicMinter[msg.sender] + _amount <= LIMIT_MINT, "LIMIT_EXCEED");
        require((PUBLIC_PRICE * _amount) <= msg.value, "INSUFFICIENT_FUNDS");
        
        uint256 tokenId = _owners.length;

        require(
            (totalSupply() + _amount) <= MAX_SUPPLY,
            "MAX_TOKEN_EXCEED"
        );
        
        publicMinter[msg.sender] += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            _mint(msg.sender, tokenId++);
        }

        emit PublicMint(msg.sender, _amount);
    }

    /// @notice Mint NFT at presale period (only for whitelisted user)
    /// @param _signature EIP-712 signature (for whitelisting purpose)
    function mintGroupA(bytes calldata _signature) external {
        require(stage == 1, "PRESALE_DISABLED"); 
        require(signerGroupA == _verify(_msgSender(), 1, _signature), "INVALID_SIGNER"); 
        require(!minterGroupA[msg.sender], "LIMIT_EXCEEDED");
        
        uint256 tokenId = _owners.length;

        require(
            (totalSupply() + 1) <= MAX_SUPPLY,
            "MAX_TOKEN_EXCEED"
        );

        minterGroupA[msg.sender] = true;
        _mint(_msgSender(), tokenId++);

        emit PresaleMint(msg.sender, 1);
    }

    function gift(address _to, uint256 _amount) external onlyOwner {
        uint256 tokenId = _owners.length;
        require(
            (totalSupply() + _amount) <= MAX_SUPPLY,
            "MAX_TOKEN_EXCEED"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _mint(_to, tokenId++);
        }
    }

    /// @notice Set base URI for the NFT.  
    /// @param _uri IPFS URI
    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    /// @notice Set stage  
    /// @param _stage current stage(0 = minting phase ended, 1 = presale, 2 = public)
    function setStage(uint256 _stage) external onlyOwner {
        stage = _stage;
    }

    function setSignerGroupA(address _signer) external onlyOwner {
        signerGroupA = _signer;
    }

    function setSignerGroupB(address _signer) external onlyOwner {
        signerGroupB = _signer;
    }

    /// @dev Disable gasless listing for opensea in case security issue
    /// @param _isOpenSeaProxyActive gasless listing status
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive) external onlyOwner{
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    /// @dev change open sea address proxy in case security issue
    /// @param _addressOpenSeaProxy opensea proxy address
    function setOpenSeaProxyRegistryAddress(address _addressOpenSeaProxy) external onlyOwner{
        openSeaProxyRegistryAddress = _addressOpenSeaProxy;
    }

    /// @notice Allows to set the royalties on the contract
    /// @dev This function in a real contract should be protected with a onlyOwner (or equivalent) modifier
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public onlyOwner{
        _setRoyalties(recipient, value);
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "BALANCE_ZERO");
        payable(owner()).transfer(address(this).balance);
    }

    function totalSupply() public view returns (uint256) {
        return _owners.length;
    }

    function getChainID() public view returns(uint){
        return block.chainid;
    }

    function _verify(address _recipient, uint256 _amountLimit, bytes calldata _sign)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(MINTER_TYPEHASH, _recipient, _amountLimit))
        );
        return ECDSA.recover(digest, _sign);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721B, ERC165)
        returns (bool)
    {
    return
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId);
    }


    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_id), "Token does not exist");

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : previewBaseURI;
    }
    
}

// REFERENCE from cryptoCoven
// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}