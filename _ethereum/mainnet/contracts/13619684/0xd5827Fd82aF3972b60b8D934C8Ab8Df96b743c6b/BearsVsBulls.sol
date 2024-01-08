// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./VRFConsumerBase.sol";

contract BearsVsBulls is ERC721Enumerable, Ownable, VRFConsumerBase {
  using Strings for uint256;
  using SafeMath for uint256;
  using MerkleProof for bytes32[];

  string public baseURI;
  string public bullBaseURI;
  string public wolfBaseURI;
  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = false;
  bool public freeWolf = true;
  uint16 public maxSupply = 10000;
  uint16 public maxMintAmount = 15;
  uint16 public bearCount;
  uint16 public bullCount;
  uint256 public bearCost = 0.042 ether;
  uint256 public bullCost = 0.069 ether;
  uint256 public randomResult;
  uint256 internal fee;
  uint256[] public _bearTokens;
  uint256[] public _bullTokens;
  address[5] public teamAddresses;
  mapping(address => uint256) public addressMintedBalance;
  mapping(uint256 => uint256) private _typeIndex;
  bytes32 internal keyHash;
  bytes32 internal whitelistMerkleRoot;

  constructor( string memory _initBaseURI, string memory _initBullBaseURI, string memory _initWolfBaseURI ) 
    ERC721('Bears vs Bulls', 'BVB') 
    VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    ) {
    string[3] memory uris = [_initBaseURI, _initBullBaseURI, _initWolfBaseURI];
    setBaseURIs( uris );
    keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    fee = 2 * 10 ** 18; // 2 LINK
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  // public
  // Mint - if not during presale, send empty [] as proof  
  function mint(uint16 _bearMintAmount, uint16 _bullMintAmount, bytes32[] memory proof) public payable {
    require(!paused, "Minting paused");
    uint256 supply = totalSupply();
    uint16 _mintAmount = _bearMintAmount + _bullMintAmount;
    require(_mintAmount > 0, "Mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "Max mint amount per transaction exceeded");
    require(supply + _mintAmount <= maxSupply, "Max NFT limit exceeded");
    
    uint256 mintValue = (_bearMintAmount * bearCost) + (_bullMintAmount * bullCost);
    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isAddressWhitelisted(proof, msg.sender), "User is not on the Whitelist");
            require(addressMintedBalance[msg.sender] + _mintAmount <= 3, "Max NFT per address exceeded");
        }
        require(msg.value >= mintValue, "Insufficient funds");
    }
    
    // Mint Bears
    if (_bearMintAmount > 0) {
      for (uint256 i = 1; i <= _bearMintAmount; i++) {
          _safeMint(msg.sender, supply + i);
          _typeIndex[supply + i] = 1;
          _bearTokens.push(supply + i);
      }
      bearCount += _bearMintAmount;
      addressMintedBalance[msg.sender] += _bearMintAmount;
      supply += _bearMintAmount;
    }
    
    // Mint Bulls
    if (_bullMintAmount > 0) {
      for (uint256 i = 1; i <= _bullMintAmount; i++) {
        _safeMint(msg.sender, supply + i);
        _typeIndex[supply + i] = 2;
        _bullTokens.push(supply + i);
      }
      bullCount += _bullMintAmount;
      addressMintedBalance[msg.sender] += _bullMintAmount;
      supply += _bullMintAmount;
    }
    
    // Buy 3, get 1 wolf free...
    if (freeWolf == true && _mintAmount % 3 == 0) {
        uint256 loops = _mintAmount / 3;
        for (uint256 i = 1; i <= loops; i++) {
            _safeMint(msg.sender, supply + i);
            _typeIndex[supply + i] = 3;
            _bearTokens.push(supply + i);
            _bullTokens.push(supply + i);
        }
    }
  }
  
  function totalBearSupply() public view returns (uint256) {
    return bearCount;
  }

  function totalBullSupply() public view returns (uint256) {
    return bullCount;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if (!revealed) {
        return "https://www.bearsvsbulls.com/prereveal.json";
    }

    // default to bear
    string memory currentBaseURI = _baseURI();
    
    if  ( _typeIndex[tokenId] == 2 ) {
        // it's a bull - switch base URI
        currentBaseURI = bullBaseURI;
    } else if ( _typeIndex[tokenId] == 3 ) {
        // it's a wolf - switch base URI
        currentBaseURI = wolfBaseURI;
    }
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

  function isAddressWhitelisted(bytes32[] memory proof, address _address) public view returns (bool) {
    return proof.verify(whitelistMerkleRoot, keccak256(abi.encodePacked(_address)));
  }

  //only owner
  function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner {
    whitelistMerkleRoot = _whitelistMerkleRoot;
  }
    
  function getRandomNumber() public onlyOwner() returns (bytes32 requestId) {
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    return requestRandomness(keyHash, fee);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    randomResult = randomness;
  }
  
  function selectWinner(uint256 _type) public view onlyOwner() returns (uint256) {
    uint256 totalNum = bearCount;
    if (_type == 2) {
        totalNum = bullCount;
    }
    uint256 randomNum = (randomResult % totalNum);
      
    if (_type == 2) {
        return _bullTokens[randomNum];
    }
    return _bearTokens[randomNum];
  }
  
  function weeklyDraw(uint256 _type) public payable onlyOwner() {
    require(totalSupply() >= 1000, "Draws not started");
    uint256 winnerToken = selectWinner(_type);
      
    address winner = ownerOf(_bearTokens[winnerToken]);
    uint256 prize = bearCost;
    if (_type == 2) {
        winner = ownerOf(_bullTokens[winnerToken]);
        prize = bullCost;
    }
    
    uint256 jackpot = prize;
    if (totalSupply() >= 2500 && totalSupply() < 5000) {
        jackpot = (prize * 5) / 2;
    } else if (totalSupply() >= 5000 && totalSupply() < 7500) {
        jackpot = prize * 5;
    } else if (totalSupply() >= 7500 && totalSupply() < 10000) {
        jackpot = (prize * 15) / 2;
    } else if (totalSupply() == maxSupply) {
        jackpot = prize * 10;
    }
    
    (bool sendPrize, ) = payable(winner).call{value: jackpot}("");

    require(sendPrize, "ERR");
  }
  
  function setCosts(uint256[2] calldata _newCost) public onlyOwner() {
    bearCost = _newCost[0];
    bullCost = _newCost[1];
  }

  function setmaxMintAmount(uint16 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setmaxSupply(uint16 _newmaxSupply) public onlyOwner() {
    maxSupply = _newmaxSupply;
  }

  function setBaseURIs(string[3] memory _newBaseURIs) public onlyOwner {
    baseURI = _newBaseURIs[0];
    bullBaseURI = _newBaseURIs[1];
    wolfBaseURI = _newBaseURIs[2];
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function reveal(bool _state) public onlyOwner {
    revealed = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function setFreeWolf(bool _state) public onlyOwner {
    freeWolf = _state;
  }
  
  function setTeamAddresses(address[2] calldata _members) public onlyOwner {
    delete teamAddresses;
    teamAddresses = _members;
  }
 
  function withdraw() public payable onlyOwner {
    uint256 _onePercent = address(this).balance.div(100);
    address team1 = 0xA4724c7393E2D361E394fDf9f7F5D6BCF644d04A;
    address team2 = 0xe2872d388f73982fb7B4016965194c46604ff09a;
    address team5 = 0xa361b780537304d99D5A7C7e53DBbA50Ee9B761E;
    (bool team1Success, ) = payable(team1).call{value: _onePercent.mul(59)}("");
    (bool team2Success, ) = payable(team2).call{value: _onePercent.mul(3)}("");
    (bool team3Success, ) = payable(teamAddresses[0]).call{value: _onePercent.mul(1)}("");
    (bool team4Success, ) = payable(teamAddresses[1]).call{value: _onePercent.mul(2)}("");
    (bool team5Success, ) = payable(team5).call{value: _onePercent.mul(20)}("");

    require(team1Success, "ERR1");
    require(team2Success, "ERR2");
    require(team3Success, "ERR3");
    require(team4Success, "ERR4");
    require(team5Success, "ERR5");
  }
}