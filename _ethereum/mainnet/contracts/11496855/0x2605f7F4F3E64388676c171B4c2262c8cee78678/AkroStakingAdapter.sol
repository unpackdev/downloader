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
import "./ProtocolAdapter.sol";


/**
 * @dev Staking contract interface.
 * Only the functions required for AkroStakingAdapter contract are added.
 */
interface Staking {
    function totalStakedFor(address) external view returns (uint256);
}


/**
 * @title Adapter for Akropolis Staking protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Alexander Mazaletskiy <am@akropolis.io>
 */
contract AkroStakingAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant STAKING = 0x3501Ec11d205fa249f2C42f5470e137b529b35D0;

    /**
     * @return Amount of AKRO locked on the protocol by the given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address, address account) external view override returns (uint256) {
        return Staking(STAKING).totalStakedFor(account);
    }
}
