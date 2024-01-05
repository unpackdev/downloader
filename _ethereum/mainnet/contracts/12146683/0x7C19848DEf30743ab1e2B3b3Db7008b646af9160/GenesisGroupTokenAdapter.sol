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
 * @dev GenesisGroup contract interface.
 * Only the functions required for GenesisGroupTokenAdapter contract are added.
 */
interface GenesisGroup {
    function getAmountOut(uint256 amountIn, bool inclusive)
    external
    view
    returns (uint256 feiAmount, uint256 tribeAmount);
}


/**
 * @title Token adapter for FGEN.
 * @dev Implementation of TokenAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract GenesisGroupTokenAdapter is TokenAdapter {

    address internal constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    address internal constant TRIBE = 0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B;


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
     * @return Array of Component structs with underlying tokens rates for the given asset.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token) external view override returns (Component[] memory) {
        (uint256 feiAmount, uint256 tribeAmount) = GenesisGroup(token).getAmountOut(1e18, true);

        Component[] memory underlyingTokens = new Component[](2);

        underlyingTokens[0] = Component({
            token: FEI,
            tokenType: "ERC20",
            rate: feiAmount
        });
        underlyingTokens[1] = Component({
            token: TRIBE,
            tokenType: "ERC20",
            rate: tribeAmount
        });

        return underlyingTokens;
    }
}
