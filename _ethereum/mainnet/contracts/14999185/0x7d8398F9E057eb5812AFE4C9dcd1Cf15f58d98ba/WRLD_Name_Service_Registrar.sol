// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

import "./IWNS_Passes.sol";
import "./IWRLD_Name_Service_Registry.sol";
import "./StringUtils.sol";

contract WRLD_Name_Service_Registrar is Ownable, ReentrancyGuard {
  using StringUtils for *;

  /**
   * @dev @iamarkdev was here
   * */

  IERC20 immutable wrld;
  IWNS_Passes immutable whitelist;
  IWRLD_Name_Service_Registry immutable registry;

  uint256 private constant YEAR_SECONDS = 31536000;
  uint256 private constant PREREGISTRATION_PASS_TYPE_ID = 2;

  bool public registrationEnabled = false;

  uint256[5] public annualWrldPrices = [ 1e70, 1e70, 20000 ether, 2000 ether, 500 ether ]; // $WRLD, 1 char to 5 chars

  address private approvedWithdrawer;

  constructor(address _registry, address _wrld, address _whitelist) {
    registry = IWRLD_Name_Service_Registry(_registry);
    wrld = IERC20(_wrld);
    whitelist = IWNS_Passes(_whitelist);
  }

  /****************
   * Registration *
   ****************/

  function registerWithPass(string[] calldata _names) external nonReentrant {
    bool senderIsOwner = msg.sender == owner();

    if (!senderIsOwner) {
      whitelist.burnTypeForOwnerAddress(PREREGISTRATION_PASS_TYPE_ID, _names.length, msg.sender);
    }

    uint16[] memory registrationYears = new uint16[](_names.length);

    for (uint256 i = 0; i < _names.length; i++) {
      registrationYears[i] = 1;

      if (!senderIsOwner) {
        require(getRegistrationPrice(_names[i]) < 1000000 ether, "Name not available for sale");
      }
    }

    _register(_names, registrationYears, true);
  }

  function register(string[] calldata _names, uint16[] calldata _registrationYears) external nonReentrant {
    require(registrationEnabled, "Registration is not enabled.");

    _register(_names, _registrationYears, false);
  }

  function _register(string[] calldata _names, uint16[] memory _registrationYears, bool _free) private {
    require(_names.length == _registrationYears.length, "Arg size mismatched");

    uint256 sumPrice = 0;

    for (uint256 i = 0; i < _names.length; i++) {
      sumPrice += _registrationYears[i] * getRegistrationPrice(_names[i]);
    }

    registry.register(msg.sender, _names, _registrationYears);

    if (!_free) {
      wrld.transferFrom(msg.sender, address(this), sumPrice);
    }
  }

  function getRegistrationPrice(string calldata _name) public view returns (uint price) {
    uint len = _name.strlen();
    if (len > 0 && len <= 5) {
      price = annualWrldPrices[len-1];
    } else if (len > 5) {
      price = annualWrldPrices[4];
    } else {
      revert("Invalid name");
    }
  }

  /*************
   * Extension *
   *************/

  function extendRegistration(string[] calldata _names, uint16[] calldata _additionalYears) external nonReentrant {
    require(_names.length == _additionalYears.length, "Arg size mismatched");

    uint256 sumPrice = 0;

    for (uint256 i = 0; i < _names.length; i++) {
      sumPrice += _additionalYears[i] * getRegistrationPrice(_names[i]);
    }

    registry.extendRegistration(_names, _additionalYears);

    wrld.transferFrom(msg.sender, address(this), sumPrice);
  }

  /*********
   * Owner *
   *********/

  function setAnnualWrldPrices(uint256[] memory _annualWrldPrices) external onlyOwner {
    annualWrldPrices[0] = _annualWrldPrices[0];
    annualWrldPrices[1] = _annualWrldPrices[1];
    annualWrldPrices[2] = _annualWrldPrices[2];
    annualWrldPrices[3] = _annualWrldPrices[3];
    annualWrldPrices[4] = _annualWrldPrices[4];
  }

  function setApprovedWithdrawer(address _approvedWithdrawer) external onlyOwner {
    approvedWithdrawer = _approvedWithdrawer;
  }

  function enableRegistration() external onlyOwner {
    registrationEnabled = true;
  }

  /**************
   * Withdrawal *
   **************/

  function withdrawWrld(address toAddress) external {
    require(msg.sender == owner() || msg.sender == approvedWithdrawer, "Not approved to withdraw");

    wrld.transfer(toAddress, wrld.balanceOf(address(this)));
  }
}
