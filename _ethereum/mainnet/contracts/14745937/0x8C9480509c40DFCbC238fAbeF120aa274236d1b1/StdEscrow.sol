// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";



contract StdEscrow is Ownable {
    using SafeMath for uint256;

    IERC20 public token = IERC20(0x20365931bE2Ed87400a4FD13ac5Ac4fBb5ADdc40);
    address payable immutable daoTreasury;

    uint256 public constant RATE = 5;
    bool private _initialized;

    event Initialized(address account);
    event BuyToken(address account, uint256 amount);

    constructor(address _daoTreasury) {
        _initialized = false;
        daoTreasury = payable(_daoTreasury);
    }

    // onlyController

    function init(uint256 _stdAmount) external onlyController notInitialized {
        require(
            token.transferFrom(msg.sender, address(this), _stdAmount),
            "Could not transfer amount initially."
        );

        _init();
    }

    function buyToken() external payable onlyInitialized {
        require(msg.value > 0, "The paid amount can't be zero.");
        uint256 balance = getBalance();
        require(balance != 0, "The token sold out now.");
        uint256 tokenAmount = (msg.value * 100000) / RATE;
        require(
            balance >= tokenAmount,
            "The token amount can't be over than the balance."
        );
        require(
            token.transfer(msg.sender, tokenAmount),
            "Could not transfer tokens"
        );
        emit BuyToken(msg.sender, tokenAmount);
    }

    receive() external payable {
        revert("Please use the buyToken function");
    }

    function initialized() public view virtual returns (bool) {
        return _initialized;
    }
    
    modifier notInitialized() {
        require(!initialized(), "Initializable: Already initialized");
        _;
    }

    modifier onlyController() {
        require(msg.sender == daoTreasury, "only controller can execute.");
        _;
    }

    modifier onlyInitialized() {
        require(initialized(), "Initializable: Not initialized");
        _;
    }

    function _init() internal virtual notInitialized {
        _initialized = true;
        emit Initialized(_msgSender());
    }

    function getBalance() internal view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getBalanceToken() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function onWithdrawToken(address withdrawAddress, uint256 amount)
        external
        onlyController
        onlyInitialized
    {
        require(getBalance() >= amount, "No available tokens for withdrawal");
        require(
            token.transfer(withdrawAddress, amount),
            "Could not transfer tokens"
        );
    }

    function claimProjectFunds() external onlyController onlyInitialized {
        (bool sent, ) = daoTreasury.call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }
}
