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

import "./ProtocolAdapter.sol";


/**
 * @dev Tube contract interface.
 * Only the functions required for TubeProtocolAdapter contract are added.
 * The Tube contract is available here
 * etherscan.io/address/0x85BC2E8Aaad5dBc347db49Ea45D95486279eD918#code
 * 
 */
interface Tube {
    function mustOf(address holder) external view returns (uint256);
}


/**
 * @title Adapter for Tube protocol.
 * @dev Implementation of ProtocolAdapter interface.
 */
contract TubeProtocolAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant MUST = 0x9C78EE466D6Cb57A4d01Fd887D2b5dFb2D46288f;
    address internal constant TUBE = 0x85BC2E8Aaad5dBc347db49Ea45D95486279eD918;

    /**
     * @return Amount of TUBE for a given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        if (token == MUST) {
            return Tube(TUBE).mustOf(account);
        } else {
            return 0;
        }
    }
}
