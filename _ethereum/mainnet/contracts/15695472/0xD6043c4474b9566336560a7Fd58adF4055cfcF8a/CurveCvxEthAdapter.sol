// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";
import "./IExchangeAdapter.sol";

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase
interface ICurveCvxEth {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        uint256 i,
        uint256 _min_received
    ) external returns (uint256);
}

contract CurveCvxEthAdapter is IExchangeAdapter {
    address public constant cvxEthLp = 0x3A283D9c08E8b55966afb64C515f5143cf907611;
    ICurveCvxEth public constant cvxEthPool =
        ICurveCvxEth(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);


    function indexByCoin(address coin) public pure returns (uint256) {
        if (coin == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return 1; // weth
        if (coin == 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B) return 2; // cvx
        return 0;
    }

    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        ICurveCvxEth curve = ICurveCvxEth(pool);
        if (toToken == cvxEthLp) {
            uint128 i = uint128(indexByCoin(fromToken));
            require(i != 0, "CurveCvxEthAdapter: Can't Swap");
            uint256[2] memory entryVector;
            entryVector[i - 1] = amount;
            return curve.add_liquidity(entryVector, 0);
        } else if (fromToken == cvxEthLp) {
            uint256 i = indexByCoin(toToken);
            require(i != 0, "CurveCvxEthAdapter: Can't Swap");
            return curve.remove_liquidity_one_coin(amount, i-1, 0);
        } else {
            revert("CurveCvxEthAdapter: Can't Swap");
        }
    }

    // 0xe83bbb76  =>  enterPool(address,address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256) {
        revert("CurveCvxEthAdapter: Can't Swap");
    }

    // 0x9d756192  =>  exitPool(address,address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256) {
        revert("CurveCvxEthAdapter: Can't Swap");
    }
}