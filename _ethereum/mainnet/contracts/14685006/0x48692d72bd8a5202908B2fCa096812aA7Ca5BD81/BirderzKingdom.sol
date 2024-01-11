// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./MerkleProof.sol";
import "./SafeMath.sol"; 
import "./Strings.sol";
import "./ERC721Enumerable.sol"; 
import "./Ownable.sol"; 
import "./IGenesisBirdez.sol";

contract BirdezKingdom is ERC721Enumerable, Ownable {
    using Strings for uint256;
     
    IGenesisBirdez public immutable genesis;  
  
   
    uint256 public constant START = 5000;  
    mapping(uint256 => uint256) public maxFreeMintsPerToken;

    bool public startSale; 
    bool public isBaseURILocked;
    address[] public wallets;

    string private baseURI; 

    constructor(
        string memory _name, 
        string memory _symbol,
        IGenesisBirdez _genesis
     ) ERC721(_name, _symbol) {
        require(address(_genesis) != address(0), "invalid-genesis"); 
        genesis = _genesis; 
        startSale = false;  
    } 
  
    function setWallet(address[] memory _list) external onlyOwner{
        delete wallets; 
        for(uint i = 0; i < _list.length; i++){
            wallets.push(_list[i]);
        }
    }


    function setBaseURI(string memory _uri) external onlyOwner {
        require(!isBaseURILocked, "locked-base-uri");       
        baseURI = _uri;
    } 

    function lockBaseURI() external onlyOwner {
        isBaseURILocked = true; 
    } 
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "non-existent-token");
        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId.toString()));
    }
 
    function openSale() public onlyOwner {
        startSale = !startSale;
    }   

    function getGenesisCount(address _owner) public view returns (uint256){
        return genesis.balanceOf(_owner);
    }

    function getGenesisByAddressAndIndex(address _owner, uint256 _tokenId) public view returns (uint256){
        return genesis.tokenOfOwnerByIndex(_owner, _tokenId);
    }
 
     function airdrop() external onlyOwner{ 
        require(startSale, "sale-not-open");   

        for (uint i = 0; i < wallets.length; i++) {  
            address _user = wallets[i]; 
            uint256 _numberOfTokens = getGenesisCount(_user);
            for(uint k = 0; k < _numberOfTokens; k++){ 
                uint256 tid = getGenesisByAddressAndIndex(_user, k);
                if(maxFreeMintsPerToken[tid] > 0) continue;
                _safeMint(_user, START + totalSupply());  
                maxFreeMintsPerToken[tid]++;
            } 
        } 
    }
 
 
     function mint(address _user) external payable{ 
        require(startSale, "sale-not-open");   
  
        uint256 _numberOfTokens = getGenesisCount(_user);
        for(uint i = 0; i < _numberOfTokens; i++){ 
            uint256 tid = getGenesisByAddressAndIndex(_user, i);
            if(maxFreeMintsPerToken[tid] > 0) continue;
            _safeMint(_user, START + totalSupply());  
            maxFreeMintsPerToken[tid]++;
        }  
    }
 
  
}