//SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./BaseHelioswapFactory.sol";
import "./IHelioswapDeployer.sol";
import "./IHelioswapFactory.sol";
import "./IHelioswap.sol";
import "./UniERC20.sol";
import "./Helioswap.sol";

contract HelioswapFactory is IHelioswapFactory, BaseHelioswapFactory {
    using UniERC20 for IERC20;

    event Deployed(
        Helioswap indexed swap,
        IERC20 indexed token1,
        IERC20 indexed token2
    );

    IHelioswapDeployer public swapDeployer;
    address public poolOwner;
    Helioswap[] public allPools;
    mapping(Helioswap => bool) public override isPool;
    mapping(IERC20 => mapping(IERC20 => IHelioswap)) private _pools;

    constructor(
        address _poolOwner,
        IHelioswapDeployer _swapDeployer,
        address _mothership
    ) public BaseHelioswapFactory(_mothership) {
        poolOwner = _poolOwner;
        swapDeployer = _swapDeployer;
    }

    function getAllPools() external view returns (Helioswap[] memory) {
        return allPools;
    }

    function pools(IERC20 tokenA, IERC20 tokenB)
        external
        view
        override
        returns (IHelioswap pool, uint256 decayPeriod, uint256 fee, uint256 slippageFee, VirtualBalance.Data[2] memory virtualBalancesForAddition, VirtualBalance.Data[2] memory virtualBalancesForRemoval)
    {
        (IERC20 token1, IERC20 token2) = sortTokens(tokenA, tokenB);
        pool = _pools[token1][token2];
        if (address(pool) != address(0)) {
            decayPeriod = pool.decayPeriod();
            fee = pool.fee();
            slippageFee = pool.slippageFee();
            virtualBalancesForAddition[0] = pool.virtualBalancesForAddition(token1);
            virtualBalancesForAddition[1] = pool.virtualBalancesForAddition(token2);
            virtualBalancesForRemoval[0] = pool.virtualBalancesForRemoval(token1);
            virtualBalancesForRemoval[1] = pool.virtualBalancesForRemoval(token2);
        }
    }

    function deploy(IERC20 tokenA, IERC20 tokenB)
        public
        returns (Helioswap pool)
    {
        require(tokenA != tokenB, "HelioswapFactory: not support same tokens");
        (IERC20 token1, IERC20 token2) = sortTokens(tokenA, tokenB);
        require(
            _pools[token1][token2] == IHelioswap(0),
            "HelioswapFactory: pool already exists"
        );

        string memory symbol1 = token1.uniSymbol();
        string memory symbol2 = token2.uniSymbol();

        pool = swapDeployer.deploy(
            token1,
            token2,
            string(
                abi.encodePacked(
                    "TokenStand Liquidity Pool (",
                    symbol1,
                    "-",
                    symbol2,
                    ")"
                )
            ),
            string(abi.encodePacked("standLP-", symbol1, "-", symbol2)),
            poolOwner
        );

        _pools[token1][token2] = IHelioswap(address(pool));
        allPools.push(pool);
        isPool[pool] = true;

        emit Deployed(pool, token1, token2);
    }

    function sortTokens(IERC20 tokenA, IERC20 tokenB)
        public
        pure
        returns (IERC20, IERC20)
    {
        if (tokenA < tokenB) {
            return (tokenA, tokenB);
        }
        return (tokenB, tokenA);
    }
}
