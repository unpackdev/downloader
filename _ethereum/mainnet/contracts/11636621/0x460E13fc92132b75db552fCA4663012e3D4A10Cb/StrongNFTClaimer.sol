//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./ServiceInterface.sol";
import "./IERC1155Preset.sol";

import "./Context.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract StrongNFTClaimer is Context, AccessControl, Ownable {
  using Counters for Counters.Counter;

  IERC1155Preset public token;
  ServiceInterface public service;

  address payable public feeCollector;
  uint256 public claimingFeeInWei;

  string[] public tokenNames;
  mapping(string => uint256) public tokenNameIndex;
  mapping(string => bool) public tokenNameExists;
  mapping(string => Counters.Counter) public tokenNameCounter;
  mapping(string => mapping(address => bool)) public tokenNameAddressClaimed;

  function init(address tokenContract, address serviceContract) public onlyOwner {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    token = IERC1155Preset(tokenContract);
    service = ServiceInterface(serviceContract);
  }

  function isEligible(string memory tokenName, address claimer) public view returns (bool) {
    if (keccak256(abi.encode(tokenName)) == keccak256(abi.encode('BRONZE'))) {
      return
        tokenNameExists[tokenName] &&
        !tokenNameAddressClaimed[tokenName][claimer] &&
        service.isEntityActive(claimer) &&
        service.getTraunch(claimer) == 0;
    }

    return false;
  }

  function updateFeeCollector(address payable newFeeCollector) public {
    require(newFeeCollector != address(0), 'zero');
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'not admin');

    feeCollector = newFeeCollector;
  }

  function updateClaimingFee(uint256 feeInWei) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'not an admin');

    claimingFeeInWei = feeInWei;
  }

  function claim(string memory tokenName) public payable {
    require(tokenNameExists[tokenName], 'invalid token');
    require(msg.value == claimingFeeInWei, 'invalid fee');
    require(tokenNameAddressClaimed[tokenName][_msgSender()] == false, 'already claimed');

    if (keccak256(abi.encode(tokenName)) == keccak256(abi.encode('BRONZE'))) {
      require(service.isEntityActive(_msgSender()), 'not active');
      require(service.getTraunch(_msgSender()) == 0, 'wrong traunch');

      token.mint(_msgSender(), tokenNameCounter[tokenName].current(), 1, '');
      tokenNameCounter[tokenName].increment();
      tokenNameAddressClaimed[tokenName][_msgSender()] = true;

      feeCollector.transfer(msg.value);
    } else {
      return;
    }
  }

  function addTokenName(string memory tokenName, uint256 counterValue) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'not admin');

    if (tokenNames.length != 0) {
      uint256 index = tokenNameIndex[tokenName];
      require(keccak256(abi.encode(tokenNames[index])) != keccak256(abi.encode(tokenName)), 'exists');
    }
    uint256 len = tokenNames.length;
    tokenNameIndex[tokenName] = len;
    tokenNameExists[tokenName] = true;
    tokenNameCounter[tokenName] = Counters.Counter(counterValue);
    tokenNames.push(tokenName);
  }
}
