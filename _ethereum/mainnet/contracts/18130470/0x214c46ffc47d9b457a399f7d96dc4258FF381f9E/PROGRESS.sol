// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) { 
        return ERC721TokenReceiver.onERC721Received.selector; 
    }
}

abstract contract ERC721 {
    
    event Transfer(address indexed from_, address indexed to_, uint256 indexed tokenId_);
    event Approval(address indexed owner_, address indexed spender_, uint256 indexed id_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, bool approved_);
    
    string public name; 
    string public symbol;

    struct TokenData { address owner; }
    struct BalanceData { uint32 balance; }

    mapping(uint256 => TokenData) public _tokenData;
    mapping(address => BalanceData) public _balanceData;

    function balanceOf(address owner_) public virtual view returns (uint256) {
        require(owner_ != address(0), "balanceOf to 0x0");
        return _balanceData[owner_].balance;
    }
    
    function ownerOf(uint256 tokenId_) public virtual view returns (address) {
        address _owner = _tokenData[tokenId_].owner;
        require(_owner != address(0), "ownerOf token does not exist!");
        return _owner;
    }

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(string memory name_, string memory symbol_) { name = name_; symbol = symbol_; }

    function _mint(address to_, uint256 tokenId_) internal virtual { unchecked {
        require(to_ != address(0), "_mint to 0x0");
        require(_tokenData[tokenId_].owner == address(0), "_mint token exists");
        _tokenData[tokenId_].owner = to_;
        _balanceData[to_].balance++;
        emit Transfer(address(0), to_, tokenId_);
    }}

    function _burn(uint256 tokenId_) internal virtual { unchecked {
        address _owner = ownerOf(tokenId_);
        _balanceData[_owner].balance--;
        delete _tokenData[tokenId_];
        delete getApproved[tokenId_];
        emit Transfer(_owner, address(0), tokenId_);
    }}

    function _transfer(address from_, address to_, uint256 tokenId_, bool checkApproved_) internal virtual { unchecked {
        require(to_ != address(0), "_transfer to 0x0");
        address _owner = ownerOf(tokenId_);
        require(from_ == _owner, "_transfer not from owner");
        if (checkApproved_) require(_isApprovedOrOwner(_owner, msg.sender, tokenId_), "_transfer not approved");
        delete getApproved[tokenId_];
        _tokenData[tokenId_].owner = to_;
        _balanceData[from_].balance--;
        _balanceData[to_].balance++;
        emit Transfer(from_, to_, tokenId_);
    }}

    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        _transfer(from_, to_, tokenId_, true);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        require(to_.code.length == 0 || ERC721TokenReceiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) ==
        ERC721TokenReceiver.onERC721Received.selector, "safeTransferFrom to unsafe address");
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function approve(address spender_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender], "approve not authorized!");
        getApproved[tokenId_] = spender_;
        emit Approval(_owner, spender_, tokenId_);
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual {
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    function _isApprovedOrOwner(address owner_, address spender_, uint256 tokenId_) internal virtual view returns (bool) {
        return (owner_ == spender_ || getApproved[tokenId_] == spender_ || isApprovedForAll[owner_][spender_]);
    }

    function supportsInterface(bytes4 id_) public virtual view returns (bool) {
        return  id_ == 0x01ffc9a7 || 
                id_ == 0x80ac58cd || 
                id_ == 0x5b5e139f;
    }

    function tokenURI(uint256 tokenId_) public virtual view returns (string memory) {}
}

abstract contract ERC721TokenURI {

    string public baseTokenURI;

    function _setBaseTokenURI(string memory uri_) internal {
        baseTokenURI = uri_;
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(owner == msg.sender, "only owner");_; }
    function transferOwnership(address newOwner) external onlyOwner { emit OwnershipTransferred(owner, newOwner); owner = newOwner; }
}

contract PROGRESS is ERC721, ERC721TokenURI, Ownable {

    event List(address, uint256);

    uint256 public current;
    uint256 public totalSupply;
    uint256 public lastMintTimestamp;
    uint256 constant price = 0.04 ether;
    uint256 constant evolveTime = 86400;
    uint256 constant over = 1123200;
    mapping(uint256 => uint256) public tokenIdToTimestamp;

    constructor() ERC721("PROGRESS", "PROGRESS") {
        lastMintTimestamp = block.timestamp;
    }

    function setBaseTokenURI(string memory uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }

    function mint() external payable {
        uint256 timePassed = block.timestamp - lastMintTimestamp;
        require(timePassed <= over, "over");
        tokenIdToTimestamp[totalSupply] = timePassed;
        if (timePassed > current) {
            current = timePassed;
        }
        if (msg.value >= price) {
            emit List(msg.sender, msg.value);
        }
        _mint(msg.sender, totalSupply);
        totalSupply++;
        lastMintTimestamp = block.timestamp;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, _toString(tokenIdToTimestamp[tokenId_]), "/", _toString(tokenId_)));
    }

    function withdraw(address destination, uint256 amount) external onlyOwner {
        (bool success, ) = destination.call{value: amount}("");
        require(success, "TRANSFER FAILED");
    }
}