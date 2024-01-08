// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IYANGDepositCallBack.sol";

interface IYangNFTVault is IYANGDepositCallBack {
    struct SubscribeParam {
        uint256 yangId;
        uint256 chiId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    struct UnSubscribeParam {
        uint256 yangId;
        uint256 chiId;
        uint256 shares;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    struct SubscribeSingleParam {
        uint256 yangId;
        uint256 chiId;
        bool zeroForOne;
        uint256 exactAmount;
        uint256 maxTokenAmount;
        uint256 minShares;
    }

    struct UnSubscribeSingleParam {
        uint256 yangId;
        uint256 chiId;
        bool zeroForOne;
        uint256 shares;
        uint256 amountOutMin;
    }

    event AcceptOwnerShip(address owner, address nextowner);
    event MintYangNFT(address recipient, uint256 tokenId);
    event Subscribe(uint256 yangId, uint256 chiId, uint256 share);
    event UnSubscribe(
        uint256 yangId,
        uint256 chiId,
        uint256 amount0,
        uint256 amount1
    );

    function setCHIManager(address) external;

    function mint(address recipient) external returns (uint256 tokenId);

    function subscribe(SubscribeParam memory params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 share
        );

    function unsubscribe(UnSubscribeParam memory params) external;

    function subscribeSingle(SubscribeSingleParam memory params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 share
        );

    function unsubscribeSingle(UnSubscribeSingleParam memory params) external;

    // view
    function getShares(
        uint256 chiId,
        uint256 amount0Desired,
        uint256 amount1Desired
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAmounts(uint256 chiId, uint256 shares)
        external
        view
        returns (uint256, uint256);

    function checkMaxUSDLimit(uint256 chiId) external view returns (bool);

    // positions
    function positions(uint256 yangId, uint256 chiId)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 shares
        );

    function getTokenId(address recipient) external view returns (uint256);
}
