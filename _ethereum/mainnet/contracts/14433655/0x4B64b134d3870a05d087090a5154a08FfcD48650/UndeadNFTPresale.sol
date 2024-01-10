// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "./OwnableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IMultiMintNFT {
  function multipleMint(
    address toAddr,
    uint256 from,
    uint256 to,
    uint256 pkgId
  ) external;
}

contract UndeadNFTPresale is
  OwnableUpgradeable,
  EIP712Upgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable
{
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  address public nft;
  struct Record {
    address wallet;
    uint256 totalPrice;
    uint256 weapon;
    uint256 from;
    uint256 to;
    bool wl;
    uint256 created;
  }

  mapping(uint256 => uint256) public saleByWeapon;
  mapping(address => uint256) public saleByAddress;
  mapping(address => bool) public blacklist;
  mapping(uint256 => uint256) public price;
  uint256 public claimTime;

  Record[] public records;

  function __UndeadNFTPresale_init(address n) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __AccessControl_init();
    __EIP712_init("UndeadNFTPresale712", "1.0.0");
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    nft = n;
  }

  function updateNFT(address n) external onlyOwner {
    nft = n;
  }

  function updatePrice(
    uint256 amateurPrice,
    uint256 survivorPrice,
    uint256 assassinPrice,
    uint256 zombieKillerPrice
  ) external onlyOwner {
    price[0] = amateurPrice;
    price[1] = survivorPrice;
    price[2] = assassinPrice;
    price[3] = zombieKillerPrice;
  }

  function updateBlacklist(address addr, bool status) external onlyOwner {
    blacklist[addr] = status;
  }

  function updateClaimTime(uint256 ct) external onlyOwner {
    claimTime = ct;
  }

  function getFunds() external onlyOwner {
    address payable sender = payable(_msgSender());

    uint256 bal = address(this).balance;
    sender.transfer(bal);
  }

  function getRecordsLength() external view returns (uint) {
    return records.length;
  }

  function buyAmateur(
    uint256 from,
    uint256 to,
    uint256 max,
    bool wl, //true for wl and false for free
    uint256 timestamp,
    bytes calldata signature
  ) external payable {
    buy(0, from, to, max, wl, timestamp, signature);
  }

  function buySurvivor(
    uint256 from,
    uint256 to,
    uint256 max,
    bool wl, //true for wl and false for free
    uint256 timestamp,
    bytes calldata signature
  ) external payable {
    buy(1, from, to, max, wl, timestamp, signature);
  }

  function buyAssassin(
    uint256 from,
    uint256 to,
    uint256 max,
    bool wl, //true for wl and false for free
    uint256 timestamp,
    bytes calldata signature
  ) external payable {
    buy(2, from, to, max, wl, timestamp, signature);
  }

  function buyZombieKiller(
    uint256 from,
    uint256 to,
    uint256 max,
    bool wl, //true for wl and false for free
    uint256 timestamp,
    bytes calldata signature
  ) external payable {
    buy(3, from, to, max, wl, timestamp, signature);
  }

  function buy(
    uint256 weaponType,
    uint256 from,
    uint256 to,
    uint256 max,
    bool wl, //true for wl and false for free
    uint256 timestamp,
    bytes calldata signature
  ) internal nonReentrant {
    uint256 value = msg.value;
    address sender = _msgSender();
    uint256 amount = to - from + 1;
    checkConditions(weaponType, amount, from, to, max, wl, timestamp, signature, sender);

    IMultiMintNFT(nft).multipleMint(sender, from, to, weaponType);
    saleByWeapon[weaponType] += amount;
    saleByAddress[sender] += amount;

    uint256 prices = price[weaponType] * amount;
    if (!wl) {
      prices = 0;
    }

    require(value >= prices, "invalid price");
    if (value > prices) payable(sender).transfer(value - prices);

    records.push(Record(sender, value, weaponType, from, to, wl, block.timestamp));
  }

  function checkConditions(
    uint256 weaponType,
    uint256 amount,
    uint256 from,
    uint256 to,
    uint256 max,
    bool wl, //true for wl and false for free
    uint256 timestamp,
    bytes calldata signature,
    address sender
  ) internal view {
    require(!blacklist[sender], "you are in blacklist");
    require(saleByAddress[sender] + amount <= max, "already bought the limit");
    require(block.timestamp <= timestamp + claimTime, "time is expired");
    require(
      hasRole(
        MINTER_ROLE,
        ECDSAUpgradeable.recover(hashVal(sender, weaponType, from, to, max, wl, timestamp), signature)
      ),
      "invalid signature"
    );
  }

  function hashVal(
    address wallet,
    uint256 weaponType,
    uint256 from,
    uint256 to,
    uint256 max,
    bool wl, //true for wl and false for free
    uint256 timestamp
  ) private view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256(
              "UndeadNFTPresale712(address wallet,uint256 weaponType,uint256 from,uint256 to,uint256 max,bool wl,uint256 timestamp)"
            ),
            wallet,
            weaponType,
            from,
            to,
            max,
            wl,
            timestamp
          )
        )
      );
  }
}
