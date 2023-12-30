// File: contracts/FairVoteProxy.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface MasterChef {
    function userInfo(uint256, address)
        external
        view
        returns (uint256, uint256);
}

contract FairVoteProxy {
    // ETH/FAIR UniswapV2 LP token
    IERC20 public constant votes = IERC20(
        0x8E9681Db59e2f6B5773c70F77Faa177BA9d2a592
    );

    // Fair's masterchef contract
    MasterChef public constant chef = MasterChef(
        0xDD343e9E6CBFC2EB8A402a576e360B39cdf33c1B
    );

    // Pool 11 is the ETH/FAIR UniswapV2 LP pool
    uint256 public constant pool = uint256(11);

    // Using 9 decimals as we're square rooting the votes
    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "Fair power";
    }

    function symbol() external pure returns (string memory) {
        return "FAIRPOWER";
    }

    function totalSupply() external view returns (uint256) {
        return sqrt(votes.totalSupply());
    }

    function balanceOf(address _voter) external view returns (uint256) {
        (uint256 _votes, ) = chef.userInfo(pool, _voter);
        return sqrt(_votes);
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    constructor() public {}
}