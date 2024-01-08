// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IHandler.sol";
import "./Math.sol";
import "./SafeUint128.sol";
import "./AccessController.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract SushiswapHandler is AccessController, IHandler {
    using SafeERC20 for IERC20;

    struct Stake {
        bytes32 id;
        address staker;
        uint256 rootK;
        uint256 lpAmount;
        address poolAddress;
    }

    mapping(bytes32 => Stake) public stakes;

    event RootKUpdated(bytes32 stakeId, uint256 rookK);
    event Update(bytes32 id, uint256 depositTime, address handler, address pool);
    event Withdraw(bytes32 id, uint256 aquaPremium, uint256 tokenDifference, address pool);

    constructor(address primary, address index)
    AccessController( primary) {
        lpFeeTaker = index;
    }

    function update(
        bytes32 stakeId,
        uint256 lpAmount,
        address lpToken,
        bytes calldata data
    )
        external
        override
        onlyPrimaryContract
    {
        (address pool, address staker) = abi.decode(abi.encodePacked(data), (address, address));

        require(whitelistedPools[pool].status == true, "Sushiswap Handler :: POOL NOT WHITELISTED.");
        require(stakes[stakeId].rootK == 0, "Sushiswap Handler :: STAKE EXIST");
        require(lpToken == pool, "UNISWAP HANDLER :: POOL MISMATCH");

        (uint256 rootK, , ) = calculateTokenAndRootK(lpAmount, lpToken);
        Stake storage s = stakes[stakeId];
        s.rootK = rootK;
        s.staker = staker;
        s.poolAddress = lpToken;
        s.lpAmount = lpAmount;

        emit RootKUpdated(stakeId, rootK);
        emit Update(stakeId, block.timestamp, address(this), pool);
    }

    function withdraw(
        bytes32 id,
        uint256 tokenIdOrAmount,
        address contractAddress
    )
        external
        override
        onlyPrimaryContract
        returns (
            address[] memory token,
            uint256 premium,
            uint128[] memory tokenFees,
            bytes memory data
        )
    {
        uint256[] memory feesArr = new uint256[](2);
        token = new address[](2);
        tokenFees = new uint128[](2);

        (feesArr[0], feesArr[1], token[0], token[1]) = calculateFee(
            id,
            stakes[id].lpAmount,
            tokenIdOrAmount,
            contractAddress
        );

        premium = whitelistedPools[stakes[id].poolAddress].aquaPremium;

        transferLPTokens(tokenIdOrAmount, feesArr[0], feesArr[1], contractAddress, stakes[id].staker);

        tokenFees[0] = SafeUint128.toUint128(feesArr[0]);
        tokenFees[1] = SafeUint128.toUint128(feesArr[1]);

        if (stakes[id].lpAmount != tokenIdOrAmount) {
            stakes[id].lpAmount -= tokenIdOrAmount;
        } else {
            delete stakes[id];
        }

        return (token, premium, tokenFees, abi.encodePacked(stakes[id].poolAddress));
    }

    function transferLPTokens(
        uint256 amount,
        uint256 tokenFeesA,
        uint256 tokenFeesB,
        address lpToken,
        address staker
    ) internal onlyPrimaryContract {
        uint256 lpTokenFee = calculateLPToken(tokenFeesA, tokenFeesB, lpToken);
        IERC20(lpToken).safeTransfer(staker, amount - lpTokenFee);
        IERC20(lpToken).safeTransfer(lpFeeTaker, lpTokenFee);
    }

    function calculateLPToken(
        uint256 tokenFeesA,
        uint256 tokenFeesB,
        address lpToken
    ) public view returns (uint256 lpAmount) {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lpToken).getReserves();
        uint256 lpAmountA = (tokenFeesA * IUniswapV2Pair(lpToken).totalSupply()) / reserve0;
        uint256 lpAmountB = (tokenFeesB * IUniswapV2Pair(lpToken).totalSupply()) / reserve1;
        lpAmount = lpAmountA + lpAmountB;
    }

    function calculateFee(
        bytes32 id,
        uint256 lpAmount,
        uint256 lpUnstakeAmount,
        address lpToken
    )
        internal
        onlyPrimaryContract
        returns (
            uint256 tokenFeesA,
            uint256 tokenFeesB,
            address tokenA,
            address tokenB
        )
    {
        Stake storage s = stakes[id];
        uint256[] memory tokenAmountArr = new uint256[](3);

        uint256 lpPercentage = (lpUnstakeAmount * 10000) / lpAmount;
        (tokenAmountArr[0], tokenAmountArr[1], tokenAmountArr[2]) = calculateTokenAndRootK(lpAmount, lpToken);

        uint256 kDiff;
        uint256 newRootK;
        uint256 kOffset;

        if (tokenAmountArr[0] < s.rootK) {
            kDiff = (s.rootK - tokenAmountArr[0]);
            newRootK = s.rootK;
        } else {
            kDiff = tokenAmountArr[0] - s.rootK;
            newRootK = tokenAmountArr[0];
        }

        kOffset = kDiff;

        (tokenA, tokenB) = getPairTokens(lpToken);

        kDiff = (kDiff * lpPercentage) / 10000;

        // Calculate fee for token0 & token1
        tokenFeesA = (tokenAmountArr[1] * kDiff ) / s.lpAmount;
        tokenFeesB = (tokenAmountArr[2] * kDiff ) / s.lpAmount;

        (lpUnstakeAmount,,) = calculateTokenAndRootK(s.lpAmount- lpUnstakeAmount,lpToken);
        s.rootK = lpUnstakeAmount + kDiff - kOffset;

        emit RootKUpdated(id, s.rootK);
    }

    function calculateTokenAndRootK(uint256 lpAmount, address lpToken)
        public
        view
        returns (
            uint256 rootK,
            uint256 tokenAAmount,
            uint256 tokenBAmount
        )
    {
        uint256 totalSupply = IUniswapV2Pair(lpToken).totalSupply();
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lpToken).getReserves();
        tokenAAmount = (lpAmount * reserve0) / totalSupply;
        tokenBAmount = (lpAmount * reserve1) / totalSupply;
        rootK = Math.sqrt(tokenAAmount * tokenBAmount);
    }

    function getPairTokens(address lpToken) public view returns (address, address) {
        return (IUniswapV2Pair(lpToken).token0(), IUniswapV2Pair(lpToken).token1());
    }
}
