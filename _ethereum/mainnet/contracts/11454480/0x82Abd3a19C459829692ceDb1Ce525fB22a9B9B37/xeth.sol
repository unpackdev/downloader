// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.6.6;
// Copyright (C) 2015, 2016, 2017 Dapphub / adapted by udev 2020

import "./IXeth.sol";

contract XETH is IXeth {
    string public name;
    string public symbol;
    uint8  public decimals;
    address xlocker;
    uint public override totalSupply;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public override balanceOf;
    mapping (address => uint256)                    public override nonces;
    mapping (address => mapping (address => uint))  public override allowance;
    
    constructor() public {
        name = "xlock.eth Wrapped Ether";
        symbol = "XETH";
        decimals = 18;
        xlocker = msg.sender;
    }

    receive() external payable {
        deposit();
    }
    
    function deposit() public payable override {
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function transferXlocker(address xlocker_) external {
        require(xlocker==msg.sender, "xlocker!=msg.sender");
        xlocker = xlocker_;
    }

    function xlockerMint(uint wad, address dst) external override {
        require(msg.sender == xlocker, "!ulocker");
        balanceOf[dst] += wad;
        totalSupply += wad;
        emit Transfer(address(0), dst, wad);
    }
    
    function withdraw(uint wad) external override {
        require(balanceOf[msg.sender] >= wad, "!balance");
        balanceOf[msg.sender] -= wad;
        totalSupply -= wad;
        (bool success, ) = msg.sender.call{value:wad}("");
        require(success, "!withdraw");
        emit Withdrawal(msg.sender, wad);
    }
    
    function _approve(address src, address guy, uint wad) internal {
        allowance[src][guy] = wad;
        emit Approval(src, guy, wad);
    }
    
    function approve(address guy, uint wad) external override returns (bool) {
        _approve(msg.sender, guy, wad); 
        return true;
    }
    
    function transfer(address dst, uint wad) external override returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    
    function transferFrom(address src, address dst, uint wad)
        public override
        returns (bool)
    {
        require(balanceOf[src] >= wad, "!balance");

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "!allowance");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(block.timestamp <= deadline, "XETH::permit: Expired permit");

        uint256 chainId;
        assembly {chainId := chainid()}
        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)));

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline));

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                hashStruct));

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "XETH::permit: invalid permit");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}