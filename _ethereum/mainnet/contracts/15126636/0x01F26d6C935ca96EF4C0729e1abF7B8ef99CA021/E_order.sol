// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;
import "./draft-EIP712.sol";

// npx hardhat run scripts/1_E_main.js  --network eth
// npx hardhat verify 0x01F26d6C935ca96EF4C0729e1abF7B8ef99CA021 --network eth

// contract B_order{
contract E_order is EIP712{
    constructor() EIP712("VII_order", "1")
    {
        owner=0x2e5DF740448e2a83d1C54aC3b4201AC72B4d793d;
        service=0x9fAf461C1720A875Be2A5909e2Ea405660A9d6A2;
    }

    address immutable private owner;
    address immutable private service;
    
    address constant public usdc=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant private weth=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant private pair=0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("order(uint256 order,uint256 amount,uint256 deadline)");

    event Order(uint256 indexed order,uint256 indexed amount);
    mapping(uint256=>uint256) public order_state;

    function eorder(uint256 order,uint256 amount ,uint256 deadline ,uint8 v,bytes32 r,bytes32 s)payable public{
        require(tx.origin==msg.sender,"order: can't use contract");
        require(deadline>block.timestamp,"order: time error");
        check(order,amount,deadline,v,r,s);
        uint256 eamount;
        unchecked{
            eamount = amount*uethprice()/10**IERC20(usdc).decimals();
            require(msg.value>=eamount,"order: error eth amount");
            payable(msg.sender).transfer(msg.value-eamount);
            payable(owner).transfer(address(this).balance);
            require(order_state[order]==0,"order: order completed");
            order_state[order] = amount*(10**(18-IERC20(usdc).decimals()));
        }
        emit Order(order,order_state[order]);
    }

    function uorder(uint256 order,uint256 amount ,uint256 deadline ,uint8 v,bytes32 r,bytes32 s)public{
        require(deadline>block.timestamp,"order: time error");
        check(order,amount,deadline,v,r,s);
        IERC20(usdc).transferFrom(msg.sender,owner,amount);
        require(order_state[order]==0,"order: order completed");
        unchecked{
            order_state[order] = amount*(10**(18-IERC20(usdc).decimals()));
        }
        emit Order(order,amount);
    }

    function check(uint256 order,uint256 amount ,uint256 deadline ,uint8 v,bytes32 r,bytes32 s)private view{
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, order, amount, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == service, "order: signer invalid signature");
    }
    function uethprice()view public returns(uint256 price){
        unchecked{
            price = IERC20(weth).balanceOf(pair)*
            10**IERC20(usdc).decimals()/
            IERC20(usdc).balanceOf(pair);
        }
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}