// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./SafeMath.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./ERC721Tradable.sol";


contract Puzzled is ERC721Tradable {

    string private _contractURI;
    
    constructor(address _proxyRegistryAddress, string memory _cURI) ERC721Tradable("Puzzled?", "CUBES", _proxyRegistryAddress) {  _contractURI = _cURI; }
    
    using SafeMath for uint256;
    using Address for address;
    event MintCube (address indexed sender, uint256 startWith, uint256 times);

    uint public constant MAX_TOKENS = 5555;
    uint256 public price = 25000000000000000; 
    uint public MAX_FREE = 1111;

    bool public sale_active = false;    
    bool public pre_sale_active = true;                     // Change Before Mainnet Deploy
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 6;  // Change Before Mainnet Deploy
    uint public constant maxNFTPerWallet = 12;             // Change Before Mainnet Deploy
    uint public constant max_wl_wallet = 2;             // Change Before Mainnet Deploy
  

    uint256 public reserved_tokens = 333;
    
    uint[] public mintedIds;
    string private base_url;
    uint256 public minted_reserved_tokens = 0;

    mapping(address => uint) public mintedNFTs;
    mapping(address => uint) public wl_mintedNFTs;



    function setBaseURI(string memory newUri) public onlyOwner {
        base_url = newUri;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return base_url;
    }

    function contractURI() public view returns (string memory) {
    return _contractURI;
    }

    // Should only be changed when there's a critical change to the contract metadata
    function setContractURI(string memory _cURI) external onlyOwner {
        _contractURI = _cURI;
    }

    function flipSaleStatus() public onlyOwner {
        sale_active = !sale_active;
        
    }

    function flipPreSaleStatus() public onlyOwner {
        pre_sale_active = !pre_sale_active;
    }

    function mintCube(uint256 _count) external payable {
        uint256 totalSupply = totalSupply();

        require(sale_active, "Sale is not active" );
        require(mintedNFTs[msg.sender] + _count <= maxNFTPerWallet, "maxNFTPerWallet constraint violation");
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1, "Exceeds maximum tokens you can purchase in a single transaction");
        require(totalSupply + _count <= MAX_TOKENS, "Exceeds maximum tokens available for purchase");
        require(msg.value >= price.mul(_count), "Ether value sent is not correct");
        require(!_msgSender().isContract(), "Contracts are not allowed");
        emit MintCube(_msgSender(), _getNextTokenId(), _count);
        mintedNFTs[msg.sender] += _count;

        for(uint256 i=0; i < _count; i++){
            _mint(_msgSender(), _getNextTokenId());
            mintedIds.push(_getNextTokenId());
            _incrementTokenId();

        }
        

    }


    function freeMintCube(uint256 _count) external payable {
        uint256 totalSupply = totalSupply();
        
        require(sale_active, "Sale is not active" );
        require(mintedNFTs[msg.sender] + _count <= maxNFTPerWallet, "maxNFTPerWallet constraint violation");
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1, "Exceeds maximum tokens you can purchase in a single transaction");
        require(totalSupply+_count <= MAX_FREE, "Exceeds maximum tokens available for Free");
        require(!_msgSender().isContract(), "Contracts are not allowed");
        emit MintCube(_msgSender(), _getNextTokenId(), _count);
        mintedNFTs[msg.sender] += _count;


        for(uint256 i=0; i < _count; i++){
            _mint(_msgSender(), _getNextTokenId());
            mintedIds.push(_getNextTokenId());
            _incrementTokenId();

        }
        

    }



    function mintWhitelist(uint256 _count, uint256 _timestamp, bytes memory _signature) public payable {

        
        require(pre_sale_active, "Pre-Sale is not active" );
        require(wl_mintedNFTs[msg.sender] + _count <= max_wl_wallet, "maxNFTPerWallet constraint violation");
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1, "Exceeds maximum tokens you can purchase in a single transaction");
        require(!_msgSender().isContract(), "Contracts are not allowed");

        address wallet = _msgSender();
        address signerOwner = signatureWallet(wallet,_timestamp,_signature);
        require(signerOwner == owner(), "Not authorized to mint");

        emit MintCube(_msgSender(), _getNextTokenId(), _count);
        wl_mintedNFTs[msg.sender] += _count;


        for(uint256 i=0; i < _count; i++){
            _mint(_msgSender(), _getNextTokenId());
            mintedIds.push(_getNextTokenId());
            _incrementTokenId();

        }
        


    }

    function signatureWallet(address wallet, uint256  _timestamp, bytes memory _signature) public view returns (address){

        return ECDSA.recover(keccak256(abi.encode(wallet, _timestamp)), _signature);

    }

    function reserveTokens(address _to, uint256 _reserveAmount) public onlyOwner {   
        require(minted_reserved_tokens <= reserved_tokens, "All allocated tokens are reserved");
        uint totalSupply = totalSupply();
        for (uint i = 0; i < _reserveAmount; i++) {
            _mint(_to, totalSupply + i + 1);
            mintedIds.push(totalSupply + i + 1);
            minted_reserved_tokens = minted_reserved_tokens +1;

        }
    }
    

    function setMaxFree(uint256 _newMax) public onlyOwner() {
        MAX_FREE = _newMax;
    }


    function get_all() public view  returns (uint[] memory) {
        return mintedIds;
    }



    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }




}