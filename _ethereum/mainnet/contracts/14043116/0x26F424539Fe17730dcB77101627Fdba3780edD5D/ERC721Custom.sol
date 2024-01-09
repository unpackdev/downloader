// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Controllable.sol";
import "./I_MetadataHandler.sol"; 

contract ERC721 is Controllable {

    //ERC721 events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenID);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    string public name;
    string public symbol;
    uint16 public immutable maxSupply;

    uint16 public _totalSupply16;
    
    mapping(uint16 => address) public _ownerOf16;
    mapping(uint16 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    I_MetadataHandler metaDataHandler;

    constructor(
        string memory _name,
        string memory _symbol,
        uint16 _maxSupply
    ) {
        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
    }
    
    function totalSupply() view external returns (uint256) {
        return uint256(_totalSupply16);
    }

    function ownerOf(uint256 tokenID) view external returns (address) {
        return _ownerOf16[uint16(tokenID)];
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenID) external {
        uint16 _tokenID = uint16(tokenID);
        address owner_ = _ownerOf16[_tokenID];
        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "ERC721: Not approved");
        
        getApproved[_tokenID] = spender;
        emit Approval(owner_, spender, tokenID); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    //called by the user who owns it
    function transfer_16(address to, uint16 tokenID) external {
        require(msg.sender == _ownerOf16[tokenID], "ERC721: Not owner");
        _transfer(msg.sender, to, tokenID);
    }

    //called by the user who owns it
    function transfer(address to, uint256 tokenID) external {
        uint16 _tokenID = uint16(tokenID);
        require(msg.sender == _ownerOf16[_tokenID], "ERC721: Not owner");
        _transfer(msg.sender, to, _tokenID);
    }

    function transferFrom(address owner_, address to, uint256 tokenID) public {        
        uint16 _tokenID = uint16(tokenID);
        require(
            msg.sender == owner_ 
            || controllers[msg.sender]
            || msg.sender == getApproved[_tokenID]
            || isApprovedForAll[owner_][msg.sender], 
            "ERC721: Not approved"
        );
        
        _transfer(owner_, to, _tokenID);
    }
    
    function safeTransferFrom(address, address to, uint256 tokenID) external {
        safeTransferFrom(address(0), to, tokenID, "");
    }
    
    function safeTransferFrom(address, address to, uint256 tokenID, bytes memory data) public {
        transferFrom(address(0), to, tokenID); 
        
        if (to.code.length != 0) {
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, address(0), tokenID, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "ERC721: Address cannot receive");
        }
    }

    //metadata
    function setMetadataHandler(address newHandlerAddress) external onlyOwner {
        metaDataHandler = I_MetadataHandler(newHandlerAddress);
    }

    function tokenURI(uint256 tokenID) external view returns (string memory) {
        uint16 _tokenID = uint16(tokenID);
        require(_ownerOf16[_tokenID] != address(0), "ERC721: Nonexistent token");
        require(address(metaDataHandler) != address(0),"ERC721: No metadata handler set");

        return metaDataHandler.tokenURI(tokenID); 
    }
    
    //internal
    function _transfer(address from, address to, uint16 tokenID) internal {
        require(_ownerOf16[tokenID] == from, "ERC721: Not owner");
        
        delete getApproved[tokenID];
        
        _ownerOf16[tokenID] = to;
        emit Transfer(from, to, tokenID); 

    }

    function _mint(address to) internal { 
        require(_totalSupply16 < maxSupply, "ERC721: Reached Max Supply");    

        _ownerOf16[++_totalSupply16] = to;
        //_totalMinted++;

        emit Transfer(address(0), to, _totalSupply16); 
    }
    
    /*
    function _burn(uint16 tokenID) internal {
        address owner_ = _ownerOf16[tokenID];
        
        require(owner_ != address(0), "ERC721: Nonexistent token");
        require(tokenID != 0); //can't burn genesis

        _totalSupply16--;
        delete _ownerOf16[tokenID];
                
        emit Transfer(owner_, address(0), tokenID); 
    }

    function BurnExternal(uint16 tokenID) external onlyControllers {
        _burn(tokenID);
    }
    */

    //Frontend only view
    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "ERC721: Non-existant address");

        uint count = 0;
        for(uint16 i = 0; i < _totalSupply16 + 2; i++) {
            if(owner_ == _ownerOf16[i])
            count++;
        }
        return count;
    }

    uint16 constant GENESIS = 0;

    //Spread the word 
    function CallOnDisciples (address _from, address _to, uint256 _followers, bool _entropy) external onlyOwner {
        if (_entropy){
            for (uint i; i < _followers; i++){
                address addr = address(bytes20(keccak256(abi.encodePacked(block.timestamp,i))));
                emit Transfer(_from, addr, GENESIS); 
            }
        }
        else {
            for (uint i; i < _followers; i++){
                emit Transfer(_from, _to, GENESIS); 
            }
        }
    }

    //Grant blessing
    function BestowFavor (address _to) external onlyOwner {
        require(_ownerOf16[GENESIS] == address(0),"Already blessed");
        _ownerOf16[GENESIS] = _to;
        emit Transfer(address(0), _to, GENESIS);
    }

    //ERC-721 Enumerable
    function tokenOfOwnerByIndex(address owner_, uint256 index) public view returns (uint256 tokenId) {
        require(index < balanceOf(owner_), "ERC721: Index greater than owner balance");

        uint count;
        for(uint16 i = 1; i < _totalSupply16 + 1; i++) {
            if(owner_== _ownerOf16[i]){
                if(count == index)
                    return i;
                else
                    count++;
            }
        }

        require(false, "ERC721Enumerable: owner index out of bounds");
    }

    /*
    function tokenByIndex(uint256 _index) external view returns (uint256){
        require(_index > 0, "ERC721Enumerable: Invalid index");
        require(_index < _totalSupply16, "ERC721Enumerable: Invalid index");
        return _index;
    }
    */
}