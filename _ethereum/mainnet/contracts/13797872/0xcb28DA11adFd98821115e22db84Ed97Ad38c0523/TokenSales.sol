// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./Initializable.sol";
import "./draft-EIP712.sol";
import "./IERC721.sol";

import "./NamelessToken.sol";

contract TokenSales is EIP712, AccessControl, Initializable  {
  address payable public benefactor;
  string public name;

  event TokenPurchased(uint index, address buyer);

  NamelessToken public tokenContract;

  struct SaleConfigInput {
    uint    maxSell;    
    address ticketSigner;
  }

  struct SaleTierConfigInput {
    uint    tier;
    uint    maxSell;    
  }

  struct SaleConfig {
    uint    maxSell;
    address ticketSigner;
    mapping(uint => uint) maxSellByTier;
  }

  struct SaleState {
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
  mapping(string => SaleConfig) public saleConfigByTicketId;
  mapping(string => SaleState) public saleStateByTicketId;

  function initialize(string memory _name, NamelessToken _tokenContract, address initialAdmin) public initializer {
    name = _name;
    benefactor = payable(initialAdmin);
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);

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
  }

  function configureSale(string calldata ticket, address ticketSigner, uint maxSell, SaleTierConfigInput[] calldata tierConfigs ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(saleConfigByTicketId[ticket].maxSell == 0, 'sale already configured');
    saleConfigByTicketId[ticket].ticketSigner = ticketSigner;
    saleConfigByTicketId[ticket].maxSell = maxSell;
    saleStateByTicketId[ticket].active = false;
    for (uint i = 0; i < tierConfigs.length; i++) {
      SaleTierConfigInput calldata config = tierConfigs[i];
      saleConfigByTicketId[ticket].maxSellByTier[config.tier] = config.maxSell;
    }
  }

  function setTierPrice(uint tier, uint newPrice ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(tierConfigByTier[tier].numTokens != 0, 'tier not configured');
    tierConfigByTier[tier].price = newPrice;
  }

  function totalPrice(uint[] memory tiers) internal view returns (uint) {
    uint total = 0;
    for (uint tierIdx = 0; tierIdx < tiers.length; tierIdx++) {
      uint tier = tiers[tierIdx];
      TierConfig storage tierConfig = tierConfigByTier[tier];
      total += tierConfig.price;
    }

    return total;
  }

  function buy(uint[] memory tiers, string calldata ticket, bytes calldata signature) external payable {
    SaleConfig storage saleConfig = saleConfigByTicketId[ticket];
    SaleState storage saleState = saleStateByTicketId[ticket];

    uint quantity = tiers.length;

    require(saleState.active, 'sale not started');
    require(quantity > 0 && quantity <= 2, 'Invalid Quantity');
    require(totalPrice(tiers) == msg.value, 'wrong price');
    require(saleState.numSold + quantity <= saleConfig.maxSell, 'Not enough for sale');

    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        keccak256("Ticket(address wallet,string ticket)"),
        msg.sender,
        keccak256(bytes(ticket))
    )));
    address signer = ECDSA.recover(digest, signature);
    require(signer == saleConfig.ticketSigner, 'invalid ticket');


    for (uint tierIdx = 0; tierIdx < tiers.length; tierIdx++) {
      uint tier = tiers[tierIdx];
      TierConfig storage tierConfig = tierConfigByTier[tier];

      require(tierConfig.numTokens != 0, 'tier not available');
      require(numSoldByTier[tier] + 1 <= tierConfig.numTokens, 'Tier Sold out');
      require(saleState.numSoldByTier[tier] + 1 <= saleConfig.maxSellByTier[tier], 'Sale Tier Sold out');

      saleState.numSold += 1;
      saleState.numSoldByTier[tier] += 1;

      uint tokenId = tierConfig.firstTokenId + numSoldByTier[tier]++;
      tokenContract.mint(msg.sender, tokenId);
      emit TokenPurchased(tokenId, msg.sender);
    }
  }

  function buyAdmin(uint tier, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE)  {
    TierConfig storage tierConfig = tierConfigByTier[tier];
    require(numSoldByTier[tier] + 1 <= tierConfig.numTokens, 'Not Enough Tokens');

    uint tokenId = tierConfig.firstTokenId + numSoldByTier[tier]++;
    tokenContract.mint(recipient, tokenId);
    emit TokenPurchased(tokenId, recipient);
  }

  function setSaleActive(string calldata ticket, bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    saleStateByTicketId[ticket].active = active;
  }

  function remainingGlobal(uint tier) public view returns (uint) {
    TierConfig storage tierConfig = tierConfigByTier[tier];
    return tierConfig.numTokens - numSoldByTier[tier];
  }

  function remainingSale(string memory ticket, uint tier) public view returns (uint) {
    uint remaining = remainingGlobal(tier);
    
    SaleConfig storage saleConfig = saleConfigByTicketId[ticket];
    SaleState storage saleState = saleStateByTicketId[ticket];
    uint saleRemaining = saleConfig.maxSellByTier[tier] - saleState.numSoldByTier[tier];
    
    return remaining < saleRemaining ? remaining : saleRemaining;
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
