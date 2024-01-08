// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./Initializable.sol";
import "./draft-EIP712.sol";
import "./IERC721.sol";

import "./NamelessToken.sol";
import "./LazyShoeDistribution.sol";

contract NFTLandSales is EIP712, AccessControl, Initializable  {
  using LazyShoeDistribution for LazyShoeDistribution.Shoe;

  address payable public benefactor;
  string public name;

  event TokenPurchased(uint index, address buyer);

  bool public pubsaleActive;
  NamelessToken public tokenContract;

  struct PresaleConfigInput {
    uint    maxSell;    
    address ticketSigner;
  }

  struct PresaleTierConfigInput {
    uint    tier;
    uint    maxSell;    
  }

  struct PresaleConfig {
    uint    maxSell;
    address ticketSigner;
    mapping(uint => uint) maxSellByTier;
  }

  struct PresaleState {
    bool    active;
    uint    numSold;
    mapping(uint => uint) numSoldByTier;
  }

  struct TierConfig {
    uint price;
    uint firstTokenId;
    uint numTokens;
  }

  mapping(uint => uint) public numSoldByTier;
  mapping(uint => TierConfig) public tierConfigByTier;
  mapping(string => PresaleConfig) public presaleConfigByTicketId;
  mapping(string => PresaleState) public presaleStateByTicketId;

  mapping(uint => LazyShoeDistribution.Shoe) private shoeByTier;

  function initialize(string memory _name, NamelessToken _tokenContract, address initialAdmin) public initializer {
    name = _name;
    benefactor = payable(initialAdmin);
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);

    pubsaleActive = false;
    tokenContract = _tokenContract;
  }

  constructor(string memory _name, string memory _domain, string memory _version, NamelessToken _tokenContract) EIP712(_domain, _version) {
    initialize(_name, _tokenContract, msg.sender);
  }

  function configureTier(uint tier, uint numTokens, uint firstTokenId, uint initialPrice ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(tierConfigByTier[tier].numTokens == 0, 'tier already configured');
    require(numSoldByTier[tier] == 0, 'tier already sold');
    tierConfigByTier[tier] = TierConfig(
      initialPrice,
      firstTokenId,
      numTokens
    );
    shoeByTier[tier].size = numTokens;
  }

  function configurePresale(string calldata ticket, address ticketSigner, uint maxSell, PresaleTierConfigInput[] calldata tierConfigs ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(presaleConfigByTicketId[ticket].maxSell == 0, 'presale already configured');
    presaleConfigByTicketId[ticket].ticketSigner = ticketSigner;
    presaleConfigByTicketId[ticket].maxSell = maxSell;
    presaleStateByTicketId[ticket].active = false;
    for (uint i = 0; i < tierConfigs.length; i++) {
      PresaleTierConfigInput calldata config = tierConfigs[i];
      presaleConfigByTicketId[ticket].maxSellByTier[config.tier] = config.maxSell;
    }
  }

  function setTierPrice(uint tier, uint newPrice ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(tierConfigByTier[tier].numTokens != 0, 'tier not configured');
    tierConfigByTier[tier].price = newPrice;
  }

  function pickTokenId(uint tier) internal returns (uint) {
    uint random = uint256(keccak256(abi.encodePacked(msg.sender, shoeByTier[tier].size, block.difficulty, block.timestamp, block.number, blockhash(block.number - 1))));
    uint result = shoeByTier[tier].pop(random);
    numSoldByTier[tier] += 1;
    return tierConfigByTier[tier].firstTokenId + result - 1;
  }

  function buyPresale(uint tier, uint quantity, string calldata ticket, bytes calldata signature) external payable {
    PresaleConfig storage presaleConfig = presaleConfigByTicketId[ticket];
    PresaleState storage presaleState = presaleStateByTicketId[ticket];
    TierConfig storage tierConfig = tierConfigByTier[tier];

    require(quantity <= 5 && quantity > 0, 'invalid quantity');
    require(presaleState.active, 'sale not started');
    
    require(tierConfig.numTokens != 0, 'tier not available');
    require(tierConfig.price * quantity == msg.value, 'wrong price');
    require(numSoldByTier[tier] + quantity <= tierConfig.numTokens, 'Tier Sold out');
    
    require(presaleState.numSold + quantity <= presaleConfig.maxSell, 'Presale Sold out');
    require(presaleState.numSoldByTier[tier] + quantity <= presaleConfig.maxSellByTier[tier], 'Presale Tier Sold out');

    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        keccak256("Ticket(address wallet,string ticket)"),
        msg.sender,
        keccak256(bytes(ticket))
    )));
    address signer = ECDSA.recover(digest, signature);
    require(signer == presaleConfig.ticketSigner, 'invalid ticket');

    presaleState.numSold += quantity;
    presaleState.numSoldByTier[tier] += quantity;

    for (uint idx = 0; idx < quantity; idx++) {
      uint tokenId = pickTokenId(tier);
      tokenContract.mint(msg.sender, tokenId);
      emit TokenPurchased(tokenId, msg.sender);
    }
  }

  function buy(uint tier, uint quantity) external payable {
    TierConfig storage tierConfig = tierConfigByTier[tier];

    require(quantity <= 5 && quantity > 0, 'invalid quantity');
    require(pubsaleActive, 'sale not started');
    require(tierConfig.price * quantity == msg.value, 'wrong price');
    require(numSoldByTier[tier] + quantity <= tierConfig.numTokens, 'Sold out');

    for (uint idx = 0; idx < quantity; idx++) {
      uint tokenId = pickTokenId(tier);
      tokenContract.mint(msg.sender, tokenId);
      emit TokenPurchased(tokenId, msg.sender);
    }
  }

  function buyAdmin(uint tier, uint quantity, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE)  {
    TierConfig storage tierConfig = tierConfigByTier[tier];
    require(numSoldByTier[tier] + quantity <= tierConfig.numTokens, 'Not Enough Tokens');

    for (uint idx = 0; idx < quantity; idx++) {
      uint tokenId = pickTokenId(tier);
      tokenContract.mint(recipient, tokenId);
      emit TokenPurchased(tokenId, recipient);
    }
  }

  function setPresaleActive(string calldata ticket, bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    presaleStateByTicketId[ticket].active = active;
  }

  function setPubsaleActive(bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    pubsaleActive = active;
  }

  function remainingPubsale(uint tier) public view returns (uint) {
    TierConfig storage tierConfig = tierConfigByTier[tier];
    return tierConfig.numTokens - numSoldByTier[tier];
  }

  function remainingPresale(string memory ticket, uint tier) public view returns (uint) {
    uint remaining = remainingPubsale(tier);
    
    PresaleConfig storage presaleConfig = presaleConfigByTicketId[ticket];
    PresaleState storage presaleState = presaleStateByTicketId[ticket];
    uint presaleRemaining = presaleConfig.maxSellByTier[tier] - presaleState.numSoldByTier[tier];
    
    return remaining < presaleRemaining ? remaining : presaleRemaining;
  }

  function withdraw() public {
    require(msg.sender == benefactor || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'not authorized');
    uint amount = address(this).balance;
    require(amount > 0, 'no balance');

    Address.sendValue(benefactor, amount);
  }

  function setBenefactor(address payable newBenefactor, bool sendBalance) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(benefactor != newBenefactor, 'already set');
    uint amount = address(this).balance;
    address payable oldBenefactor = benefactor;
    benefactor = newBenefactor;

    if (sendBalance && amount > 0) {
      Address.sendValue(oldBenefactor, amount);
    }
  }
}
