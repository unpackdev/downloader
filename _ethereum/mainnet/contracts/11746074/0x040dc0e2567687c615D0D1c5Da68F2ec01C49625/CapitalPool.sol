// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./ICapitalPool.sol";
import "./ICapitalManager.sol";

import "./ERC20.sol";
import "./Ownable.sol";

contract CapitalPool is ICapitalPool, ERC20, Ownable {
    using SafeMath for uint;

    ICapitalManager public capitalManager;

    uint public investedBalance;
    uint public lockupPeriod = 2 weeks;

    uint public RATE = 1000;
    bool public stopChanges;

    mapping(address => uint) public lastProvideTimestamp;
    mapping(address => bool) public _revertTransfersInLockUpPeriod;
    mapping(address => bool) public guests;
    
    bool public guestlistIsActive = true;

    constructor() public ERC20("2ndary LP ETH", "2ndaryETH") {}

    receive() external payable {}

    function inviteGuest(address guest) external onlyOwner {
        guests[guest] = true;
    }

    function stopChangesForever() external onlyOwner {
        stopChanges = true;
    }

    function setGuestlistActive(bool active) external onlyOwner {
        guestlistIsActive = active;
    }

    function setCapitalManager(ICapitalManager cm) external onlyOwner {
        require(!stopChanges, "!stopChanges");
        capitalManager = cm;
    }

    function setLockupPeriod(uint newLockupPeriod) external onlyOwner {
        lockupPeriod = newLockupPeriod;
    }

    function sendTo(address to, uint amount) external override onlyCapitalManager {
        payable(to).transfer(amount);
    }

    function updateInvestedBalance(bool isAddOrSubstract, uint amount) external override onlyCapitalManager {
        // add = true, substract = false
        if(isAddOrSubstract){
            investedBalance = investedBalance.add(amount);
        } else {
            investedBalance = investedBalance.sub(amount);
        }
    }

    function provide(uint minMint) external payable override onlyGuests returns (uint amountToMint) {
        uint amount = msg.value;
        uint supply = totalSupply();
        uint balance = totalBalance();

        if(supply > 0 && balance > 0) {
            amountToMint = amount.mul(supply).div(balance.sub(msg.value));
        } else {
            amountToMint = amount.mul(RATE);
        }

        require(amountToMint >= minMint, "2ndary::CapitalPool::deposit::minMint-too-high");

        lastProvideTimestamp[msg.sender] = block.timestamp;
        _mint(msg.sender, amountToMint);

        emit Provide(msg.sender, amount, amountToMint);
    }

    function withdraw(uint amount, uint maxBurn) external override returns (uint amountToBurn) {
        require(amount <= availableBalance(), "2ndary::CapitalPool::withdraw::not-enough-available-funds");
        require(lastProvideTimestamp[msg.sender].add(lockupPeriod) <= block.timestamp, "2ndary::CapitalPool::withdraw::funds-are-locked");
                
        amountToBurn = divCeil(amount.mul(totalSupply()), totalBalance());

        require(amountToBurn <= maxBurn, "2ndary::CapitalPool::withdraw::maxBurn-too-low");
        require(amountToBurn <= balanceOf(msg.sender), "2ndary::CapitalPool::withdraw::amount-is-too-large");
        require(amountToBurn > 0, "2ndary::CapitalPool::withdraw::amountToBurn-too-low");

        _burn(msg.sender, amountToBurn);

        payable(msg.sender).transfer(amount);
        
        emit Withdraw(msg.sender, amount, amountToBurn);
    }

    function shareOf(address user) external view returns (uint share){
        uint supply = totalSupply();
        if(supply > 0)
            share = totalBalance().mul(balanceOf(user)).div(supply);
        else
            share = 0;
    }

    function totalBalance() public view override returns (uint) {
        return address(this).balance.add(investedBalance);
    } 

    function availableBalance() public view override returns (uint) {
        // all the balance because "locked Balance" is paid to option holders (out of the contract)
        return address(this).balance;
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (
            lastProvideTimestamp[from].add(lockupPeriod) > block.timestamp &&
            lastProvideTimestamp[from] > lastProvideTimestamp[to]
        ) {
            require(
                !_revertTransfersInLockUpPeriod[to],
                "2ndary::CapitalPool::transfer::blocked-funds-not-accepted"
            );
            lastProvideTimestamp[to] = lastProvideTimestamp[from];
        }
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        if (a % b != 0)
            c = c + 1;
        return c;
    }

    modifier onlyCapitalManager {
        require(address(capitalManager) == msg.sender, "2ndary::onlyManager::invalid-capital-manager");
        _;
    }

    modifier onlyGuests {
        require(guests[msg.sender] || !guestlistIsActive, "2ndary::onlyGuests::not-invited");
        _;
    }
}