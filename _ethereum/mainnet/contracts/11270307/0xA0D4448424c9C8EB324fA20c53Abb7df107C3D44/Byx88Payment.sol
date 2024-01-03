// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./IERC20.sol";

contract Byx88Payment {
    address payable public owner;
    IERC20 public usdt;

    constructor(address usdtAddress_) public {
        owner = msg.sender;
        usdt = IERC20(usdtAddress_);
    }

    struct Deposit {
        address sender;
        uint256 amount;
        bool reverted;
    }

    Deposit[] deposits;

    function fill() public payable restricted returns (bool) {
        emit FillBalance(msg.value);
        return true;
    }

    function take(uint256 amount) public restricted returns (bool) {
        require(
            address(this).balance >= amount,
            "Payment:Take: InsufficientBalance"
        );
        owner.transfer(amount);
        emit Take(owner, amount);
    }

    // execute deposit
    function deposit(address source, uint256 amount)
        public
        restricted
        returns (uint256)
    {
        uint256 id = deposits.length;
        bool result = usdt.transferFrom(source, address(this), amount);
        require(result, "Payment: FailedToDeposit");
        deposits.push(Deposit(source, amount, false));
        emit DepositInit(id, amount);
        return id;
    }

    function revert(uint256 id) public restricted returns (bool) {
        deposits[id].reverted = true;
        usdt.transfer(deposits[id].sender, deposits[id].amount);
        emit Revert(id);
        return true;
    }

    function withdraw(
        uint256 ref,
        address to,
        uint256 amount
    ) public restricted returns (bool) {
        usdt.transfer(to, amount);
        emit Withdraw(ref, to, amount);
        return true;
    }

    function getDeposit(uint256 id)
        public
        view
        returns (
            address sender,
            uint256 amount, // in wei
            bool reverted
        )
    {
        Deposit storage d = deposits[id];
        return (d.sender, d.amount, d.reverted);
    }

    function transferOwnership(address payable target) public restricted {
        owner = target;
    }

    // allow only owner
    modifier restricted() {
        require(msg.sender == owner, "Payment: Forbidden actions");
        _;
    }

    // id: deposit id
    event DepositInit(uint256 id, uint256 amount);

    // id: deposit id
    event Revert(uint256 id);

    // sender: eth account
    // source: gwallet account
    // amount: eth amount, in wei
    event Withdraw(uint256 ref, address to, uint256 amount);

    // transfer ETH to contract
    event FillBalance(uint256 amount);

    // transfer balance from contract to owner
    event Take(address payable to, uint256 amount);

    event ChangeOwner(address from, address to);
}
