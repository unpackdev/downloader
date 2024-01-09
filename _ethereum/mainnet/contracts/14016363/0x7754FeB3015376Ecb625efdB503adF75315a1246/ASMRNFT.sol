/*
* NFT Lottery powered by ChainLink
* Telegram: https://t.me/ASMRtoken
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

interface ASMRTOKEN {
    function balanceOf(address account) external view returns (uint256);
}

contract ASMRNFT is ERC721, Ownable, VRFConsumerBase {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uri;
  uint256 public cost = 0.15 ether;
  uint256 public maxSupply = 100;
  uint256 public maxMintAmountPerTx = 5;
  uint256 public winningId;
  address public previousRoundWinner;
  address private tokenAddress;
  uint256 public minTokenToMint;
  uint256 private startingMintTokensToMint;
  uint256 private deployed;
  uint256 public currentLotteryRound = 1;
  uint256 public totalWinnings;
  bool public lotteryStarted = false;
  bool public paused = true;
  bool private requireMinHold = true;
  bytes32 internal keyHash;
  bytes32 public reqId;
  uint256 internal fee;
  uint256 public randomNumber;
  address public VRFCoordinator;
  address public LinkToken; 

    constructor(address _LinkToken, address _VRFCoordinator, bytes32 _keyhash)
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("ASMR Seed Phrases", "ASMR NFT")
    {   
        LinkToken = _LinkToken;
        VRFCoordinator = _VRFCoordinator;
        keyHash = _keyhash;
        fee = 2 * 10**18; // 2 LINK eth mainnet
        deployed = block.timestamp;
    }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function lotteryRoundJackpot() public view returns (uint256) {
    if (address(this).balance < 2 ether){
        return address(this).balance; //if contract balance is less than 2ETH then all of it goes towards the jackpot
    } else {
        return  address(this).balance * 50 / 100; //this takes 50% of the supply and makes it the total jackpot, for longetivity of the project
    }
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    if (requireMinHold)
        require(tokenHolderBalance(msg.sender) >= minTokenToMint, "You must hold at least the proper amount ASMR Tokens");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string(abi.encodePacked(uri, _tokenId.toString()));
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setMinToken(uint256 _minToken) public onlyOwner {
    minTokenToMint = _minToken;
    startingMintTokensToMint = _minToken;
  }
  
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setTokenAddress(address _tokenAddress) public onlyOwner {
    tokenAddress = _tokenAddress;
  }

  function setRequireHold(bool _requireMinHold) public onlyOwner {
    requireMinHold = _requireMinHold;
  }
  
  function setUri(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function withdraw(address _winner) internal virtual {
    uint256 lotteryRoundJackpotDev = lotteryRoundJackpot() * 25 / 100; //25% to devs
    uint256 lotteryRoundJackpotWinner = lotteryRoundJackpot() - lotteryRoundJackpotDev; //remainder to winner
    totalWinnings += lotteryRoundJackpotWinner;
    currentLotteryRound += 1;
    // This will pay Devs 25% of the Jackpot
    // =============================================================================
    (bool hs, ) = payable(owner()).call{value: lotteryRoundJackpotDev}("");
    require(hs);

    // This will transfer the remaining contract balance (75%) to the jackpot winner.
    // =============================================================================
    (bool os, ) = payable(_winner).call{value: lotteryRoundJackpotWinner}("");
    require(os);
    // =============================================================================
    lotteryStarted = false;
  }

  function pickWinner(uint256 _randomNumber) internal virtual {
    // Randomly picks winner from Chainlink VRF
    // =============================================================================
    winningId = _randomNumber % totalSupply() + 1;
    previousRoundWinner = ownerOf(winningId);
    withdraw(previousRoundWinner);
  }

  function tokenHolderBalance(address wallet) public view returns(uint256){
    ASMRTOKEN instance = ASMRTOKEN(tokenAddress);
    uint256 tokenBalance = instance.balanceOf(wallet);
    return tokenBalance;
  }

  function canMint(address wallet) public view returns(bool){
    uint256 amountTokenHeld = tokenHolderBalance(wallet);
    if (amountTokenHeld >= minTokenToMint){
        return true;
    } else {
        return false;
    }
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
    minTokenToMint = (startingMintTokensToMint *  totalSupply()) / 10;
  }

  function startRandomWinnerRequest() public onlyOwner {
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    lotteryStarted = true;
    bytes32 requestId = requestRandomness(keyHash, fee);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    reqId = requestId;
    randomNumber = randomness;
    pickWinner(randomNumber);
  }

  function claimChainLink() external onlyOwner {
    LINK.transfer(owner(), LINK.balanceOf(address(this)));
  }

  function emergencyWithdraw() public onlyOwner {
    uint256 emergencyWithdrawTime = deployed + 7 days;
    require(block.timestamp > emergencyWithdrawTime, "In case of lottery failure you must wait at least 7 days after contract deployment to withdraw contract ETH balance");
    (bool hs, ) = payable(owner()).call{value: address(this).balance}("");
    require(hs);
  }

  receive() external payable {}

}