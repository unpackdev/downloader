// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4.0;
import "./SafeMath.sol";

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";

contract AeroSwap is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit {
    uint256 private _guardCounter;
    bool private _paused; // Circuit breaker flag
    uint256 public depositDeadline = 1000000000000000000000000000000000000000000 minutes;
    uint256 public maxWithdrawPerTx = 100000000000000000000000000000000000000000; // Adjust the value as needed
    uint256 public ethToAeroRatio = 1;

    event EthDeposited(address indexed sender, uint256 amount, uint256 fee);
    event AeroWithdrawn(address indexed recipient, uint256 amount);
    event EmergencyStop(bool stopped);
    event DepositStarted(address indexed sender);
    event DepositEnded(address indexed sender, uint256 amount);
    event WithdrawalStarted(address indexed sender, uint256 amount);
    event WithdrawalEnded(address indexed sender, uint256 amount);

    modifier nonReentrant() {
        _guardCounter++;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "Reentrancy detected");
    }

    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "No contracts allowed");
        _;
    }

    address private _owner;

    constructor() ERC20("AeroSwap", "AERO") Ownable(msg.sender) ERC20Permit("AeroSwap") {
        _owner = msg.sender;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable nonReentrant notContract notPaused {
        emit DepositStarted(msg.sender);

        require(msg.value > 0, "Must deposit some ETH");
        require(block.timestamp < depositDeadline, "Deposit deadline passed");

        uint256 feeAmount = (msg.value * 1) / 100;
        uint256 aeroAmount = (msg.value - feeAmount) * ethToAeroRatio;

        _mint(msg.sender, aeroAmount);

        emit EthDeposited(msg.sender, msg.value, feeAmount);
        emit DepositEnded(msg.sender, aeroAmount);
    }

    function withdraw(uint256 _aeroAmount) public nonReentrant notPaused {
        emit WithdrawalStarted(msg.sender, _aeroAmount);

        require(_aeroAmount > 0, "Withdraw AeroSwap tokens");
        require(_aeroAmount <= maxWithdrawPerTx, "Exceeds max per tx");
        require(balanceOf(msg.sender) >= _aeroAmount, "Insufficient balance");

        uint256 ethAmount = (_aeroAmount / ethToAeroRatio);
        
        _burn(msg.sender, _aeroAmount);

        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "Eth transfer failed");

        emit AeroWithdrawn(msg.sender, ethAmount);
        emit WithdrawalEnded(msg.sender, _aeroAmount);
    }

    function toggleEmergencyStop() external onlyOwner {
        _paused = !_paused;

        emit EmergencyStop(_paused);
    }

    function rescueEth() external onlyOwner {
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success, "Eth rescue failed");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
