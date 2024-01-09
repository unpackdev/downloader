// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Controllable.sol";
import "./I_TokenData.sol";
contract ERC721 is Controllable {

    mapping(uint16 => address) public _ownerOf16;
    mapping(uint16 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenID);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    uint16 public _totalMinted;
    uint16 public _totalSupply16;
    string public name;
    string public symbol;
    uint16 public immutable maxSupply;
    I_TokenData tokenData;

    constructor(string memory _name, string memory _symbol, uint16 _maxSupply) {
        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
    }
    
    function totalSupply() view external returns (uint256) {
        return uint256(_totalSupply16);
    }
    
    function approve(address spender, uint256 tokenID) external {
        uint16 _tokenID = uint16(tokenID);
        address owner_ = _ownerOf16[_tokenID];
        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender],
            "ERC721: Not approved");
        
        getApproved[_tokenID] = spender;
        emit Approval(owner_, spender, tokenID); 
    }
    
    function transfer(address to, uint256 tokenID) external {
        uint16 _tokenID = uint16(tokenID);
        require(msg.sender == _ownerOf16[_tokenID], "ERC721: Not owner");
        _transfer(msg.sender, to, _tokenID);
    }

    function ownerOf(uint256 tokenID) view external returns (address) {
        return _ownerOf16[uint16(tokenID)];
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
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

    function setTokenData(address newHandlerAddress) external onlyOwner {
        tokenData = I_TokenData(newHandlerAddress);
    }

    function tokenURI(uint256 tokenID) external view returns (string memory) {
        uint16 _tokenID = uint16(tokenID);
        require(_ownerOf16[_tokenID] != address(0), "ERC721: Nonexistent token");
        require(address(tokenData) != address(0),"ERC721: No metadata handler set");
        return tokenData.tokenURI(tokenID); 
    }
    
    function _transfer(address from, address to, uint16 tokenID) internal {
        require(_ownerOf16[tokenID] == from, "ERC721: Not owner");
        delete getApproved[tokenID];
        
        _ownerOf16[tokenID] = to;
        emit Transfer(from, to, tokenID); 
    }

    function _mintinternal(address to, uint16 tokenID) internal { 
        require(_ownerOf16[tokenID] == address(0), "ERC721: Token already minted");
        require(_totalSupply16 < maxSupply, "ERC721: Reached Max Supply");    

        _ownerOf16[tokenID] = to;
        _totalMinted++;
        _totalSupply16++;

        emit Transfer(address(0), to, tokenID); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transfer_16(address to, uint16 tokenID) external {
        require(msg.sender == _ownerOf16[tokenID], "ERC721: Not owner");
        _transfer(msg.sender, to, tokenID);
    }

    function _burninternal(uint16 tokenID) internal {
        address owner_ = _ownerOf16[tokenID];
        require(owner_ != address(0), "ERC721: Nonexistent token");
        _totalSupply16--;
        
        delete _ownerOf16[tokenID];
                
        emit Transfer(owner_, address(0), tokenID); 
    }

    //authorized minting contracts only
    function mintExternal(address to, uint16 tokenID) external onlyControllers {
        _mintinternal(to, tokenID);
    }

    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "ERC721: Non-existant address");

        uint count = 0;
        for(uint16 i = 1; i < _totalSupply16 + 1; i++) {
            if(owner_ == _ownerOf16[i])
            count++;
        }
        return count;
    }

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

}