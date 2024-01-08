// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./ICCFactory.sol";
import "./ICCPair.sol";

contract Migrator is Ownable {
    address public chef;
    address public oldFactory;
    ICCFactory public factory;
    uint256 public notBeforeBlock;
    uint256 public desiredLiquidity = uint256(-1);

    constructor(
        address _chef,
        address _oldFactory,
        uint256 _notBeforeBlock
    ) public {
        require(_chef != address(0), "Migrator: _chef is zero address");
        require(_oldFactory != address(0), "Migrator: _oldFactory is zero address");
        chef = _chef;
        oldFactory = _oldFactory;
        notBeforeBlock = _notBeforeBlock;
    }

    function setFactory(ICCFactory _factory) public onlyOwner {
        require(address(_factory) != address(0), "Migrator: zero address");
        factory = _factory;
    }

    function migrate(IUniswapV2Pair orig) public returns (ICCPair) {
        require(msg.sender == chef, "Migrator: not from master chef");
        require(block.number >= notBeforeBlock, "Migrator: too early to migrate");
        require(orig.factory() == oldFactory, "Migrator: not from old factory");
        require(address(factory) != address(0), "Migrator: factory address can not be zero");
        address token0 = orig.token0();
        address token1 = orig.token1();
        ICCPair pair = ICCPair(factory.getPair(token0, token1));
        if (pair == ICCPair(address(0))) {
            pair = ICCPair(factory.createPair(token0, token1));
        }
        uint256 lp = orig.balanceOf(msg.sender);
        if (lp == 0) return pair;
        desiredLiquidity = lp;
        orig.transferFrom(msg.sender, address(orig), lp);
        orig.burn(address(pair));
        pair.mint(msg.sender);
        desiredLiquidity = uint256(-1);
        return pair;
    }
}