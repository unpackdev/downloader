// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./Structs.sol";
import "./TokenAdapter.sol";


/**
 * @dev AToken contract interface.
 * Only the functions required for AaveTokenAdapter contract are added.
 * The AToken contract is available here
 * github.com/aave/aave-protocol/blob/master/contracts/tokenization/AToken.sol.
 */
interface AToken {
    function underlyingAssetAddress() external view returns (address);
}


/**
 * @title Token adapter for ATokens.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract AaveUniswapTokenAdapter is TokenAdapter {


    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @return TokenMetadata struct with ERC20-style token info.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getMetadata(address token) external view override returns (TokenMetadata memory) {
        return TokenMetadata({
            token: token,
            name: ERC20(token).name(),
            symbol: ERC20(token).symbol(),
            decimals: ERC20(token).decimals()
        });
    }

    /**
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        address underlying = AToken(token).underlyingAssetAddress();

        Component[] memory underlyingTokens = new Component[](1);
        string memory underlyingType;

        if (underlying == DAI ||
            underlying == USDC ||
            underlying == USDT ||
            underlying == ETH ) {
            underlyingType = "ERC20";
        } else {
            underlyingType = "Uniswap V1 pool token";
        }

        underlyingTokens[0] = Component({
            token: underlying,
            tokenType: underlyingType,
            rate: uint256(1e18)
        });

        return underlyingTokens;
    }
}
