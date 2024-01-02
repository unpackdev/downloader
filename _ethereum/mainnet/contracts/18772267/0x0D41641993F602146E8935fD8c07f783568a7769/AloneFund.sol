/*
   _____                      __  _                    
  / ___/____  ____ ___  ___  / /_(_)___ ___  ___  _____
  \__ \/ __ \/ __ `__ \/ _ \/ __/ / __ `__ \/ _ \/ ___/
 ___/ / /_/ / / / / / /  __/ /_/ / / / / / /  __(__  ) 
/____/\____/_/ /_/ /_/\___/\__/_/_/ /_/ /_/\___/____/  
   /   |  / /___  ____  ___                            
  / /| | / / __ \/ __ \/ _ \                           
 / ___ |/ / /_/ / / / /  __/                           
/_/  |_/_/\____/_/ /_/\___/                                 

TG: https://t.me/AlonePortal
Website: https://alone.af
Twitter: https://twitter.com/ERC20_Alone
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract AloneFund is Context, Ownable {
    using SafeMath for uint256;
    address payable public botWallet;
    uint256 public botGasTax = 10;

    event AloneReward(
        address indexed user,
        uint256 indexed amount
    );

    event AloneDeposit(
        uint256 indexed deposited,
        uint256 indexed botShare
    );

    modifier onlyBot() {
        require(botWallet == _msgSender(), "AloneFund: Caller is not the bot");
        _;
    }

    constructor(address _botWallet) {
        botWallet = payable(_botWallet);
    }

    function changeBotWallet(address newBotWallet) external onlyOwner {
        require(newBotWallet != address(0), "AloneFund: BotWallet can not be zero address");
        botWallet = payable(newBotWallet);
    }

    function setBotGasTax(uint256 _botGasTax) external onlyOwner {
        require(50 > _botGasTax, "AloneFund: BotGasTax cannot be more than 50%");
        botGasTax = _botGasTax;
    }

    function deposit() external payable {
        require(msg.value > 0, "AloneFund: Deposit of 0 ETH");
        uint256 botShare = 0;
        if (botGasTax > 0) {
            botShare = msg.value.mul(botGasTax).div(100);
            botWallet.transfer(botShare);
        }
        emit AloneDeposit(msg.value.sub(botShare), botShare);
    }

    function reward(address aloneUser, uint256 amount) external onlyBot {
        require(amount < address(this).balance, "AloneFund: Not enought funds");
        payable(aloneUser).transfer(amount);
        emit AloneReward(aloneUser, amount);
    }

    receive() external payable {}

}