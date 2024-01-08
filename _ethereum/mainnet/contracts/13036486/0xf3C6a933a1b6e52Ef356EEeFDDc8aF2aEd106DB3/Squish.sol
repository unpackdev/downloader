// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./Counters.sol";

interface ERC721TokenReceiver
{
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// look into this 
contract Squish is IERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event Mint(uint indexed index, address indexed minter);

    event Transfer(address from, address to, uint256 tokenId);

    event Approval(address owner, address approved, uint256 tokenId);

    event ApprovalForAll(address owner,address operator,bool approved);

    event MultiMint(string handle, uint number);

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint public constant TOKEN_LIMIT = 10000;
    uint public MINTED_AMOUNT;
    uint public squishRemaining = 10000;
    uint internal numTokens = 0;

    address payable internal deployer;
    address payable internal beneficiary;

    mapping(bytes4 => bool) internal supportedInterfaces;

    //don't think we need this 
    mapping(uint256 => address) internal idToOwner;

    mapping(uint256 => uint256) public creatorNftMints;

    mapping(uint256 => address) internal idToApproval;

    mapping(address => mapping(address => bool)) internal ownerToOperators;

    mapping(address=>uint256[]) internal ownerToIds;

    mapping(uint256 => uint256) internal idToOwnerIndex;

    string internal nftName = "Squishy";
    string internal nftSymbol = "SQSH";

    uint internal nonce = 0;
    uint[TOKEN_LIMIT] internal indices;

    bool private reentrancyLock = false;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

        /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "Cannot operate.");
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender], "Cannot transfer."
        );
        _;
    }

    //between 0 and the length of the ipfshash array 
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "Invalid token.");
        _;
    }

    constructor(address payable _beneficiary) public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
        deployer = msg.sender;
        beneficiary = _beneficiary;     
    }

    //////////////////////////
    //// ERC 721 ERC 165  ////
    /////////////////////////
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }
    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Wrong from address.");
        require(_to != address(0), "Cannot send to 0x0.");
        _transfer(_to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(uint256 _tokenId) external view override returns (address _owner) {
        require(idToOwner[_tokenId] != address(0));
        _owner = idToOwner[_tokenId];
    }

    function getApproved(uint256 _tokenId) external view override validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }
    
    //// Enumerable

    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenByIndex(uint256 index) public pure returns (uint256) {
        require(index >= 0 && index < TOKEN_LIMIT);
        return index + 1;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

    //// Metadata

    function randomIndex() internal returns (uint) {
        uint totalSize = TOKEN_LIMIT - numTokens;
        uint index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        require(index >= 0, "must have int as index");
        uint value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value + 1;
    }
    
    function mint() external payable reentrancyGuard returns (uint) {
        uint salePrice = 5*10**16 wei;
        require(msg.value == salePrice, "insufficient funds to purchase.");
        require(numTokens < TOKEN_LIMIT, "Sale limit reached!");
        beneficiary.transfer(msg.value);
        return _mint(msg.sender);
    }

    function multiMint(uint amount) external payable reentrancyGuard returns (uint[] memory) {
        require(amount <= 40, "can only mint 10 at a time!");
        uint salePrice = amount * (5*10**16 wei);
        require(msg.value == salePrice, "insufficient funds to purchase.");
        require(numTokens < TOKEN_LIMIT, "Sale limit reached!");
        beneficiary.transfer(msg.value);
        uint[] memory ids = new uint[](amount);
        for (uint8 i=0; i<amount; i++) {
            uint id = _mint(msg.sender);
            ids[i] = id;
        }
        return ids;
    }

    function devMint(address _to) public {
        require(msg.sender == deployer, "must be deployer");
        uint16[20] memory ids = [6593,734,2445,9836,8097,5697,4700,4440,3277,6084,6311,7883,9610,2971,2253,7129,6057,98,437,14];
        for (uint8 i=0; i<ids.length; i++) {
            _addNFToken(_to, ids[i]);
            numTokens = numTokens + 1;
            squishRemaining--;
            emit Mint(ids[i], _to);
            emit Transfer(address(0), _to, ids[i]);
        }
    }

    function _mint(address _to) internal returns (uint) {
        require(_to != address(0), "cannot mint to 0x0");
        require(numTokens < TOKEN_LIMIT, "Token limit reached");
        uint id = randomIndex();
        numTokens = numTokens + 1;
        squishRemaining--;
        _addNFToken(_to, id);

        emit Mint(id, _to);
        emit Transfer(address(0), _to, id);
        return id;
    }
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0), "Cannot add, already owned.");
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
    }

        function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from, "Incorrect owner.");
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Incorrect owner.");
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }
    /**
      * @dev Returns a descriptive name for a collection of NFTokens.
      * @return _name Representing name.
      */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return _symbol Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }
    function toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
    // remember to put the bytes32 to string back
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return string(abi.encodePacked("ipfs://QmRMn95jNjMpKXTyGpKZ4YojXnpRqZZaD3KMTeUu1CTJPk/",toString(_tokenId),".json"));
    }

}