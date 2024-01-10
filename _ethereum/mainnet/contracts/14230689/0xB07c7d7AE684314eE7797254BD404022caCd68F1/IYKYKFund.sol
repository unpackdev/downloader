// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./ERC1155Holder.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IIYKYKERC1155.sol";


contract IYKYKFund is Ownable, ReentrancyGuard, ERC1155Holder {

  IIYKYKERC1155 public token;

  uint256 public salesEndPeriod;
  uint256 public tokenPrice;
  
  uint256 public totalTokensMinted = 0;
  uint16 public constant TOKEN_ID = 0;
  uint16 public constant MAX_TOTAL_TOKEN = 1000;
  bytes32 whiteslitedAddressesMerkleRoot = 0x00;
  bool public isWhitelistingEnabled = true;



  event BuyToken(
    address indexed user, 
    uint256 etherToRefund,
    uint256 etherUsed,
    uint256 etherSent,
    uint256 timestamp
  );  

  event Withdraw(
    address indexed user, 
    uint256 amount,
    uint256 timestamp
  );  

  event UpdateSalesEndPeriod(
    uint256 indexed newSalesEndPeriod, 
    uint256 timestamp
  );  

  event UpdateMerkleRoot(
    bytes32 indexed newRoot, 
    uint256 timestamp
  );  

  constructor(address erc1155Token_, uint256 salesEndPeriod_, uint256 tokenPrice_) {
    require(erc1155Token_ != address(0), "Not a valid token address");
    require(tokenPrice_ > 0, "Token Price must be greater than zero");
    require(salesEndPeriod_ > block.timestamp, "Distribution date is in the past");

    token = IIYKYKERC1155(erc1155Token_);
    salesEndPeriod = salesEndPeriod_;
    tokenPrice = tokenPrice_;
  }

  receive() external payable {
    revert();
  }

  function buyToken(bytes32[] memory proof) external payable nonReentrant {
    require(block.timestamp <= salesEndPeriod, "Token sale period have ended");
    require(msg.value >= tokenPrice, "Price must be greater than or equal to the token price");
    require(totalTokensMinted < MAX_TOTAL_TOKEN, "Contract have reached the max NFT mint");

    if (isWhitelistingEnabled) {
      require(proof.length > 0, "Proof length can not be zero");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      bool iswhitelisted = verifyProof(leaf, proof);
      require(iswhitelisted, "User not whitelisted");
    } 

    uint256 numOfTokenPerPrice = msg.value / tokenPrice; 

    uint256 numOfEligibleTokenToPurchase = MAX_TOTAL_TOKEN - totalTokensMinted;

    uint256 numOfTokenPurchased = (numOfTokenPerPrice + totalTokensMinted) > MAX_TOTAL_TOKEN ? numOfEligibleTokenToPurchase : numOfTokenPerPrice;
        
    uint256 totalEtherUsed = numOfTokenPurchased * tokenPrice;

    totalTokensMinted += numOfTokenPurchased;
    
    // calculate and transfer the remaining ether balance
    uint256 etherToRefund = _transferBalance(msg.value, payable(msg.sender), totalEtherUsed);


    // MINT NFT;
    token.mint(msg.sender, TOKEN_ID, numOfTokenPurchased, "0x0");

    emit BuyToken(msg.sender, etherToRefund, totalEtherUsed, msg.value, block.timestamp);
  }

  function _transferBalance(uint256 totalEtherUserSent, address payable user, uint256 totalEtherUsedByContract) internal returns(uint256) {
    uint256 balance = 0;
    if (totalEtherUserSent > totalEtherUsedByContract) {
      balance = totalEtherUserSent - totalEtherUsedByContract;
      (bool sent, ) = user.call{value: balance}("");
      require(sent, "Failed to send remaining Ether balance");
    } 
    return balance;
  }

  function verifyProof(bytes32 leaf, bytes32[] memory proof) public view returns (bool) {

    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    return computedHash == whiteslitedAddressesMerkleRoot;
  }

  function withdrawEther(address payable receiver) external onlyOwner nonReentrant {
    require(receiver != address(0), "Not a valid address");
    require(address(this).balance > 0, "Contract have zero balance");

    (bool sent, ) = receiver.call{value: address(this).balance}("");
    require(sent, "Failed to send ether");
    emit Withdraw(receiver, address(this).balance, block.timestamp);
  }

  function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
    require(newMerkleRoot.length > 0, "New merkle tree is empty");
    whiteslitedAddressesMerkleRoot = newMerkleRoot;
    emit UpdateMerkleRoot(newMerkleRoot, block.timestamp);
  } 

  function updateSalesEndPeriod(uint256 newSalesEndPeriod) external onlyOwner{
    require(newSalesEndPeriod > block.timestamp, "New sale end period is in the past");
    salesEndPeriod = newSalesEndPeriod;
    emit UpdateSalesEndPeriod(newSalesEndPeriod, block.timestamp);
  } 

  function toggleWhitelist() external onlyOwner {
    isWhitelistingEnabled = !isWhitelistingEnabled;
  }


}