// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./ECDSA.sol";

contract VeeDAO is ERC721, Ownable {
    using Strings for uint256;
	using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenSupply;
    Counters.Counter private _teamMints;
    uint256 public totalCount = 10000;
    uint256 public maxPurchase = 10;
    uint256 public price = 50000000000000000; 
    uint256 public reserved_community = 150;
    string public baseURI;

    uint public constant max_wl_wallet = 10;        
    bool public pre_sale_active = false;                   
    bool public sale_active = false;    

	mapping(address => uint) public wl_mintedNFTs;

    mapping (address => bool)     private adminWallets;  

    
    //constructor args 
	constructor() ERC721 ("VeeDAO", "Vee") {


	}
    
    function setURIs(string memory _newBaseURI) external onlyOwner {
		baseURI = _newBaseURI;
    }

	function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

	function setSaleStatus(bool _start) public onlyOwner {
        sale_active = _start;
    }

    function setPreSaleStatus(bool _start) public onlyOwner {
        pre_sale_active = _start;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }


    function changeBatchSize(uint256 _newBatch) public onlyOwner {
        maxPurchase = _newBatch;
    }

    function mint (uint256 _count) payable public {
        uint256 mintIndex = _tokenSupply.current();
        require(sale_active, "sale has to be active");
        require(_count >0 && _count <= maxPurchase, "Minting more than allowed in a TX");
        require(mintIndex + _count <= totalCount-reserved_community, "VeeDAO is Sold Out");
		require(msg.value == price.mul(_count), "Must provide exact required ETH");

        for(uint256 i=0; i < _count; i++){
            _tokenSupply.increment();
            _safeMint(_msgSender(), _tokenSupply.current());
        }
    }  

    
    function mintWhitelist(uint256 _count, uint256 _timestamp, bytes memory _signature) public payable {

        uint256 mintIndex = _tokenSupply.current();        
        require(pre_sale_active, "Pre-Sale is not active" );
        require(wl_mintedNFTs[msg.sender] + _count <= max_wl_wallet, "Whitelist max mint per wallet is 10");
        require(_count >0 && _count <= maxPurchase, "Minting more than allowed in a TX");
        require(mintIndex + _count <= totalCount-reserved_community, "VeeDAO is Sold Out");
		require(msg.value == price.mul(_count), "Must provide exact required ETH");

        address wallet = _msgSender();
        address signerOwner = signatureWallet(wallet,_timestamp,_signature);
        require(signerOwner == owner(), "Not authorized to mint");

        wl_mintedNFTs[msg.sender] += _count;

        for(uint256 i=0; i < _count; i++){
            _tokenSupply.increment();
            _safeMint(_msgSender(), _tokenSupply.current());
        }

        


    }

    function signatureWallet(address wallet, uint256  _timestamp, bytes memory _signature) public pure returns (address){

        return ECDSA.recover(keccak256(abi.encode(wallet, _timestamp)), _signature);

    }

    
    function TeamMint(address _to, uint256 _count) payable public  {
        require(adminWallets[_msgSender()], "Bye Bye");
		uint256 mintIndex = _tokenSupply.current();
        uint256 teamIndex = _teamMints.current();

        require(teamIndex+ _count <= reserved_community,"Exceeds reserved mints");
		require(mintIndex + _count <= totalCount, "Exceeds Max Tokens Available");

        for(uint256 i=0; i < _count; i++){

            _tokenSupply.increment();
            _teamMints.increment();
            _safeMint(_to, _tokenSupply.current());

        }
    }


	function withdraw() public payable onlyOwner {

        uint256 _community = (address(this).balance * 80) / 100;
        uint256 _wallet_1 = (address(this).balance * 15) / 1000;
        uint256 _wallet_2 = (address(this).balance * 15) / 1000;
        uint256 _wallet_3 = (address(this).balance * 3) / 100;
        uint256 _wallet_4 = (address(this).balance * 3) / 100;
        uint256 _wallet_5 = (address(this).balance * 4) / 100;
        uint256 _wallet_6 = (address(this).balance * 7) / 100;

        address  community_wallet = 0xF8d35aC03d4B743fCdf4DaE359965cb3355400a3;
        address  wallet_1 = 0x3f8A8Fe1872A4503BCe8Ff8e5F6F8Cfb10C25995;
        address  wallet_2 = 0xb4ef5903733613Df79D50F16a46f908314d36cCf;
        address  wallet_3 = 0xc07c0b557789F54A209DD567e2Fb35575B5fF58B;
        address  wallet_4 = 0x84c0438d30703Ba9e81E4F9cEbCCD67d0A9f7Ca8;
        address  wallet_5 = 0xAEE58A8b28C895d7C32F9Edc90E0aD9E1897e2Dc;
        address  wallet_6 = 0x841a2e31d859813371A82579A83E466ef5d5ec0f;

		payable(community_wallet).transfer(_community);
        payable(wallet_6).transfer(_wallet_6);
		payable(wallet_5).transfer(_wallet_5);
		payable(wallet_4).transfer(_wallet_4);
        payable(wallet_3).transfer(_wallet_3);
        payable(wallet_2).transfer(_wallet_2);
        payable(wallet_1).transfer(_wallet_1);

    }


    function tokensMinted() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function teamTokensMinted() public view returns (uint256) {
        return _teamMints.current();
    }

    function setAdminWallets(address wallet_address, bool status) public onlyOwner{
      adminWallets[wallet_address] = status;
    }


}