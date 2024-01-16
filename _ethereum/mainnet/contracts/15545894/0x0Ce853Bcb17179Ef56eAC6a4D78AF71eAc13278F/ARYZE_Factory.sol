// SPDX-License-Identifier: MIT
pragma solidity =0.5.16;

import "./IARYZE_Factory.sol";
import "./ARYZE_Pair.sol";

//  ARYZE Factory Contract

contract ARYZE_Factory is IARYZE_Factory {
    address public feeToRYZEVault;
    address public feeToRewardsVault;
    address public RYZEVaultAdmin;
    address public RewardsVaultAdmin;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    constructor(address _RYZEVaultAdmin, address _RewardsVaultAdmin) public {
        RYZEVaultAdmin = _RYZEVaultAdmin;
        RewardsVaultAdmin = _RewardsVaultAdmin;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "ARYZE: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ARYZE: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "ARYZE: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(ARYZE_Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IARYZE_Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; /// populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeToRYZEVault(address _feeToRYZEVault) external {
        require(msg.sender == RYZEVaultAdmin, "ARYZE: FORBIDDEN");
        feeToRYZEVault = _feeToRYZEVault;
    }

    function setFeeToRewardsVault(address _feeToRewardsVault) external {
        require(msg.sender == RewardsVaultAdmin, "ARYZE: FORBIDDEN");
        feeToRewardsVault = _feeToRewardsVault;
    }

    function setRYZEVaultAdmin(address _RYZEVaultAdmin) external {
        require(msg.sender == RYZEVaultAdmin, "ARYZE: FORBIDDEN");
        RYZEVaultAdmin = _RYZEVaultAdmin;
    }

    function setRewardsVaultAdmin(address _RewardsVaultAdmin) external {
        require(msg.sender == RewardsVaultAdmin, "ARYZE: FORBIDDEN");
        RewardsVaultAdmin = _RewardsVaultAdmin;
    }
}
