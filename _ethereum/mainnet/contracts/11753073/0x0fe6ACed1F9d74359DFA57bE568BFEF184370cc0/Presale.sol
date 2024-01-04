// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IUniswapV2Router02.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";

import "./GameForth.sol";
import "./console.sol";

contract Presale is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => bool) public whitelist;

    uint256 public max = 2 ether;
    uint256 public min = 0.1 ether;
    uint256 public cap = 200 ether;
    uint256 public recev = 0;
    uint256 public gmePerEther = 0;
    address public uniswapRouter;

    uint256 private constant DECIMALS = 12; // 10^18 - 10^6 from rGME

    bool public active = false;
    GameForth public gameforth;

    uint256 lockPeriod = now + 60 days;

    constructor(uint256 _gmePerEther, address _uniswapRouter) public {
        gmePerEther = _gmePerEther;
        uniswapRouter = _uniswapRouter;
    }
    
    function presale() public payable returns (bool) {
        require(
            msg.value >= min && (balances[msg.sender].add(msg.value) <= max) && active && (recev < cap || whitelist[msg.sender]),
            "Value too small or too high or presale inactive"
        );
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        recev = recev + msg.value;

        uint256 alloc = msg.value.mul(3).div(10);
        
        payable(owner()).transfer(alloc);

        uint256 toTransfer = msg.value.div(10**DECIMALS).mul(gmePerEther).mul(13).div(100);
        gameforth.transfer(msg.sender, toTransfer);
    }

    function list() public onlyOwner() {
        uint256 numList = address(this).balance.div(10**DECIMALS).mul(gmePerEther.mul(8).div(10)).div(10);
        gameforth.approve(uniswapRouter, numList);
        gameforth.unlimit();
        IUniswapV2Router02(uniswapRouter).addLiquidityETH{
            value: address(this).balance
        }(
            address(gameforth),
            numList,
            numList,
            address(this).balance,
            address(this),
            block.timestamp + 600
        );

        burnRemaining();

        active = false;
    }

    function setGameForth(address payable addr) public onlyOwner {
        require(address(gameforth) == address(0), "already set");
        gameforth = GameForth(addr);
        active = true;
    }

    function addWhitelist(address payable addr) public onlyOwner {
        whitelist[addr] = true;
    }

    function endSale() public onlyOwner {
        gameforth.unlimit();
        active = false;
    }
    
    function addWhitelistMulti(address payable[] memory addrs) public onlyOwner {
        for (uint256 i=0; i< addrs.length; i++) {
            whitelist[addrs[i]] = true;
        }
    }

    function burnRemaining() public onlyOwner {
        gameforth.transfer(address(0), gameforth.balanceOf(address(this)));
    }

    function withdraw(address token, address to, uint256 amount) public onlyOwner {
        require(now > lockPeriod, "LP tokens have not been locked for long enough");
        IERC20(token).transfer(to, amount);
    }
}
