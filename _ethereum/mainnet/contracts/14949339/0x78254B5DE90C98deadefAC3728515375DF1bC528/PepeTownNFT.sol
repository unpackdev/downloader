// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

interface PepeInterface {
    function balanceOf(address _claimAddress) external view returns (uint256 tokenAmount);
}

contract PepeTownNFT is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = 'ipfs://QmRFD74FVqYZHdBk7w2f5bY4LQoc4mbqokgiRxm39qZxru/';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.001 ether;
  uint256 public maxSupply = 4800;
  uint256 public maxMintAmountPerTx = 2;
  uint256 public maxNFTPerAccount = 100;
  uint256 public timeLimit;
  mapping(address => uint256) public addressMintedBalance;     

  bool public paused = true;
  bool public revealed = true;

  //Mainnet : 0xB8DD7DCF7DcDb7b196fbC2322834a50d8F90E192
  address private goblinBotAddr = 0xB8DD7DCF7DcDb7b196fbC2322834a50d8F90E192;
  PepeInterface GBContract = PepeInterface(goblinBotAddr);  

  constructor(
  ) ERC721A("Pepe Town NFT", "PTN") {
    setHiddenMetadataUri("ipfs://QmThxUzNGmxE6CPxZjUAVRdCw5TCGQ8zabvcF7wPqXt3kM/hidden.json");
    timeLimit = block.timestamp + getDelay();
    _safeMint(_msgSender(), 3);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'max Pepe limit exceeded!');
    require(_mintAmount + addressMintedBalance[_msgSender()] <= maxNFTPerAccount, "You reach maximum Pepe per address!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= getCurrentPrice(_mintAmount), 'Pepe need more funds!');
    _;
  }

  function Mint(uint256 _mintAmount) public payable nonReentrant mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(
      block.timestamp <= timeLimit ,
      "The game is ended, we already have the Pepe KING!"
    );
    addressMintedBalance[_msgSender()] = addressMintedBalance[_msgSender()] + _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
    timeLimit = block.timestamp + getDelay();
  }

  function checkGoblin(address _claim) public view returns (uint256) {
    uint256 tokenAmount = GBContract.balanceOf(_claim);
    return tokenAmount;
  }

  function getCurrentPrice(uint256 _mintAmount) public view returns (uint256) {
      // require(_mintAmount <= maxMintAmountPerTx, 'You request is too big.');
      uint256 step = 300;
      uint256 counter = totalSupply();
      uint256 finalPrice;
      if (counter + _mintAmount <= 303) {
        finalPrice = 0;
      } else {
        uint256 tokenAmount = checkGoblin(_msgSender());
        for (uint256 i = 0; i < _mintAmount; i++) {
          uint256 currentPrice = cost * 2**(counter/step);
          counter++;
          finalPrice = finalPrice + currentPrice;
        }
        // Discount from GoblinBot
        if (tokenAmount > 0 && tokenAmount < 2) {
          finalPrice = finalPrice * 80 / 100;
        } else if (tokenAmount >= 2 && tokenAmount < 5) {
          finalPrice = finalPrice * 70 / 100;
        } else if (tokenAmount >= 5) {
          finalPrice = finalPrice * 60 / 100;
        } 
      }
      return finalPrice;
  }

  function getWinner() public view returns (address) {
      uint256 currentWinnerID = totalSupply() - 1;
      address currentWinner = ownerOf(currentWinnerID);
      return currentWinner;
  }

  function getDelay() private view returns (uint256) {
    //Halving every 300 units after 1200 NFTs sold
      uint256 cuurentMint = totalSupply();
      uint256 delayTime;
      if (cuurentMint <= 1200) {
        delayTime = 5259486;
      }else if(cuurentMint > 1200 && cuurentMint <= 1500){
        delayTime = 2629743;
        }else if(cuurentMint > 1500 && cuurentMint <= 1800){
        delayTime = 1209600;
      }else if(cuurentMint > 1800 && cuurentMint <= 2100){
        delayTime = 604800;
      }else if(cuurentMint > 2100 && cuurentMint <= 2400){
        delayTime = 345600;
      }else if(cuurentMint > 2400 && cuurentMint <= 2700){
        delayTime = 172800;
      }else{
        delayTime = 86400;
      }
      return delayTime;
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setNFTAddr(address _addr) public onlyOwner {
    goblinBotAddr = _addr;
  }

  function resetMaxSupply() external onlyOwner {
    require(
      block.timestamp >= timeLimit ,
      "The game is ongoing, we have the wait for the winner!"
    );
    maxSupply = totalSupply();
  }


  function withdraw() public onlyOwner nonReentrant {
    require(
      block.timestamp >= timeLimit ,
      "The game is ongoing, we have the wait for the winner!"
    );
    // Pay for winner
    uint256 totalBalance = address(this).balance;
    (bool w, ) = payable(getWinner()).call{value: totalBalance * 55 / 100}("");
    require(w);
    // Pay for second prize winner
    (bool s, ) = payable(ownerOf(totalSupply())).call{value: totalBalance * 5 / 100}("");
    require(s);
    // Send to claim pool
    (bool cl, ) = payable(0xE7c563621155bFc33bD59Ea3C8303D158993464e).call{value: totalBalance * 25 / 100}("");
    require(cl);
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}