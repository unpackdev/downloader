// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";


abstract contract ContextMixin {
    function msgSender()
    internal
    view
    returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BinoGlyph is ERC721,Ownable,ContextMixin {

    using SafeMath for uint256;
    using Counters for Counters.Counter;


    uint256 public TOTAL_SUPPLY = 5555;
    uint256 public MAX_MINT_PER_TRANSACTION = 20;
    uint256 public MAX_MINT_PER_ADDRESS = 20;
    uint256 public MAX_MINT_PER_ADDRESS_PRESLAE = 5;
    uint256 public PRICE = 0.0625 ether;
    Counters.Counter private _nextTokenId;
    

    mapping(address => uint256) private PRE_SALE_MINT_BALANCE;
    mapping(address => uint256) private MINT_BALANCE;

    bool public PUBLIC_SALE_ACTIVE = false;
    bool public PRE_SALE_ACTIVE = false;
    
    string private BASE_URI = "https://api.binoglyph.com/token/";
    string private CONTRACT_URI = "https://api.binoglyph.com/contract";

    address proxyRegistryAddress;

    bytes32 MERKLE_ROOT;

    constructor(address _proxyRegistryAddress,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _nextTokenId.increment();
    }

    function set_merkle_root(bytes32 _MERKLE_ROOT) public onlyOwner {
        MERKLE_ROOT = _MERKLE_ROOT;
    }

    function verify_merkel_proof(bytes32[] calldata proof) internal view returns (bool){
        return MerkleProof.verify(proof,get_merkle_root(),keccak256(abi.encodePacked(_msgSender())));
    }

    function get_merkle_root() public view returns(bytes32){
        return MERKLE_ROOT;
    }

    function baseTokenURI()  public view returns (string memory) {
        return _baseURI();
    }

    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }


    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }
    
    function setBaseURI (string memory _BASE_URI) public onlyOwner {
        BASE_URI = _BASE_URI;
    }
    
    function setContractURI (string memory _CONTRACT_URI) public onlyOwner {
        CONTRACT_URI = _CONTRACT_URI;
    }
    
    function mint(uint256 amount)  payable public {
        require (amount + totalSupply() < TOTAL_SUPPLY,"Maximum number of mintable tokens has been reached.");
        require (PUBLIC_SALE_ACTIVE , "Public Sale is not active.");
        require (MINT_BALANCE[_msgSender()] <= MAX_MINT_PER_ADDRESS , "Maximum number of tokens per wallet has been reached.");
        require (amount <= MAX_MINT_PER_TRANSACTION , "The number of tokens selected exceeds the maximum allowed per transaction");
        require (PRICE.mul(amount) >= msg.value, "Invalid Price.");
        safeMint(amount,_msgSender());
    }
    
    
    function presaleMint(uint256 amount,bytes32[] calldata proof) payable public {
    
        require (amount + totalSupply() < TOTAL_SUPPLY,"Maximum number of mintable tokens has been reached.");
        require (PRE_SALE_ACTIVE , "Presale is not active.");
        require (verify_merkel_proof(proof),"You are not Whitelisted.");
        require (PRE_SALE_MINT_BALANCE[_msgSender()] + amount <= MAX_MINT_PER_ADDRESS_PRESLAE ,"Maximum number of tokens per wallet (presale) has been reached." );
        require (amount <= MAX_MINT_PER_TRANSACTION , "The number of tokens selected exceeds the maximum allowed per transaction.");
        require (PRICE.mul(amount) >= msg.value, "Invalid Price.");
        presaleSafeMint(amount,_msgSender());
    }
    
    function presaleSafeMint(uint256 amount,address _to_address) internal {
        for ( uint256 i= 0 ; i <  amount ; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            PRE_SALE_MINT_BALANCE[_to_address] += 1;
            _safeMint(address(_to_address),currentTokenId);
        }
    }
    
    function giftMint(uint256 amount, address _to_address) public {
        require (amount + totalSupply() < TOTAL_SUPPLY,"Maximum number of mintable tokens has been reached.");
        require (PUBLIC_SALE_ACTIVE , "Presale is not active.");
        require (amount <= MAX_MINT_PER_TRANSACTION , "The number of tokens selected exceeds the maximum allowed per transaction.");
        require (MINT_BALANCE[address(_to_address)]  + amount <= MAX_MINT_PER_ADDRESS ,"Maximum number of tokens per wallet has been reached.");
        safeMint(amount,_to_address);
    }

    function safeMint(uint256 amount,address _to_address) internal {
        for ( uint256 i= 0 ; i <  amount ; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            MINT_BALANCE[_to_address] += 1;
            _safeMint(address(_to_address),currentTokenId);
        }
    }

    function _msgSender()
    internal
    override
    view
    returns (address sender)
    {
        return ContextMixin.msgSender();
    }


    function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
    
    
    function togglePreSale() external onlyOwner {
        PRE_SALE_ACTIVE = !(PRE_SALE_ACTIVE);
    }
    
    function getPreSaleStatus() external view returns(bool) {
        return PRE_SALE_ACTIVE;
    }
    
    function getPublicSaleStatus() external view returns(bool) {
        return PUBLIC_SALE_ACTIVE;
    }
    
    function toggleSale() external onlyOwner{
        PUBLIC_SALE_ACTIVE = !(PUBLIC_SALE_ACTIVE);
    }

    function  getPublicSaleBalance(address _address) public view returns (uint256) {
        return MINT_BALANCE[_address];
    }

    function getPresaleBalance(address _address) public view returns (uint256) {
        return PRE_SALE_MINT_BALANCE[_address];
    }
    
    function bulkMint(address[] memory _addresses, uint256 _amount) external onlyOwner{
        for ( uint256 i = 0 ; i <  _addresses.length ; i++) {
            safeMint(_amount,_addresses[i]);
        }
    }
    
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
}
