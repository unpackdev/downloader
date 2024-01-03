/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Source https://github.com/Uniswap/uniswap-v2-core
 * Subject to the GPL-3.0 license.
 */
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import "./IUniswapV2Factory.sol";
import "./UniswapV2Pair.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override owner;

    address public override whitelist;

    uint public override fee;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    // XXX: whitelisted routers
    mapping(address => bool) public override isRouter;
    modifier onlyRouter() {
        require(isRouter[msg.sender], 'UniswapV2: ROUTER PERMISSION DENIED');
        _;
    }

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _owner) public {
        owner = _owner;
    }

    // XXX: owner permission
    modifier onlyOwner() {
        require(msg.sender == owner, 'UniswapV2: FORBIDDEN');
        _;
    }

    function feeInfo() external override view returns (address, uint) {
        return (feeTo, fee);
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override onlyRouter returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // XXX: can only be called by the owner.
    function setFeeTo(address _feeTo) external override onlyOwner {
        feeTo = _feeTo;
    }

    // XXX: whitelist setter. Can only be called by the owner.
    function setWhitelist(address _whitelist) external override onlyOwner {
        whitelist = _whitelist;
    }

    // XXX: fee setter. Can only be called by the owner.
    function setFee(uint _fee) external override onlyOwner {
        require(_fee <= 1e18, 'UniswapV2: fee must be from 0 to 1e18');
        fee = _fee;
    }

    // XXX: router address setter. Can only be called by the owner.
    function setRouterPermission(address _router, bool _permission) external override onlyOwner {
        isRouter[_router] = _permission;
    }

    // XXX: new owner setter. Can only be called by the owner.
    function setOwner(address _owner) external override onlyOwner {
        owner = _owner;
    }

}
