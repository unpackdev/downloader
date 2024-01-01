// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./ICheezburgerFactory.sol";
import "./ICheezburger.sol";
import "./CheezburgerStructs.sol";

abstract contract CheezburgerRegistry is CheezburgerStructs {
    /// @dev Convert a socialTokens entry back to Token
    function getSocialToken(
        ICheezburger _chzb,
        uint256 _id
    ) internal view returns (Token memory) {
        (
            address _uniswapFactory,
            address _uniswapRouter,
            address _uniswapPair,
            address _creator,
            address _leftSide,
            address _rightSide,
            LiquiditySettings memory _liquidity,
            DynamicSettings memory _fee,
            DynamicSettings memory _wallet,
            ReferralSettings memory _referral
        ) = _chzb.socialTokens(_id);

        return
            Token({
                factory: _uniswapFactory,
                router: _uniswapRouter,
                pair: _uniswapPair,
                creator: _creator,
                leftSide: _leftSide,
                rightSide: _rightSide,
                liquidity: _liquidity,
                fee: _fee,
                wallet: _wallet,
                referral: _referral
            });
    }

    /// @dev Convert a burgerRegistry entry back to Token
    function getToken(
        ICheezburgerFactory _factory,
        address _pairedToken
    ) internal view returns (Token memory) {
        (
            address _uniswapFactory,
            address _uniswapRouter,
            address _uniswapPair,
            address _creator,
            address _leftSide,
            address _rightSide,
            LiquiditySettings memory _liquidity,
            DynamicSettings memory _fee,
            DynamicSettings memory _wallet,
            ReferralSettings memory _referral
        ) = _factory.burgerRegistry(_pairedToken);

        return
            Token({
                factory: _uniswapFactory,
                router: _uniswapRouter,
                pair: _uniswapPair,
                creator: _creator,
                leftSide: _leftSide,
                rightSide: _rightSide,
                liquidity: _liquidity,
                fee: _fee,
                wallet: _wallet,
                referral: _referral
            });
    }
}
