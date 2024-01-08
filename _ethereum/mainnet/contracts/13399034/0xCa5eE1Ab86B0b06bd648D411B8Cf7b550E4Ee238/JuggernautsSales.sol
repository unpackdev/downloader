// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./Initializable.sol";
import "./draft-EIP712.sol";

import "./NamelessToken.sol";
import "./LazyShoeDistribution.sol";

contract JuggernautsSales is EIP712, AccessControl, Initializable  {
  using LazyShoeDistribution for LazyShoeDistribution.Shoe;

  address payable public benefactor;
  string public name;

  event TokenPurchased(uint index, address buyer);

  struct Stats {
    uint32 numSold;
    uint32 maxPresale;
    uint32 maxPubsale;
  }

  mapping(uint => Stats) public statsByTier;
  mapping(uint => mapping(uint => uint )) public priceByTierQuantity;
  bool public presaleActive;
  bool public pubsaleActive;
  address public ticketSigner;
  NamelessToken public tokenContract;

  mapping(uint => LazyShoeDistribution.Shoe) private shoeByTier;
  mapping(uint => uint) private firstTokenIdByTier;

  function initialize(string memory _name, NamelessToken _tokenContract, address _ticketSigner, address initialAdmin) public initializer {
    name = _name;
    benefactor = payable(initialAdmin);
    _setupRole(DEFAULT_ADMIN_ROLE, initialAdmin);

    statsByTier[1] = Stats(0, 300,  888 - 220);
    statsByTier[2] = Stats(0, 1500, 3552 - 488);
    statsByTier[3] = Stats(0, 2000, 4360 - 588);
    priceByTierQuantity[1][1] = 880000000 gwei;
    priceByTierQuantity[2][1] = 660000000 gwei;
    priceByTierQuantity[3][1] = 180000000 gwei;
    priceByTierQuantity[1][4] = 3000000000 gwei;
    priceByTierQuantity[2][4] = 2000000000 gwei;

    presaleActive = false;
    pubsaleActive = false;
    tokenContract = _tokenContract;
    ticketSigner = _ticketSigner;

    shoeByTier[1].size = statsByTier[1].maxPubsale;
    shoeByTier[2].size = statsByTier[2].maxPubsale;
    shoeByTier[3].size = statsByTier[3].maxPubsale;

    firstTokenIdByTier[1] = 100089;
    firstTokenIdByTier[2] = 100977;
    firstTokenIdByTier[3] = 104529;
  }

  constructor(string memory _name, string memory _domain, string memory _version, NamelessToken _tokenContract, address _ticketSigner) EIP712(_domain, _version) {
    initialize(_name, _tokenContract, _ticketSigner, msg.sender);
  }

  function pickTokenId(uint tier) internal returns (uint) {
    uint random = uint256(keccak256(abi.encodePacked(msg.sender, shoeByTier[tier].size, block.difficulty, block.timestamp, block.number, blockhash(block.number - 1))));
    uint result = shoeByTier[tier].pop(random);
    statsByTier[tier].numSold += 1;
    return firstTokenIdByTier[tier] + result - 1;
  }

  function buyPresale(uint tier, uint quantity, string calldata ticket, bytes calldata signature) external payable {
    require(presaleActive, 'sale not started');
    require(tier > 0 && tier <= 3, 'tier not for sale');
    if (tier == 3) {
      require(quantity == 1, 'only singles');
    } else {
      require(quantity == 1 || quantity == 4, 'only singles or 4 packs');
    }
    require(priceByTierQuantity[tier][quantity] == msg.value, 'wrong price');
    require(statsByTier[tier].numSold + quantity <= statsByTier[tier].maxPresale, 'Sold out of presale');


    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
        keccak256("Ticket(address wallet,string ticket)"),
        msg.sender,
        keccak256(bytes(ticket))
    )));
    address signer = ECDSA.recover(digest, signature);
    require(signer == ticketSigner, 'invalid ticket');

    for (uint i = 0; i < quantity; i++) {
      uint tokenId = pickTokenId(tier);
      tokenContract.mint(msg.sender, tokenId);
      emit TokenPurchased(tokenId, msg.sender);
    }
  }

  function buy(uint tier, uint quantity) external payable {
    require(pubsaleActive, 'sale not started');
    require(tier > 0 && tier <= 3, 'tier not for sale');
    if (tier == 3) {
      require(quantity == 1, 'only singles');
    } else {
      require(quantity == 1 || quantity == 4, 'only singles or 4 packs');
    }
    require(priceByTierQuantity[tier][quantity] == msg.value, 'wrong price');
    require(statsByTier[tier].numSold + quantity <= statsByTier[tier].maxPubsale, 'Sold out');

    for (uint i = 0; i < quantity; i++) {
      uint tokenId = pickTokenId(tier);
      tokenContract.mint(msg.sender, tokenId);
      emit TokenPurchased(tokenId, msg.sender);
    }
  }

  function setPresaleActive(bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    presaleActive = active;
  }

  function setPubsaleActive(bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
    pubsaleActive = active;
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
