// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Pausable.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// ************************ @author: F-Society // ************************ //
/*
MMMMMMMMMMMMMMMMMMMMWWWNX0xl:,'..         ..',:lxOXNWWWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWX0kdl:;,....             ....,;:ldk0XWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMN0dc'.           ..','..           .':d0NMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWXKKNN0o,.            'lxkko;.            'lONNXKXNWMMMMMMMMMMM
MMMMMMMMMMNKxc;ckXNXd,.         .,lO00Odc,.          'oKNXOl;cd0NWMMMMMMMMM
MMMMMMMMNKx:.  .,o0NXkc.       .:xKXOxl;cl;.       .:xKN0d;.  .;d0NWMMMMMMM
MMMMMMWXx:.      .lOXXOl'     .;xXWNkl,.'cl:,.    .cOXX0o'      .;xKWMMMMMM
MMMMMNOl'         .;xXNKx,   .ckXWMNxc'  .;ol'   'o0NXkc.         .ckNMMMMM
MMMWKx:.           .,dKNXd,..:ONMMMNxc'   .:c:,',oKNKx;.           .;xKWMMM
MMW0o'.              .cOXKOxxONMMMMNxc'    .,coxkKX0l'.             .'l0NMM
MN0o'                 .:xKWWWWMMMMMNxc'     .'lOXXOl.                 'o0NM
W0o,.                  .;kNMMMMMMMMNxc'       .lOkc'                   'l0W
Xx,                    .cOWMMMMMMMMNxc'        .:cc,.                   'dK
kc.                   'o0NMMMMMMMMWXxc'         .,ll;.                  .cx
c,.                 .,oKWMMMMMMWWX0d:'.          .;cl:.                  ':
,.                 .:kXWMMMWNKkdl:,.              .,loc'.                .'
..                'ckNWNK0kdl;'.                   .':lc,.                .
..              .'okOOxo:'.                          .;lc,.               .
::;;;;;;;;;;;,,:oxOkl..                              .;oxxo:,,;;;;;;;;;;;::
KK00KKKXXXXXXXKXNNX0d;..                          ..;lkKNNNXXXXXXXXXXKK00KK
OxdoxOKWMMMMMMMMMMWWXKOko;..                   .':dO0KXNWWMMMMMMMMMWXOxodxk
c,...,l0NWMMMMMMMMWWWMMWNKkdc,.             .;oxk00koox0XWMMMMMMMWN0o,...,:
c,.   .ckXMMMMMWX0xdOXWMMMMWX0xl;'.     .,:lxKX0xl;,',:ox0XWMMMMMNkl'   .':
kc.    .:kNWWN0xl;..,oONMMMMMMWNKko:,,;:dO00Oko;...';:,..,cd0XWWNOc.    .:x
Xx'     .:dkko,.     .:kXWMMMMMMMWNXXKKK0kd:'.  .':c;'.    .,lkkd:.     'dK
W0l'      ....        .:xKWMMMMMMMMWXKOo,.     .;loc.        ....      .cOW
WKd;.                .'lOXWMMMMMMMMNko:.      .lOK0d;.                .,o0W
Nk:.              .'cx0XNWMMMMMMMMMNxc'     .,lONMWN0xc'.              .;kN
Nx,             .;okXWMMMMMMMMMMMMMNxc'    .;xKWMMMMMWXOo;.             'xX
W0o,.           'lOWMMMMMMMMMMMMMMMNxc'   'lONMMMMMMMMMW0l'.           'l0W
MWKx;.           'lOXWMMMMMMMMMMMMMNxc' .'oKWMMMMMMMMWXOl,.          .;dKNM
MMWXkl'.          .'lOXWMMMMMMMMMMWXxc,':kXWMMMMMMMWXOl'.          .'ckXWMM
MMMMWKxc;;,,..      .'lOXWMMMMMMMMWXOxdd0NMMMMMMMWXOl,.      ..,,;;:xKNMMMM
MMMMMWNXXKKKOl'.      .'ckXWWMMMMMWWNNNNWMMMMMMWXkc'.      .'lkKKKKXNWMMMMM
MMMMMMMMMMMMWX0dc'.      .;d0NWWMMMMMMMMMMMWWNKx:..     .':dOXWMMMMMMMMMMMM
MMMMMMMMMMMMMMMNKOxl;'.    .,lx0NWMMMMMMMWN0xl;.    ..;ldOKNMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWNKkdl:;,...':d0NWMMMWNKx:'...,;:ldkKNWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMWWNX0xl,. .;d0NMMMWKx:. .,cx0XNWWWMMMMMMMMMMMMMMMMMMMM

#     # ####### #######    #       #######    #    ######  #     # ####### ######   #####
##   ## #          #      # #      #         # #   #     # ##   ## #       #     # #     #
# # # # #          #     #   #     #        #   #  #     # # # # # #       #     # #
#  #  # #####      #    #     #    #####   #     # ######  #  #  # #####   ######   #####
#     # #          #    #######    #       ####### #   #   #     # #       #   #         #
#     # #          #    #     #    #       #     # #    #  #     # #       #    #  #     #
#     # #######    #    #     #    #       #     # #     # #     # ####### #     #  #####
*/
// *************************************************************************** //
contract MetaFarmers is
  ERC721,
  PaymentSplitter,
  Pausable,
  Ownable,
  ReentrancyGuard
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenSupply;
  uint64 public constant MAX_SUPPLY = 3999;
  uint64 public constant RAFFLE_SUPPLY = 399;
  uint64 public publicRedeemedCount;
  uint64 public raffleRedeemedCount;
  uint128 public rafflePrivateRedeemedCount;
  uint128 public whitelistRedeemedCount;
  uint256 public PRICE = 0.17 ether;
  uint256 public RAFFLE_PRICE = 0.15 ether;
  uint256 public constant PRIVATE_RAFFLE_PRICE = 0.15 ether;
  uint256 public constant WHITELIST_PRICE = 0.16 ether;

  mapping(address => uint256) public raffleRedeemed;
  mapping(address => uint256) public privateRaffleRedeemed;
  mapping(address => uint256) public privateRedeemed;
  mapping(address => uint256) public publicRedeemed;

  WorkflowStatus public workflow;

  event RaffleMint(address indexed _minter, uint256 _amount, uint256 _price);
  event PrivateRaffleMint(
    address indexed _minter,
    uint256 _amount,
    uint256 _price
  );
  event PrivateMint(address indexed _minter, uint256 _amount, uint256 _price);
  event PublicMint(address indexed _minter, uint256 _amount, uint256 _price);

  uint256[] private teamShares_ = [80,200,100,100,100, 1000, 100, 133, 133, 134];

  address[] private team_ = [
    0x118aB57514481103D54fBa63a08EdDa2eBE55309,
    0x6110b1BBb5Adb7BA07a137a86C02012F9Af88703,
    0xa5bbE2Cd62e275d4Ecaa9a752783823308ACc4d0,
    0x23C625789c391463997267BDD8b21e5E266014F6,
    0xbFb7aA27c6A7977a65b97b679A68cDDF73b89509,
    0x52f29aEED85B76C8DAc820D397E58f06CBe40Ef9,
    0x8cD6127C34B3AC7749430Ae466a0e8f9ebE0d364,
    0x7B0c2F65A7DC95b11B0b99111192bfddA2F08271,
    0x655d8A60345188b2C94d543dE4eafF58905A40fD,
    0xD7E39C749A9c34bff1Dac37b4681B9636F87Ff9A
  ];

  enum WorkflowStatus {
    Before,
    Raffle,
    PrivateRaffle,
    Presale,
    Sale,
    SoldOut,
    Reveal
  }

  bool public revealed;
  string public baseURI;
  string public notRevealedUri;

  bytes32 public raffleWhitelist;
  bytes32 public privateWhitelist;

  constructor(
    string memory _initNotRevealedUri,
    bytes32 _raffleWhitelist,
    bytes32 _privateWhitelist
  ) ERC721("Meta-Farmers", "JC") PaymentSplitter(team_, teamShares_) {
    transferOwnership(msg.sender);
    revealed = false;
    workflow = WorkflowStatus.Before;
    setNotRevealedURI(_initNotRevealedUri);
    raffleWhitelist = _raffleWhitelist;
    privateWhitelist = _privateWhitelist;
  }

  function redeemRaffle(uint64 amount, bytes32[] calldata proof)
    external
    payable
    whenNotPaused
  {
    require(workflow == WorkflowStatus.Raffle, "Raffle sale has ended");

    bool isOnWhitelist = _verifyRaffle(_leaf(msg.sender, 1), proof);
    require(
      isOnWhitelist,
      "address not verified on the raffle winners whitelist"
    );
    require(
      RAFFLE_SUPPLY >= raffleRedeemedCount + amount,
      "cannot mint tokens. will go over raffle supply limit"
    );

    uint256 price = RAFFLE_PRICE;
    uint256 max = MAX_SUPPLY;
    uint256 maxAmount = 5;
    uint256 currentSupply = _tokenSupply.current();
    uint256 alreadyRedeemed = raffleRedeemed[msg.sender];
    uint256 supply = currentSupply + amount;

    require(supply <= max, "Sold out !");
    require(
      alreadyRedeemed + amount <= maxAmount,
      "tokens minted will go over user limit"
    );
    require(price * amount <= msg.value, "Meta-Farmers: Insuficient funds");

    emit RaffleMint(msg.sender, amount, price);

    raffleRedeemed[msg.sender] = raffleRedeemed[msg.sender] + amount;
    for (uint256 i = 0; i < amount; i++) {
      raffleRedeemedCount = raffleRedeemedCount++;
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }

  function redeemPrivateRaffle(uint64 amount, bytes32[] calldata proof)
    external
    payable
    whenNotPaused
  {
    require(workflow == WorkflowStatus.PrivateRaffle, "Raffle sale has ended");

    bool isOnWhitelist = _verifyRaffle(_leaf(msg.sender, 1), proof);
    require(
      isOnWhitelist,
      "address not verified on the raffle winners whitelist"
    );

    uint256 price = RAFFLE_PRICE;
    uint256 max = MAX_SUPPLY;
    uint256 maxAmount = 5;
    uint256 alreadyRedeemed = privateRaffleRedeemed[msg.sender];
    uint256 currentSupply = _tokenSupply.current();
    uint256 supply = currentSupply + amount;

    require(supply <= max, "Sold out !");
    require(
      alreadyRedeemed + amount <= maxAmount,
      "tokens minted will go over user limit"
    );
    require(price * amount <= msg.value, "Meta-Farmers: Insuficient funds");

    emit PrivateRaffleMint(msg.sender, amount, price);

    privateRaffleRedeemed[msg.sender] =
      privateRaffleRedeemed[msg.sender] +
      amount;
    for (uint256 i = 0; i < amount; i++) {
      rafflePrivateRedeemedCount = rafflePrivateRedeemedCount++;
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }

  function redeemPrivateSale(uint64 amount, bytes32[] calldata proof)
    external
    payable
    whenNotPaused
  {
    require(amount > 0, "need to mint at least one token");
    require(workflow != WorkflowStatus.SoldOut, "Meta-Farmers: SOLD OUT!");
    require(
      workflow == WorkflowStatus.Presale,
      "Meta-Farmers: private sale is not started yet"
    );

    bool isOnWhitelist = _verifyPrivate(_leaf(msg.sender, 1), proof);
    require(
      isOnWhitelist,
      "address not verified on the private sale whitelist"
    );

    uint256 price = WHITELIST_PRICE;
    uint256 maxAmount = 5;
    uint256 alreadyRedeemed = privateRedeemed[msg.sender];
    uint256 currentSupply = _tokenSupply.current();
    uint256 supply = currentSupply + amount;

    require(
      alreadyRedeemed + amount <= maxAmount,
      "Meta-Farmers: You can't mint more than 5 tokens!"
    );
    require(supply <= MAX_SUPPLY, "Sold out !");
    require(price * amount <= msg.value, "Meta-Farmers: Insuficient funds");

    whitelistRedeemedCount = whitelistRedeemedCount + amount;
    emit PrivateMint(msg.sender, amount, price);

    uint256 initial = 1;
    uint256 condition = amount;
    if (currentSupply == MAX_SUPPLY) {
      workflow = WorkflowStatus.SoldOut;
    }
    privateRedeemed[msg.sender] = privateRedeemed[msg.sender] + condition;
    for (uint256 i = initial; i <= condition; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }

  function publicSaleMint(uint64 amount)
    external
    payable
    nonReentrant
    whenNotPaused
  {
    require(amount > 0, "need to mint at least one token");
    require(workflow != WorkflowStatus.SoldOut, "Meta-Farmers: SOLD OUT!");
    require(
      workflow == WorkflowStatus.Sale,
      "Meta-Farmers: public sale is not started yet"
    );

    uint256 price = PRICE;
    uint256 maxAmount = 10;
    uint256 alreadyRedeemed = publicRedeemed[msg.sender];
    uint256 currentSupply = _tokenSupply.current();
    uint256 supply = currentSupply + amount;
    require(
      alreadyRedeemed + amount <= maxAmount,
      "Meta-Farmers: You can't mint more than 5 tokens!"
    );
    require(supply <= MAX_SUPPLY, "Meta-Farmers: Sold out !");
    require(price * amount <= msg.value, "Meta-Farmers: Insuficient funds");

    publicRedeemedCount = publicRedeemedCount + amount;
    emit PublicMint(msg.sender, amount, price);

    uint256 initial = 1;
    uint256 condition = amount;
    if (currentSupply + amount == MAX_SUPPLY) {
      workflow = WorkflowStatus.SoldOut;
    }
    publicRedeemed[msg.sender] = publicRedeemed[msg.sender] + condition;
    for (uint256 i = initial; i <= condition; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }

  function gift(uint64 _mintAmount) public onlyOwner {
    require(_mintAmount > 0, "Meta-Farmers: need to mint at least 1 NFT");

    uint256 currentSupply = _tokenSupply.current();
    uint256 supply = currentSupply + _mintAmount;
    require(supply <= MAX_SUPPLY, "Meta-Farmers: Sold out !");

    uint256 condition = _mintAmount;
    if (currentSupply + _mintAmount == MAX_SUPPLY) {
      workflow = WorkflowStatus.SoldOut;
    }

    for (uint256 i = 1; i <= condition; i++) {
      _tokenSupply.increment();
      _safeMint(msg.sender, _tokenSupply.current());
    }
  }

  function giveaway(address[] memory giveawayAddressTable) public onlyOwner {
    uint256 _mintAmount = giveawayAddressTable.length;
    require(giveawayAddressTable.length > 0, "Meta-Farmers:at least 1 NFT");

    uint256 currentSupply = _tokenSupply.current();
    uint256 supply = currentSupply + _mintAmount;
    require(supply <= MAX_SUPPLY, "Meta-Farmers: Sold out !");

    if (currentSupply + _mintAmount == MAX_SUPPLY) {
      workflow = WorkflowStatus.SoldOut;
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _tokenSupply.increment();
      _safeMint(giveawayAddressTable[i], _tokenSupply.current());
    }
  }

  /***************************
   * Owner Protected Functions
   ***************************/

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function totalSupply() external view returns (uint256) {
    uint256 supply = _tokenSupply.current();
    return supply;
  }

  function setRaffleWhitelist(bytes32 whitelist_) public onlyOwner {
    raffleWhitelist = whitelist_;
  }

  function setprivateWhitelist(bytes32 whitelist_) public onlyOwner {
    privateWhitelist = whitelist_;
  }

  function setRaffleSaleEnabled() public onlyOwner {
    workflow = WorkflowStatus.Raffle;
  }

  function setPrivateRaffleSaleEnabled() public onlyOwner {
    workflow = WorkflowStatus.PrivateRaffle;
  }

  function setPrivateSaleEnabled() public onlyOwner {
    workflow = WorkflowStatus.Presale;
  }

  function setPublicSaleEnabled() public onlyOwner {
    workflow = WorkflowStatus.Sale;
  }

  function getWorkflowStatus() public view returns (WorkflowStatus) {
    return workflow;
  }

  function _leaf(address account, uint256 amount)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(account, amount));
  }

  function _verifyRaffle(bytes32 leaf, bytes32[] memory proof)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, raffleWhitelist, leaf);
  }

  function _verifyPrivate(bytes32 leaf, bytes32[] memory proof)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, privateWhitelist, leaf);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /*************************************************************
   * The following functions are overrides required by Solidity.
   *************************************************************/

  function _toString(uint256 v) internal pure returns (string memory str) {
    if (v == 0) {
      return "0";
    }
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;
    while (v != 0) {
      uint256 remainder = v % 10;
      v = v / 10;
      reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i);
    for (uint256 j = 0; j < i; j++) {
      s[j] = reversed[i - 1 - j];
    }
    str = string(s);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    if (revealed == false) {
      return notRevealedUri;
    }

    string memory currentBaseURI = baseURI;
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId)))
        : "";
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setPrice(uint256 _price) public onlyOwner {
    PRICE = _price;
  }

  function setPrivatePrice(uint256 _price) public onlyOwner {
    RAFFLE_PRICE = _price;
  }

  function reveal(string memory revealedBaseURI) public onlyOwner {
    baseURI = revealedBaseURI;
    revealed = true;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
}
