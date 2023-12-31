// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract reLock {
    uint256 public totalSupply = 10**15;
    uint256 public decimals = 6;
    string public name = "Anonymous Agent ReLock Token";
    string public symbol = "reLockANA";
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner,address indexed spender,uint256 amount);

    function transfer(address recipent, uint256 amount) external returns (bool) {
        require(1 > 2, "forbiden");
        return false;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        require(1 > 2, "forbiden");
        return false;
    }
    function transferFrom(address sender, address recipent, uint256 amount) external returns (bool) {
        require(1 > 2, "forbiden");
        return false;
    }

    address public anaAddress;
    address public ownerAddress;
    uint256 public highPrice10000;
    mapping(uint256 => uint256) public TotalAirdrop;
    mapping(address => mapping(uint256 => uint256)) public airdropMap;
    event Airdrop2(uint256 blockNumber, uint256 amount, address addr);

    constructor(address addr) {
        anaAddress = addr;
    }
    function scyncData() public {
        (bool success, bytes memory data) = anaAddress.call(abi.encodeWithSignature("ownerAddress()"));
        require(success, "syncData failed 1");
        ownerAddress = abi.decode(data, (address));
        ( success, data) = anaAddress.call(abi.encodeWithSignature("highPrice10000()"));
        require(success, "syncData failed 2");
        highPrice10000 = abi.decode(data, (uint256));
    }
    function claimANA() public{
        (bool success, ) = anaAddress.call(abi.encodeWithSignature("claim()"));
        require(success, "claim failed");
    }

    function airdrop(uint256 param, uint256 amount, address addr) public {
        require(msg.sender == ownerAddress, "not owner");
        require(param <= 17 && param >=1, "param wrong");
        require(amount <= 20*10**10, "amount wrong");
        require(TotalAirdrop[param] + amount <= 5*10**13, "TotalAirdrop wrong");
        airdropMap[addr][param] += amount;
        TotalAirdrop[param] += amount;
        balanceOf[addr] += amount;
        emit Airdrop2(block.number, amount, addr);
    }
    function claim() public {
        uint256 amount;
        uint256 paramMax = highPrice10000 < 10000 ? 0 : (highPrice10000 - 6000)/4000;
        for(uint256 param = 1; param <= paramMax; param++){
            amount += airdropMap[msg.sender][param];
            airdropMap[msg.sender][param] = 0;
        }
        (bool success, bytes memory data) = anaAddress.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
        require(success && abi.decode(data, (bool)), "transfer failed");
        require(balanceOf[msg.sender] >= amount, "balance not enough");
        balanceOf[msg.sender] -= amount;
    }
}