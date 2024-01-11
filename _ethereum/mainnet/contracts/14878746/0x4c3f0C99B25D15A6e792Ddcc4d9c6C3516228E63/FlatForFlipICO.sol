// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./IFlatForFlipERC721A.sol";


contract FlatForFlipICO is Ownable, PaymentSplitter, ReentrancyGuard {
  uint8 public constant MAX_TOKEN_PER_ACCOUNT = 10;

  IFlatForFlipERC721A public erc721AToken;

  struct ContractData { 
    uint256 erc721ATokenPrice;
    bytes32 whiteslitedAddressesMerkleRoot;
    bool    whitelistingEnabled;
  } 

  ContractData public contractData;

  event BuyToken(
    address indexed user, 
    uint256 etherToRefund,
    uint256 etherUsed,
    uint256 etherSent
  );  

  event DelegatePurchase(
    address[] indexed users, 
    uint256[] quantities
  );  

  event Withdraw(
    address indexed user, 
    uint256 amount
  );  

  event UpdateMerkleRoot(
    bytes32 indexed newRoot
  );  

  event UpdateTokenPrice(
    uint256 newTokenPrice 
  );  

  constructor (
    ContractData memory params, 
    address erc721ATokenAddress, 
    address[] memory _payees, 
    uint256[] memory _shares
  ) PaymentSplitter (_payees, _shares) {

    require(erc721ATokenAddress != address(0), "Not a valid token address");
    require(params.erc721ATokenPrice > 0, "Token Price can not be equal to zero");

    erc721AToken = IFlatForFlipERC721A(erc721ATokenAddress);

    contractData = ContractData(params.erc721ATokenPrice, params.whiteslitedAddressesMerkleRoot, params.whitelistingEnabled);
  } 

  receive() external payable virtual override {
    revert();
  }

  function buyToken(bytes32[] memory proof) external payable nonReentrant {

    uint256 salesEndPeriod = erc721AToken.salesEndPeriod();

    require(block.timestamp <= salesEndPeriod, "Token sale period have ended");
    require(msg.value >= contractData.erc721ATokenPrice, "Price must be greather than or equal to the token price");

    uint256 balance = erc721AToken.balanceOf(msg.sender);

    require(balance < MAX_TOKEN_PER_ACCOUNT, "Receiver have reached the allocated limit");

    if (contractData.whitelistingEnabled) {
      require(proof.length > 0, "Proof length can not be zero");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      bool iswhitelisted = verifyProof(leaf, proof);
      require(iswhitelisted, "User not whitelisted");
    } 

    uint256 numOfTokenPerPrice = msg.value / contractData.erc721ATokenPrice;

    uint256 numOfEligibleTokenToPurchase = MAX_TOKEN_PER_ACCOUNT - balance;
    uint256 numOfTokenPurchased = numOfTokenPerPrice > numOfEligibleTokenToPurchase ? numOfEligibleTokenToPurchase : numOfTokenPerPrice;
        
    require((balance + numOfTokenPurchased) <= MAX_TOKEN_PER_ACCOUNT, "Receiver total erc721AToken plus the erc721AToken you want to purchase exceed your limit");

    uint256 totalEtherUsed = numOfTokenPurchased * contractData.erc721ATokenPrice;

    // calculate and send the remaining ether balance
    uint256 etherToRefund = _transferBalance(msg.value, payable(msg.sender), totalEtherUsed);

    erc721AToken.safeMint(msg.sender, numOfTokenPurchased);
    
    emit BuyToken(msg.sender, etherToRefund, totalEtherUsed, msg.value);
  }

  function delegatePurchase(address[] memory users, uint256[] memory quantities) external onlyOwner nonReentrant{
    require(users.length == quantities.length, "users and quantities length mismatch");

    for (uint256 i = 0; i < users.length; i++) {

      address user = users[i];
      uint256 quantityPerUser = quantities[i];

      // MINT NFT;
      erc721AToken.safeMint(user, quantityPerUser);
 
    }
    emit DelegatePurchase(users, quantities);

  }

  function _transferBalance(uint256 totalEtherSpent, address payable user, uint256 totalEtherUsed) internal returns(uint256) {
    uint256 balance = 0;
    if (totalEtherSpent > totalEtherUsed) {
      balance = totalEtherSpent - totalEtherUsed;
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

    return computedHash == contractData.whiteslitedAddressesMerkleRoot;
  }

  function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
    require(newMerkleRoot.length > 0, "New merkle tree is empty");
    contractData.whiteslitedAddressesMerkleRoot = newMerkleRoot;
    emit UpdateMerkleRoot(newMerkleRoot);
  } 

  function updateTokenPrice(uint256 newTokenPrice) external onlyOwner{
    require(newTokenPrice > 0, "New token price can not be 0");
    contractData.erc721ATokenPrice = newTokenPrice;
    emit UpdateTokenPrice(newTokenPrice);
  } 

  function switchOnOrOffWhitelisting() external onlyOwner {
    contractData.whitelistingEnabled = !contractData.whitelistingEnabled;
  }

}