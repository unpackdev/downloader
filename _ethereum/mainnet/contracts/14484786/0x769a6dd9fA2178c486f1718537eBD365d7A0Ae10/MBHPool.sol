// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

// @author: olive

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//     $$\      $$\ $$$$$$$\  $$\   $$\       $$$$$$$\                      $$\       ///
//     $$$\    $$$ |$$  __$$\ $$ |  $$ |      $$  __$$\                     $$ |      ///
//     $$$$\  $$$$ |$$ |  $$ |$$ |  $$ |      $$ |  $$ | $$$$$$\   $$$$$$\  $$ |      ///
//     $$\$$\$$ $$ |$$$$$$$\ |$$$$$$$$ |      $$$$$$$  |$$  __$$\ $$  __$$\ $$ |      ///
//     $$ \$$$  $$ |$$  __$$\ $$  __$$ |      $$  ____/ $$ /  $$ |$$ /  $$ |$$ |      ///
//     $$ |\$  /$$ |$$ |  $$ |$$ |  $$ |      $$ |      $$ |  $$ |$$ |  $$ |$$ |      ///
//     $$ | \_/ $$ |$$$$$$$  |$$ |  $$ |      $$ |      \$$$$$$  |\$$$$$$  |$$ |      ///
//     \__|     \__|\_______/ \__|  \__|      \__|       \______/  \______/ \__|      ///
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

contract MBHPool is Ownable, ReentrancyGuard {
    address public signerAddress;

    mapping(address => bool) internal admins;

    mapping(address => uint256) lastCheckPoint;
    uint256 public delayBetweenPayout = 5 * 24 * 60 * 60;
    mapping(address => uint256) payoutLimit;
    uint256 public defaultLimit = 5 ether;
    bool public limitPaused = true;
    uint256 timeLimit = 90;

    event Deposited(uint256 amount);
    event Payout(address to, uint256 amount);

    constructor(address _signer) {
      signerAddress = _signer;
    }

    modifier onlyAdmin() {
        require(admins[_msgSender()], 'Caller is not the admin');
        _;
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function deposit() public payable onlyAdmin {
      require(msg.value > 0, "Not a valid amount");
      emit Deposited(msg.value);
    }

    function withdrawAll() public onlyOwner {
      uint256 balance = address(this).balance;
      require(balance > 0);
      _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
    }

    function getLimit(address _claimer) public view returns (uint256) {
      uint256 limit = payoutLimit[_claimer];
      if (limit == 0) { limit = defaultLimit; }

      return limit;
    }

    function payout(uint256 _amount, uint256 _timestamp, bytes memory _signature) external nonReentrant {
      uint256 balance = address(this).balance;
      require(_amount <= balance, "Not enough balance");

      address wallet = _msgSender();
      address signerOwner = signatureWallet(wallet, _amount, _timestamp, _signature);
      require(signerOwner == signerAddress, "Invalid data provided");

      require(_timestamp >= block.timestamp - timeLimit, "Out of time");

      require(_timestamp >= lastCheckPoint[wallet] + delayBetweenPayout, "Invalid timestamp");

      require(limitPaused || _amount < getLimit(wallet), "Amount exceeds limit");

      lastCheckPoint[wallet] = block.timestamp;
      _widthdraw(wallet, _amount);
      emit Payout(wallet, _amount);
    }

    function signatureWallet(address _wallet, uint256 _amount, uint256 _timestamp, bytes memory _signature) public pure returns (address){

      return ECDSA.recover(keccak256(abi.encode(_wallet, _amount, _timestamp)), _signature);

    }

    function setCheckPoint(address _claimer, uint256 _point) public onlyOwner {
      require(_claimer != address(0), "Unknown address");
      lastCheckPoint[_claimer] = _point;
    }

    function getCheckPoint(address _claimer) external view returns (uint256) {
      return lastCheckPoint[_claimer];
    }

    function updateDelay(uint256 _delay) public onlyOwner {
      delayBetweenPayout = _delay;
    }

    function setLimit(address _claimer, uint256 _limit) public onlyOwner {
      payoutLimit[_claimer ] = _limit;
    }

    function updateDefaultLimit(uint256 _limit) public onlyOwner {
      defaultLimit = _limit;
    }

    function pauseLimit(bool _pause) public onlyOwner {
      limitPaused = _pause;
    }

    function updateSignerAddress(address _signer) public onlyOwner {
      signerAddress = _signer;
    }

    function updateTimeLimit(uint256 _timeLimit) public onlyOwner {
      timeLimit = _timeLimit;
    }
}