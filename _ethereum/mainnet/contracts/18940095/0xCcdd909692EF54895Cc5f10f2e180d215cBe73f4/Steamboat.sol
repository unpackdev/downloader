// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./EnefteOwnership.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract Steamboat is ERC721A, EnefteOwnership {

    uint64 public MAX_SUPPLY = 5000;
    uint64 public TOKEN_PRICE = 0.0069 ether;
    uint64 public PRESALE_TOKEN_PRICE = 0.0069 ether;
    uint64 public MAX_TOKENS_PER_WALLET = 5;
    uint64 public saleOpens = 999999999999999;
    uint64 public publicOpens = 999999999999999;
    bytes32 private merkleRoot; 
    string public BASE_URI = "";


    function mint(uint64 _numberOfTokens, bytes32[] calldata _merkleProof) external payable  {
        if(block.timestamp < saleOpens){
            revert("Sale not open");
        }
        
        if(totalSupply() + _numberOfTokens > MAX_SUPPLY){
            revert("Not enough left");
        }
        
        uint64 mintsForThisWallet = mintsForWallet(msg.sender);
        mintsForThisWallet += _numberOfTokens;
        if(mintsForThisWallet > MAX_TOKENS_PER_WALLET){
            revert("Max tokens reached per wallet");
        }


        if(block.timestamp < publicOpens){
            
            if(PRESALE_TOKEN_PRICE * _numberOfTokens > msg.value){
                revert("Not enough eth sent");
            }
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if(!MerkleProof.verify(_merkleProof, merkleRoot, leaf)){
                revert("Presale and not whitelisted.");
            }
        }else {
            if(TOKEN_PRICE * _numberOfTokens > msg.value){
                revert("Not enough eth sent");
            }
        }
        
        _mint(msg.sender, _numberOfTokens);
        _setAux(msg.sender,mintsForThisWallet);
    }

    function airdrop(address[] memory _wallets) external onlyDevOrOwner  {
        for(uint i = 0;i<_wallets.length;i++){
            _mint(_wallets[i], 1);
            _setAux(msg.sender,mintsForWallet(_wallets[i])+1);
        }
    }

    function mintsForWallet(address _wallet) public view returns (uint64) {
        return _getAux(_wallet);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyDevOrOwner {
        merkleRoot = _merkleRoot;
    }

    function setSaleTimes(uint64 _saleOpens, uint64 _publicOpens) external onlyDevOrOwner {
        saleOpens = _saleOpens;
        publicOpens = _publicOpens;
    }
    
    function setMaxPerWallet(uint64 _quantity) external onlyDevOrOwner {
        MAX_TOKENS_PER_WALLET = _quantity;
    }
    
    function setPrice(uint64 _price) external onlyDevOrOwner {
        TOKEN_PRICE = _price;
    }

    function setPresalePrice(uint64 _price) external onlyDevOrOwner {
        PRESALE_TOKEN_PRICE = _price;
    }
    
    function setMaxSupply(uint64 _supply) external onlyDevOrOwner {
        MAX_SUPPLY = _supply;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if(from != address(0) && block.timestamp < (publicOpens+3600)){
            revert("Cannot sell before public sale opens");
        }
    }


    function setBaseURI(string memory _uri) external onlyDevOrOwner {
        BASE_URI = _uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    function withdrawBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether to Wallet");
    }
    
    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }
    
    constructor() ERC721A("Steamboat Willie","SBOAT") {
        setOwner(msg.sender);
        _mint(msg.sender, 1);
    }

}