// SPDX-License-Identifier: BUSL-1.1
// EPSProxy Contracts v1.11.0 (epsproxy/contracts/ProxyRegister.sol)

pragma solidity ^0.8.13;
import "./Ownable.sol";
import "./EPS.sol";
import "./ERC20SpendableReceiver.sol"; 

/**
 * @dev The EPS Register contract.
 */
contract ProxyRegister is EPS, Ownable, ERC20SpendableReceiver {
  using SafeERC20 for IERC20;

  struct Record {
    address nominator;
    address delivery; 
  }

  uint256 private registerFee;
  uint256 private registerFeeOat;
  address private treasury;

  mapping (address => address) nominatorToProxy;
  mapping (address => Record) proxyToRecord;

  /**
  * @dev Constructor initialises the register fee and treasury address:
  */
  constructor(
    uint256 _registerFee,
    uint256 _registerFeeOat,
    address _treasury,
    address _ERC20Spendable
  ) 
    ERC20SpendableReceiver(_ERC20Spendable) 
  {
    setRegisterFee(_registerFee);
    setRegisterFeeOat(_registerFeeOat);
    setTreasuryAddress(_treasury);
  }

  /** 
  * @dev Nominators can nominate ONCE only
  */ 
  modifier isNotCurrentNominator(address _nominator) {
    require(!nominationExists(_nominator), "Address has an existing nomination");
    _;
  }

  /**
  * @dev Check if this nominator is already on the registry
  */
  modifier isExistingNominator(address _nominator) {
    require(nominationExists(_nominator), "Nominator entry does not exist");
    _;
  }

  /** 
  * @dev Proxys can act as proxy ONCE only
  */ 
  modifier isNotCurrentProxy(address _proxy) {
    require(!proxyRecordExists(_proxy), "Address is already acting as a proxy");
    _;
  }

  /**
  * @dev Check if this proxy is already on the registry
  */
  modifier isExistingProxy(address _proxy) {
    require(proxyRecordExists(_proxy), "Proxy entry does not exist");
    _;
  }

  /**
  * @dev Return if an entry exists for this nominator address
  */
  function nominationExists(address _nominator) public view returns (bool) {
    return nominatorToProxy[_nominator] != address(0);
  }

  /**
  * @dev Return if an entry exists for this nominator address - For Caller
  */
  function nominationExistsForCaller() public view returns (bool) {
    return nominationExists(msg.sender);
  }

  /**
  * @dev Return if an entry exists for this proxy address
  */
  function proxyRecordExists(address _proxy) public view returns (bool) {
    return proxyToRecord[_proxy].nominator != address(0);
  }

  /**
  * @dev Return if an entry exists for this proxy address - For Caller
  */
  function proxyRecordExistsForCaller() external view returns (bool) {
    return proxyRecordExists(msg.sender);
  }

  /**
  * @dev Return if an entry exists for this nominator address
  */
  function nominatorRecordExists(address _nominator) public view returns (bool) {
    return proxyToRecord[nominatorToProxy[_nominator]].nominator != address(0);
  }

  /**
  * @dev Return if an entry exists for this nominator address - For Caller
  */
  function nominatorRecordExistsForCaller() external view returns (bool) {
    return nominatorRecordExists(msg.sender);
  }

  /**
  * @dev Return if the address is an active proxy address OR a nominator with an active proxy
  */
  function addressIsActive(address _receivedAddress) public view returns (bool) {
    bool isActive = false;
    // Check if the address is an active proxy address or active nominator:
    if (proxyRecordExists(_receivedAddress) || nominatorRecordExists(_receivedAddress)){
      isActive = true;
    }
    return isActive;
  }

  /**
  * @dev Return if the address is an active proxy address OR a nominator with an active proxy - For Caller
  */
  function addressIsActiveForCaller() external view returns (bool) {
    return addressIsActive(msg.sender);
  }

  /**
  * @dev Get entry details by proxy
  */
  function getProxyRecord(address _proxy) public view returns (address nominator, address proxy, address delivery) {
    Record memory currentItem = proxyToRecord[_proxy];
    return (currentItem.nominator, nominatorToProxy[currentItem.nominator], currentItem.delivery);
  }
  
  /**
  * @dev Get entry details by proxy - For Caller
  */
  function getProxyRecordForCaller() external view returns (address nominator, address proxy, address delivery) {
    return (getProxyRecord(msg.sender));
  }

  /**
  * @dev Get entry details by nominator
  */
  function getNominatorRecord(address _nominator) public view returns (address nominator, address proxy, address delivery) {
    address proxyAddress = nominatorToProxy[_nominator];
    if (proxyToRecord[proxyAddress].nominator == address(0)) {
      // This function returns registry entries. If there is no entry on the registry (despite there being a nomination), do
      // not return the proxy address:
      proxyAddress = address(0);
    }
    return (proxyToRecord[proxyAddress].nominator, proxyAddress, proxyToRecord[proxyAddress].delivery);
  }

  /**
  * @dev Get entry details by nominator - For Caller
  */
  function getNominatorRecordForCaller() external view returns (address nominator, address proxy, address delivery) {
    return (getNominatorRecord(msg.sender));
  }

  /**
  * @dev Get nomination details only for nominator
  */
  function getNomination(address _nominator) public view returns (address proxy) {
    return (nominatorToProxy[_nominator]);
  }

  /**
  * @dev Get nomination details only for nominator - For Caller
  */
  function getNominationForCaller() public view returns (address proxy) {
    return (getNomination(msg.sender));
  }

  /**
  * @dev Returns the proxied address details (nominator and delivery address) for a passed proxy address  
  */
  function getAddresses(address _receivedAddress) public view returns (address nominator, address delivery, bool isProxied) {
    require(!nominationExists(_receivedAddress), "Nominator address cannot interact directly, only through the proxy address");
    Record memory currentItem = proxyToRecord[_receivedAddress];
    if (proxyToRecord[_receivedAddress].nominator == address(0)) {
      return(_receivedAddress, _receivedAddress, false);
    }
    else {
      return (currentItem.nominator, currentItem.delivery, true);
    }
  }

  /**
  * @dev Returns the proxied address details (owner and delivery address) for the msg.sender being interacted with
  */
  function getAddressesForCaller() external view returns (address nominator, address delivery, bool isProxied) {
    return (getAddresses(msg.sender));
  }

  /**
  * @dev Returns the current role of a given address (nominator, proxy, none)
  */
  function getRole(address _roleAddress) public view returns (string memory currentRole) {
    if (proxyRecordExists(_roleAddress)) {
      return "Proxy";
    }
    if (nominationExists(_roleAddress)) {
      if (proxyRecordExists(nominatorToProxy[_roleAddress])) {
        return "Nominator - Proxy Active";
      }
      else {
        return "Nominator - Proxy Pending";
      }
    }
    return "None";
  }

  /**
  * @dev Returns the current role of a given address (nominator, proxy, none) - For Caller
  */
  function getRoleForCaller() external view returns (string memory currentRole) {
    return getRole(msg.sender);
  }

  /**
  * @dev The nominator initiaties a proxy entry
  */
  function makeNomination(address _proxy, uint256 _provider) external payable {
    require(msg.value == registerFee, "Register fee must be paid");

    performNomination(msg.sender, _proxy, _provider);
  }

  /**
  * @dev The nominator initiaties a proxy entry, paying with ERC20
  */
  function receiveSpendableERC20(address _caller, uint256 _tokenPaid, uint256[] memory _arguments) override external onlyERC20Spendable(msg.sender) returns(bool, uint256[] memory) { 
    require(_tokenPaid == registerFeeOat, "Register fee must be paid");

    performNomination(_caller, address(uint160(_arguments[0])), _arguments[1]);

    return(true, new uint256[](0)); 
  }

  /**
  * @dev Process the nomination
  */
  function performNomination(address _nominator, address _proxy, uint256 _provider) internal isNotCurrentNominator(_nominator) isNotCurrentProxy(_proxy) isNotCurrentProxy(_nominator) {
    require (_proxy != address(0), "Proxy address must be provided");
    require (_proxy != _nominator, "Proxy address cannot be the same as Nominator address");

    nominatorToProxy[_nominator] = _proxy;
    emit NominationMade(_nominator, _proxy, block.timestamp, _provider); 
  }
  
  /**
  * @dev Proxy accepts nomination
  */
  function acceptNomination(address _nominator, address _delivery, uint256 _provider) external isNotCurrentProxy(msg.sender) isNotCurrentProxy(_nominator) {
    // The nominator must be passed in:
    require (_nominator != address(0), "Nominator address must be provided");
    // The sender must match the proxy nomination:
    require (nominatorToProxy[_nominator] == msg.sender, "Caller is not the nominated proxy for this nominator");
    // We have a valid nomination, create the ProxyRegisterItem:
    proxyToRecord[msg.sender] = Record(_nominator, _delivery);
    emit NominationAccepted(_nominator, msg.sender, _delivery, block.timestamp, _provider);
  }

  /**
  * @dev Change delivery address on an existing proxy item. Can only be called by the proxy address.
  */
  function updateDeliveryAddress(address _delivery, uint256 _provider) external isExistingProxy(msg.sender) {
    Record memory priorItem = proxyToRecord[msg.sender];
    proxyToRecord[msg.sender].delivery = _delivery;
    emit DeliveryUpdated(priorItem.nominator, msg.sender, _delivery, priorItem.delivery, block.timestamp, _provider);
  }

  /**
  * @dev delete a proxy entry. BOTH the nominator and proxy can delete a proxy arrangement and all
  * aspects of that proxy arrangement will be removed.
  */
  function deleteRecordByNominator(uint256 _provider) external isExistingNominator(msg.sender) {
    deleteProxyRegisterItems(msg.sender, nominatorToProxy[msg.sender], "nominator", _provider);
  }

  /**
  * @dev delete a proxy entry. BOTH the nominator and proxy can delete a proxy arrangement and all
  * aspects of that proxy arrangement will be removed.
  */
  function deleteRecordByProxy(uint256 _provider) external isExistingProxy(msg.sender) {
    deleteProxyRegisterItems(proxyToRecord[msg.sender].nominator, msg.sender, "proxy", _provider);
  }

  /**
  * @dev delete the nomination and record (if present)
  */
  function deleteProxyRegisterItems(address _nominator, address _proxy, string memory _initiator, uint256 _provider) internal {
    // First remove the nomination. We know this must exists, as it has to come before the proxy can be accepted:
    delete nominatorToProxy[_nominator];
    emit NominationDeleted(_initiator, _nominator, _proxy, block.timestamp, _provider);
    // Now remove the proxy register item. If the nominator is deleting a nomination that has not been accepted by a proxy
    // then this will not exists. Check that the proxy is for this nominator.
    if (proxyToRecord[_proxy].nominator == _nominator) {
      address deletedDelivery = proxyToRecord[_proxy].delivery; 
      delete proxyToRecord[_proxy];
      emit RecordDeleted(_initiator, _nominator, _proxy, deletedDelivery, block.timestamp, _provider);
    }
  }

  /**
  * @dev set the fee for initiating a registration (accepting a proxy, updating the delivery address and deletions will always be free)
  */
  function setRegisterFee(uint256 _registerFee) public onlyOwner returns (bool)
  {
    require(_registerFee != registerFee, "No change to register fee");
    registerFee = _registerFee;
    emit RegisterFeeSet(registerFee);
    return true;
  }

  /**
  * @dev set the OAT fee for initiating a registration (accepting a proxy, updating the delivery address and deletions will always be free)
  */
  function setRegisterFeeOat(uint256 _registerFeeOat) public onlyOwner returns (bool)
  {
    require(_registerFeeOat != registerFeeOat, "No change to register fee");
    registerFeeOat = _registerFeeOat;
    emit RegisterFeeOatSet(_registerFeeOat);
    return true;
  }

  /**
  * @dev return the register fee:
  */
  function getRegisterFee() external view returns (uint256 _registerFee) {
    return(registerFee);
  }

    /**
  * @dev return the OAT register fee:
  */
  function getRegisterFeeOat() external view returns (uint256 _registerFeeOat) {
    return(registerFeeOat);
  }

  /**
  * @dev set the treasury address:
  */
  function setTreasuryAddress(address _treasuryAddress) public onlyOwner returns (bool)
  {
    require(_treasuryAddress != treasury, "No change to treasury address");
    treasury = _treasuryAddress;
    emit TreasuryAddressSet(treasury);
    return true;
  }

  /**
  * @dev get the treasury address:
  */
  function getTreasuryAddress() external view returns (address _treasuryAddress) {
    return(treasury);
  }

  /**
  * @dev withdraw eth to the treasury:
  */
  function withdraw(uint256 _amount) external onlyOwner returns (bool) {
    (bool success, ) = treasury.call{value: _amount}("");
    require(success, "Withdrawal failed.");
    emit Withdrawal(_amount, block.timestamp);
    return true;
  }

  /**
  * @dev Allow any token payments to be withdrawn:
  */
  function withdrawERC20(IERC20 _token, uint256 _amountToWithdraw) external onlyOwner {
    _token.safeTransfer(treasury, _amountToWithdraw); 
    emit TokenWithdrawal(_amountToWithdraw, address(_token), block.timestamp);
  }

  /**
  * @dev revert fallback
  */
  fallback() external payable {
    revert();
  }

  /**
  * @dev revert receive
  */
  receive() external payable {
    revert();
  }
}