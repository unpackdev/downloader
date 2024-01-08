// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./Counters.sol";

import "./Presalable.sol";

contract Voodollz is ERC721Enumerable, Ownable, Pausable, Presalable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    uint256 private constant _RESERVED = 100;

    string public baseTokenURI;
    
    uint256 public constant MAX_TOKEN_COUNT = 9999;
    uint256 public constant PRICE = 0.08 ether;
    uint256 public constant PRESALE_PRICE = 0.07 ether;

    mapping(address => uint8) public tokenOwnersCounter;
    mapping(address => uint8) public presaleTokenOwnersCounter;
    
    Counters.Counter private _tokenIdCounter = Counters.Counter(_RESERVED);
    Counters.Counter private _giveTokenIdCounter;

    address t1 = 0x2A71996Eb62E15f76C78d90B6ce901527e47aB0D;
    address t2 = 0x5795FCC85820DDfD20A310CB2705700082FDFD52;
    address t3 = 0x333EaDE7E56F6e55F7dA16050efCCbD24303E99A;

    constructor(string memory _baseTokenURI) ERC721("Voodollz", "VDLZ")  {
        setBaseURI(_baseTokenURI);
        presale();
    }

    // Mint methods

    function mint(uint256 _amount) public payable whenNotPresaled whenNotPaused {
        require(tokenOwnersCounter[msg.sender] + _amount <= 5, "Can only mint 5 tokens at address");
        require(_tokenIdCounter.current() + _amount <= MAX_TOKEN_COUNT, "Exceeds maximum Voodollz supply");
        require(_amount <= 3, "Can only mint 3 tokens at a time");
        require(msg.value >= PRICE * _amount, "Ether value sent is not correct");
    
        for(uint256 i = 0; i < _amount; i++) {
            if (_tokenIdCounter.current() < MAX_TOKEN_COUNT) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, _tokenIdCounter.current());
                tokenOwnersCounter[msg.sender] += 1;
            }
        }
    }

    function presaleMint(uint256 _amount, bytes memory _signature) public payable whenPresaled whenNotPaused {        
        address signer = recoverSigner(msg.sender, _signature);

        require(signer == owner(), "Not authorized to mint");
        require(presaleTokenOwnersCounter[msg.sender] + _amount <= 6, "Can only mint 6 tokens at address");
        require(_tokenIdCounter.current() + _amount <= MAX_TOKEN_COUNT, "Exceeds maximum Voodollz supply");
        require(_amount <= 3, "Can only mint 3 tokens at a time");
        require(msg.value >= PRESALE_PRICE * _amount, "Ether value sent is not correct");
    
        for(uint256 i = 0; i < _amount; i++) {
            if (_tokenIdCounter.current() < MAX_TOKEN_COUNT) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, _tokenIdCounter.current());
                presaleTokenOwnersCounter[msg.sender] += 1;
            }
        }
    }

    // Give methods
    
    function giveAway(address _to) public onlyOwner {
        require(_giveTokenIdCounter.current() < _RESERVED, "Exceeds reserved Voodollz supply");

        _giveTokenIdCounter.increment();
        _safeMint(_to, _giveTokenIdCounter.current());
    }

    // Burn methods
    
    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        _burn(tokenId);
    }

    // Service methods

    function tokensOfOwner(address _owner) public view returns(uint256[] memory){
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function recoverSigner(address _wallet, bytes memory _signature) private pure returns (address){
        return keccak256(abi.encodePacked(_wallet)).toEthSignedMessageHash().recover(_signature);
    }
    
    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance / 100;

        require(payable(t1).send(_balance * 2));
        require(payable(t2).send(_balance * 48));
        require(payable(t3).send(_balance * 50));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function presale() public onlyOwner {
        _presale();
    }

    function unpresale() public onlyOwner {
        _unpresale();
    }
}