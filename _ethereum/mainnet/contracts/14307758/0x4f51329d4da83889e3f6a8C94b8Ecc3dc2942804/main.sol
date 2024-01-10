//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./helpers.sol";
import "./interface.sol";

contract Rebalancer is InstaFlashReceiver {
    constructor(
        address _flashloan,
        address _oneInchRouter,
        address _uniswapV3Router,
        address _nftManagerAddress
    )
        InstaFlashReceiver(
            _flashloan,
            _oneInchRouter,
            _uniswapV3Router,
            _nftManagerAddress
        )
    {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        bool simulate;
        uint256 tokenId;
        uint256 route;
        address owner;
        uint256[] memory _amount;
        address[] memory _tokens;
        bytes memory _callData;
        MintParams memory params;
        (
            simulate,
            tokenId,
            route,
            owner,
            _amount,
            _tokens,
            _callData,
            params
        ) = abi.decode(
            data,
            (
                bool,
                uint256,
                uint256,
                address,
                uint256[],
                address[],
                bytes,
                MintParams
            )
        );

        this.basicRebalancer(
            simulate,
            tokenId,
            route,
            owner,
            _amount,
            _tokens,
            _callData,
            params
        );

        return 0x150b7a02;
    }

    function basicRebalancer(
        bool simulate,
        uint256 tokenId,
        uint256 route,
        address owner,
        uint256[] memory _amount,
        address[] memory _tokens,
        bytes memory _callData,
        MintParams memory params
    ) public {
        bytes memory callData = abi.encode(
            simulate,
            tokenId,
            owner,
            _callData,
            params
        );

        this.flashBorrow(_tokens, _amount, route, callData);
    }
}

contract InstaBasicRebalancer is Rebalancer {
    constructor(
        address _flashloan,
        address _oneInchRouter,
        address _uniswapV3Router,
        address _nftManagerAddress
    )
        Rebalancer(
            _flashloan,
            _oneInchRouter,
            _uniswapV3Router,
            _nftManagerAddress
        )
    {}

    string public name = "InstaBasicRebalancer-v1.0";
}
