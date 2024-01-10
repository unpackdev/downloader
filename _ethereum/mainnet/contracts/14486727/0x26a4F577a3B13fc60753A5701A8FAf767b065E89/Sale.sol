// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;
pragma abicoder v2;

import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721PresetMinterPauserAutoId.sol";

struct SaleInfo {
  uint256 start;
  uint256 end;
  uint256 price;
}

contract Sale is OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeMathUpgradeable for uint256;

  // 1. 명당 하나씩 + 프리민트
  SaleInfo public phase1;
  // 2. 정해진 물량 안에서 제한없이
  SaleInfo public phase2;
  // 3. 인당 정해진 캡
  SaleInfo public phase3;

  // phase3
  uint256 public saleAmount;
  uint256 public saleRemainings;
  uint256 public saleUserCap;

  address public spottie;
  address public beneficiary;

  // phase1 + phase2
  mapping(address => uint256) public freemint;
  mapping(address => uint256) public whitelistAllocation;
  mapping(address => bool) public whitelisted;

  // phase3
  mapping(address => uint256) public purchaseLogs;

  function initialize(
    SaleInfo[] memory _phases,
    uint256 _saleAmount,
    uint256 _saleUserCap,
    address _spottie,
    address _beneficiary
  ) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();

    require(_phases.length == 3, "Sale: invalid phases");
    phase1 = _phases[0];
    phase2 = _phases[1];
    phase3 = _phases[2];

    saleAmount = _saleAmount;
    saleRemainings = _saleAmount;
    saleUserCap = _saleUserCap;
    spottie = _spottie;
    beneficiary = _beneficiary;
  }

  function freeminter(address _user, uint256 _amount) external onlyOwner {
    freemint[_user] = _amount;
  }

  function whitelist(address _user, uint256 _amount) external onlyOwner {
    whitelisted[_user] = _amount > 0;
    whitelistAllocation[_user] = _amount;
  }

  function batchWhitelist(address[] memory _users, uint256[] memory _amounts)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _users.length; i++) {
      whitelisted[_users[i]] = _amounts[i] > 0;
      whitelistAllocation[_users[i]] = _amounts[i];
    }
  }

  function info(address _user)
    external
    view
    returns (
      bool,
      uint256,
      bool,
      uint256,
      uint256
    )
  {
    return (
      whitelisted[_user],
      whitelistAllocation[_user],
      freemint[_user] > 0,
      freemint[_user],
      saleRemainings
    );
  }

  function sale()
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (saleAmount, saleRemainings, saleUserCap);
  }

  function phases() external view returns (SaleInfo[] memory infos) {
    infos = new SaleInfo[](3);
    infos[0] = phase1;
    infos[1] = phase2;
    infos[2] = phase3;
  }

  function checkTime(SaleInfo memory _info) internal view returns (bool) {
    return _info.start <= block.timestamp && block.timestamp < _info.end;
  }

  function exchange(uint256 _amount)
    external
    payable
    nonReentrant
    returns (uint256, uint256)
  {
    uint256 amount;
    uint256 returned;

    if (checkTime(phase1)) {
      (amount, returned) = processPhase1(msg.value, _amount);
    } else if (checkTime(phase2)) {
      (amount, returned) = processPhase2(msg.value, _amount);
    } else if (checkTime(phase3)) {
      (amount, returned) = processPhase3(msg.value, _amount);
    } else {
      revert("Sale: invalid time");
    }

    for (uint256 i = 0; i < amount; i++) {
      ERC721PresetMinterPauserAutoId(spottie).mint(_msgSender());
    }

    payable(beneficiary).transfer(msg.value.sub(returned));
    payable(_msgSender()).transfer(returned);

    return (amount, returned);
  }

  function processPhase1(uint256 _received, uint256 _desired)
    internal
    returns (uint256, uint256)
  {
    require(saleRemainings > 0, "Sale: not enough remainings");

    address sender = _msgSender();
    uint256 f = freemint[sender];
    uint256 w = whitelistAllocation[sender];

    if (f >= _desired) {
      freemint[sender] = f.sub(_desired);
      saleRemainings = saleRemainings.sub(_desired);
      return (_desired, _received); // free
    }

    require(whitelisted[sender], "Sale: only whitelist");
    require(w > 0, "Sale: not enough allocation");

    uint256 amount = MathUpgradeable.min(w, _desired.sub(f)).add(f);
    require(
      _received >= phase1.price.mul(amount.sub(f)),
      "Sale: insufficient receives"
    );

    freemint[sender] = 0;
    whitelistAllocation[sender] = w.sub(amount.sub(f));
    saleRemainings = saleRemainings.sub(amount);

    return (amount, _received.sub(phase1.price.mul(amount.sub(f))));
  }

  function processPhase2(uint256 _received, uint256 _desired)
    internal
    returns (uint256, uint256)
  {
    address sender = _msgSender();
    require(whitelisted[sender], "Sale: only whitelist");
    require(saleRemainings > 0, "Sale: not enough remainings");

    uint256 amount = MathUpgradeable.min(_desired, saleRemainings);
    saleRemainings = saleRemainings.sub(amount);
    require(
      _received >= phase2.price.mul(amount),
      "Sale: insufficient receives"
    );

    return (amount, _received.sub(phase2.price.mul(amount)));
  }

  function processPhase3(uint256 _received, uint256 _desired)
    internal
    returns (uint256, uint256)
  {
    address sender = _msgSender();
    require(saleRemainings > 0, "Sale: not enough remainings");

    uint256 amount = MathUpgradeable.min(
      MathUpgradeable.min(_desired, saleRemainings),
      saleUserCap.sub(purchaseLogs[sender])
    );
    require(
      _received >= phase3.price.mul(amount),
      "Sale: insufficient receives"
    );

    purchaseLogs[sender] = purchaseLogs[sender].add(amount);
    saleRemainings = saleRemainings.sub(amount);

    return (amount, _received.sub(phase3.price.mul(amount)));
  }
}
