// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./LinkTokenInterface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ERC721.sol";

contract Jackpot is ERC721, Ownable, VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  uint64 subscriptionId;
  address vrfCoordinator;
  address link_token_contract = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
  bytes32 keyHash;
  uint32 callbackGasLimit = 150000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;

  bool public paused;

  uint256 public transferPrice = 30000000000000000;
  address payable rake = payable(0x6e4668EaBBa3095d64fe302d8d480D2Af39092F2);

  mapping(uint256 => address payable) reqIdToFromAddress;

  event Win(address, uint256, uint256);
  event JackpotBalance(uint256);

  receive() external payable {
    require(msg.value >= transferPrice, "Not enough ETH sent");
    transferFrom(
      payable(ownerOf(0)),
      msg.sender,
      0
    );
  }

  constructor(
      uint64 _subscriptionId,
      address _vrfCoordinator,
      bytes32 _keyHash,
      string memory _name,
      string memory _symbol
  ) ERC721(_name, _symbol, 1)
    VRFConsumerBaseV2(_vrfCoordinator) 
  {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link_token_contract);
    subscriptionId = _subscriptionId;
    vrfCoordinator = _vrfCoordinator;
    keyHash = _keyHash;

    _safeMint(msg.sender, 1);
  }

  function requestRandomWords() private {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
    reqIdToFromAddress[s_requestId] = payable(ownerOf(0));
  }
  
  function fulfillRandomWords(
    uint256 requestId, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    uint256 s_randomRange = (randomWords[0] % 10000) + 1;
    uint winAmount = 0;

    if (1 <= s_randomRange && s_randomRange <= 2000) {
      winAmount = transferPrice;
    } else if (2001 <= s_randomRange && s_randomRange <= 3001) {
      winAmount = transferPrice * 11 / 10;
    } else if (3002 <= s_randomRange && s_randomRange <= 3502) {
      winAmount = transferPrice * 12 / 10;
    } else if (3503 <= s_randomRange && s_randomRange <= 3703) {
      winAmount = transferPrice * 15 / 10;
    } else if (3704 <= s_randomRange && s_randomRange <= 3804) {
      winAmount = transferPrice * 2;
    } else if (3805 <= s_randomRange && s_randomRange <= 3825) {
      winAmount = transferPrice * 5;
    } else if (3826 <= s_randomRange && s_randomRange <= 3836) {
      winAmount = transferPrice * 10;
    } else if (s_randomRange == 6666) {
      winAmount = address(this).balance / 2;
    }
    
    // need to make sure there is sufficient balance in the contract or this will fail
    if (winAmount > 0) {
      if (winAmount > address(this).balance) {
        winAmount = address(this).balance;
      }
      reqIdToFromAddress[requestId].transfer(winAmount);
      emit Win(
        reqIdToFromAddress[requestId],
        winAmount,
        address(this).balance / 2
      );
    } else {
      emit JackpotBalance(address(this).balance / 2);
    }
  }

  function transferFrom(
      address payable from,
      address to,
      uint256 tokenId
  ) public payable {
      require(msg.value >= transferPrice, "Not enough ETH sent");
      rake.transfer(msg.value * 1 / 10);
      requestRandomWords();
      _transfer(from, to, tokenId);
  }

  function changetransferPrice(uint256 amount) external onlyOwner {
    transferPrice = amount;
  }

  function changeRake(address payable _rake) external onlyOwner {
    rake = _rake;
  }

  function flipPaused() external onlyOwner {
    paused = !paused;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function withdraw() external onlyOwner() {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(address tokenAddress) external onlyOwner() {
    IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
  }
}