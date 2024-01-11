// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IHookSender.sol";

// ---------------------------------------------------------------------
// MultiSender
// Maximum 700 addresses per TX
// ---------------------------------------------------------------------
contract MultiSender is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event LogEthSent(uint total);
  event LogTokenSent(address token, uint total);
  event LogHookSent(address hook);

  uint public txFee;
  uint public VIPFee;

  /**
   * @dev Upgradable initializer
   */
  function __MultiSender_init() public initializer {
    __Ownable_init();
  }

  mapping(address => bool) public vipList;

  function registerVIP() public payable {
    require(msg.value >= VIPFee, "0x00000000001");
    require(!vipList[_msgSender()], "0x00000000017");
    vipList[_msgSender()] = true;
    require(payable(_msgSender()).send(msg.value), "0x00000000002");
  }

  function addToVIPList(address[] memory _vipList) public onlyOwner {
    for (uint i = 0; i < _vipList.length; i++) {
      vipList[_vipList[i]] = true;
    }
  }

  function removeFromVIPList(address[] memory _vipList) public onlyOwner {
    for (uint i = 0; i < _vipList.length; i++) {
      vipList[_vipList[i]] = false;
    }
  }

  function isVIP(address _addr) public view returns (bool) {
    return _addr == owner() || vipList[_addr];
  }

  function setVIPFee(uint _fee) public onlyOwner {
    VIPFee = _fee;
  }

  function setTxFee(uint _fee) public onlyOwner {
    txFee = _fee;
  }

  function ethSendSameValue(address[] memory _to, uint _value) public payable {
    // Validate fee
    uint totalAmount = _to.length * _value;
    uint totalEthValue = msg.value;
    if (isVIP(_msgSender())) {
      require(totalEthValue >= totalAmount, "0x00000000003");
    } else {
      require(totalEthValue >= (totalAmount + txFee), "0x00000000004");
    }

    // Send
    // solhint-disable multiple-sends
    for (uint i = 0; i < _to.length; i++) {
      require(payable(_to[i]).send(_value), "0x00000000005");
    }

    emit LogEthSent(msg.value);
  }

  function ethSendDifferentValue(address[] memory _to, uint[] memory _value) public payable {
    require(_to.length == _value.length, "0x00000000006");

    uint totalEthValue = msg.value;

    // Validate fee
    uint totalAmount = 0;
    for (uint i = 0; i < _to.length; i++) {
      totalAmount = totalAmount + _value[i];
    }

    if (isVIP(_msgSender())) {
      require(totalEthValue >= totalAmount, "0x00000000007");
    } else {
      require(totalEthValue >= (totalAmount + txFee), "0x00000000008");
    }

    // Send
    for (uint i = 0; i < _to.length; i++) {
      require(payable(_to[i]).send(_value[i]), "0x00000000009");
    }

    emit LogEthSent(msg.value);
  }

  function coinSendSameValue(
    address _tokenAddress,
    address[] memory _to,
    uint _value
  ) public payable {
    // Validate fee
    uint totalEthValue = msg.value;
    if (!isVIP(_msgSender())) {
      require(totalEthValue >= txFee, "0x00000000010");
    }

    // Validate token balance
    IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
    uint tokenBalance = token.balanceOf(_msgSender());
    uint totalAmount = _to.length * _value;
    require(tokenBalance >= totalAmount, "0x00000000011");

    // Send
    for (uint i = 0; i < _to.length; i++) {
      token.safeTransferFrom(_msgSender(), _to[i], _value);
    }

    emit LogTokenSent(_tokenAddress, totalAmount);
  }

  function coinSendDifferentValue(
    address _tokenAddress,
    address[] memory _to,
    uint[] memory _value
  ) public payable {
    require(_to.length == _value.length, "0x00000000012");

    // Validate fee
    uint totalEthValue = msg.value;
    if (!isVIP(_msgSender())) {
      require(totalEthValue >= txFee, "0x00000000013");
    }

    // Validate token balance
    IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
    uint tokenBalance = token.balanceOf(_msgSender());
    uint totalAmount = 0;
    for (uint i = 0; i < _to.length; i++) {
      totalAmount = totalAmount + _value[i];
    }
    require(tokenBalance >= totalAmount, "0x00000000014");

    // Send
    for (uint i = 0; i < _to.length; i++) {
      token.safeTransferFrom(_msgSender(), _to[i], _value[i]);
    }

    emit LogTokenSent(_tokenAddress, totalAmount);
  }

  function hookSend(address _hookAddress, uint maxLoop) public payable {
    // Validate fee
    uint totalEthValue = msg.value;
    if (!isVIP(_msgSender())) {
      require(totalEthValue >= txFee, "0x00000000015");
    }

    // Loop
    IHookSender hook = IHookSender(_hookAddress);
    for (uint i = 0; i < maxLoop; i++) {
      require(hook.multiSenderLoop(_msgSender(), i, maxLoop), "0x00000000016");
    }

    emit LogHookSent(_hookAddress);
  }

  function getEthBalance() public view returns (uint) {
    return address(this).balance;
  }

  function withdrawEthBalance() external onlyOwner {
    payable(owner()).transfer(getEthBalance());
  }

  function getTokenBalance(address _tokenAddress) public view returns (uint) {
    IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
    return token.balanceOf(address(this));
  }

  function withdrawTokenBalance(address _tokenAddress) external onlyOwner {
    IERC20Upgradeable token = IERC20Upgradeable(_tokenAddress);
    token.safeTransfer(owner(), getTokenBalance(_tokenAddress));
  }
}
