// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma abicoder v2;

import "./AccessController.sol";
import "./SafeUint128.sol";
import "./PositionFee.sol";
import "./IHandler.sol";
import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Pool.sol";
import "./PositionKey.sol";
import "./SafeERC20.sol";

contract UniswapHandlerV3 is AccessController, IHandler {
    using SafeERC20 for IERC20;

    uint128 private constant MAX_AMOUNT = type(uint128).max;

    struct Stake {
        address staker;
        address poolAddress;
        uint256 tokenId;
    }

    mapping(bytes32 => Stake) public stakes;

    event Update(bytes32 id, uint256 depositTime, address handler, address pool);
    event Withdraw(bytes32 id, uint256 aquaPremium, uint128[] tokenDifference, address pool);

    constructor(address aquaPrimary, address indexFund) AccessController(indexFund) {
        AQUA_PRIMARY = aquaPrimary;
    }

    function update(
        bytes32 id,
        uint256 tokenValue,
        address contractAddress,
        bytes calldata data
    ) external override onlyAquaPrimary {
        (address pool, address staker) = abi.decode(data, (address, address));

        require(whitelistedPools[pool].status == true, "Uniswap handler :: Pool not whitelisted.");

        require(
            PositionFee.checkIdValidity(POSITION_MANAGER, tokenValue, pool),
            "Uniswap handler :: TokenID has a different pool."
        );

        Stake storage s = stakes[id];
        s.staker = staker;
        s.poolAddress = pool;
        s.tokenId = tokenValue;

        collectFees(tokenValue, staker);

        emit Update(id, block.timestamp, address(this), pool);
    }

    function collectFees(uint256 tokenId, address staker)
        internal
        returns (address[] memory token, uint128[] memory amounts)
    {
        token = new address[](2);
        amounts = new uint128[](2);

        (uint256 amount0, uint256 amount1) = PositionFee.getPositionDetails(tokenId, POSITION_MANAGER);

        if ((amount0 != 0) || (amount1 != 0)) {
            (, , token[0], token[1], , , , , , , , ) = INonfungiblePositionManager(POSITION_MANAGER).positions(tokenId);

            INonfungiblePositionManager.CollectParams memory params =
                INonfungiblePositionManager.CollectParams(tokenId, staker, MAX_AMOUNT, MAX_AMOUNT);

            (uint256 amount0u, uint256 amount1u) = INonfungiblePositionManager(POSITION_MANAGER).collect(params);

            amounts[0] = SafeUint128.toUint128(amount0u);
            amounts[1] = SafeUint128.toUint128(amount1u);
        }

        return (token, amounts);
    }

    function withdraw(
        bytes32 id,
        uint256 tokenIdOrAmount,
        address contractAddress
    )
        external
        override
        onlyAquaPrimary
        returns (
            address[] memory token,
            uint256 aquaPoolPremium,
            uint128[] memory tokenDiff,
            bytes memory data
        )
    {
        require(tokenIdOrAmount == stakes[id].tokenId, "Uniswap handler :: Invalid tokenID");
        uint24 fee = abi.decode(whitelistedPools[stakes[id].poolAddress].data, (uint24));
        aquaPoolPremium = whitelistedPools[stakes[id].poolAddress].aquaPremium;

        tokenDiff = new uint128[](2);
        token = new address[](2);

        (token, tokenDiff) = collectFees(tokenIdOrAmount, INDEX_FUND);

        IERC20(POSITION_MANAGER).safeTransferFrom(address(this), stakes[id].staker, tokenIdOrAmount);

        emit Withdraw(id, aquaPoolPremium, tokenDiff, stakes[id].poolAddress);

        delete stakes[id];

        return (token, aquaPoolPremium, tokenDiff, abi.encode(fee));
    }
}
