// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./INonfungiblePositionManager.sol";
import "./IERC20.sol";

// 0xC36442b4a4522E871399CD717aBDD847Ab11FE88

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract Coin {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Coin";
    string public symbol = "C";
    uint8 public decimals = 18;

    INonfungiblePositionManager public nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() {
      nonfungiblePositionManager.createAndInitializePoolIfNecessary(address(this), WETH, 10000, 560222869268382347287321900);
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) public returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) public {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) public {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function mintNewPosition(
        uint amount0ToAdd,
        uint amount1ToAdd,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Min,
        uint256 amount1Min
    ) public returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1) {
        transferFrom(msg.sender, address(this), amount0ToAdd);
        IERC20(WETH).transferFrom(msg.sender, address(this), amount1ToAdd);

        approve(address(nonfungiblePositionManager), amount0ToAdd);
        IERC20(WETH).approve(address(nonfungiblePositionManager), amount1ToAdd);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: address(this),
                token1: WETH,
                fee: fee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount0ToAdd,
                amount1Desired: amount1ToAdd,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                recipient: address(this),
                deadline: block.timestamp
            });

        (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(
            params
        );
    }


    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}
