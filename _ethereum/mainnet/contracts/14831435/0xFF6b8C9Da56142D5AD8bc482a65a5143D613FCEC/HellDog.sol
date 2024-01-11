// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Counters.sol";
import "ECDSA.sol";
import "SafeMath.sol";

contract HellDog is ERC721, Ownable {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using Strings for uint256;

    enum contractState {
        Inactive,
        PresaleActive,
        Active
    }

    uint256 public constant price = 0.08 ether;
    uint256 public constant maxSupply = 888;
    uint256 public constant maxPerAddress = 50;

    address public marketing1Address = 0xF6f197b2789eBAb2fB70AF2349316a3121Ce8087;
    address public marketing2Address = 0xEc11145A9C0e4F69F5EAFa93565A2a48e4C43FB6;
    address public devAddress = 0x679cb2FbfA6b788B4f3BAA4580aD3C8AF620b438;
    address public projectManager1 = 0xE3764e940a4Dd84CDbc07Bac43956b4Eb631844A;
    address public creatorAddress = 0x1aB39dBa75eAA8c30d2509267C615A83a839DD49;

    Counters.Counter private tokenIDCounter;
    address public serverPublicKey; 
    bool private isRevealed = false;
    string private overrideBaseURI;
    contractState state = contractState.Inactive;
    mapping(address => mapping(uint256 => bool)) seenNonces;
    
    constructor(string memory _unrevealedBaseURI) ERC721("HELLDOG", "HDG") payable {
        setBaseURI(_unrevealedBaseURI);
    }

    function safeRecover(bytes32 hash, bytes memory signature) private view returns (address) {
        return hash.recover(signature);
    }

    function withdrawAll() public {
        require(msg.sender == marketing1Address || 
                msg.sender == marketing2Address || 
                msg.sender == devAddress || 
                msg.sender == projectManager1 ||
                msg.sender == creatorAddress ||
                msg.sender == owner(),
                "caller is not a receivable address");
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(marketing1Address, balance.mul(15).div(100));  // 15.0% 
        _widthdraw(marketing2Address, balance.mul(15).div(100));  // 15.0%
        _widthdraw(devAddress, balance.mul(10).div(100));         // 10.0%
        _widthdraw(projectManager1, balance.mul(10).div(100));    // 10.0%
        _widthdraw(creatorAddress, address(this).balance);        // 50.0%
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    
    function _baseURI() internal view override returns (string memory) {
        return string(abi.encodePacked(overrideBaseURI, "/"));
    }

    function setReveal(bool _isRevealed) public onlyOwner {
        setSaleInactive();
        isRevealed = _isRevealed;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!isRevealed) {
            return overrideBaseURI;
        }
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function totalTokensMinted() public view returns (uint256) {
        return tokenIDCounter.current();
    }

    function setPublicKeySignature(address pubAddress) public onlyOwner {
        serverPublicKey = pubAddress;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        overrideBaseURI = _newBaseURI;
    }
    
    function setPresaleActive() public onlyOwner {
        state = contractState.PresaleActive;
    }
    function setSaleActive() public onlyOwner {
        state = contractState.Active;
    }
    function setSaleInactive() public onlyOwner {
        state = contractState.Inactive;
    }

    function Whitelist(address _allowedWallet, uint _amount, bool _isFree, uint _nonce, bytes memory _signature) public payable {
        require(!isRevealed);
        require(state >= contractState.PresaleActive, "Presale is not active");
        require(msg.sender == _allowedWallet, "You were not given permission to mint");
        if (!_isFree) {
            require(msg.value == price * _amount, "Wrong amount of ETH sent" );
        }
        require(balanceOf(msg.sender) + _amount <= maxPerAddress, "Attempted to mint too many tokens");
        require(tokenIDCounter.current() + _amount <= maxSupply, "Amount exceeds max supply");

        bytes memory hexs = abi.encodePacked(_allowedWallet, _amount, _isFree, _nonce);
        bytes32 messageHash = keccak256(hexs);
        bytes32 prefixedHash = messageHash.toEthSignedMessageHash();
        address publicKey = prefixedHash.recover(_signature);
        require(publicKey == serverPublicKey, "publickey doesn't match original signature");
        require(!seenNonces[msg.sender][_nonce], "Cannot reuse nonce");
        seenNonces[msg.sender][_nonce] = true;

        for (uint256 i; i < _amount; i++) {
            _safeMint(msg.sender, tokenIDCounter.current());
            tokenIDCounter.increment();
        }
    }

    function mint(uint256 _numToMint) public payable {
        require(!isRevealed, "cannot mint when revealed");
        require(state >= contractState.Active, "Sale is not active");
        require(balanceOf(msg.sender) + _numToMint <= maxPerAddress, "Attempted to mint too many tokens");
        require(msg.value == price * _numToMint, "Wrong amount of ETH sent");
        require(tokenIDCounter.current() + _numToMint <= maxSupply, "Amount exceeds max supply");
        
        for (uint256 i; i < _numToMint; i++) {
            _safeMint(msg.sender, tokenIDCounter.current());
            tokenIDCounter.increment();
        }
    }

    function burnUnsoldTokens() public onlyOwner {
        require(isRevealed, "must be revealed");
        require(tokenIDCounter.current() != maxSupply, "no tokens left to burn");
        
        for (uint256 i = tokenIDCounter.current(); i < maxSupply; i++) {
            _safeMint(msg.sender, tokenIDCounter.current());
            _burn(tokenIDCounter.current());
            tokenIDCounter.increment();
        }
    }
}
