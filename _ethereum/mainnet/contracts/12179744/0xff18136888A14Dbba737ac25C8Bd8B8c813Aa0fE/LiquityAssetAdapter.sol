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
 * @dev TroveManager contract interface.
 * Only the functions required for LiquityAssetAdapter contract are added.
 * The TroveManager contract is available here
 * https://github.com/liquity/beta/blob/main/contracts/TroveManager.sol.
 */
interface TroveManager {
    function getTroveColl(address _borrower) external view returns (uint);
}


/**
 * @title Asset adapter for Liquity protocol.
 * @dev Implementation of ProtocolAdapter interface.
 * @author Igor Sobolev <sobolev@zerion.io>
 */
contract LiquityAssetAdapter is ProtocolAdapter {

    string public constant override adapterType = "Asset";

    string public constant override tokenType = "ERC20";

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant TROVE_MANAGER = 0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2;

    /**
     * @return Amount of collateral locked on the protocol by the given account.
     * @dev Implementation of ProtocolAdapter interface function.
     */
    function getBalance(address token, address account) external view override returns (uint256) {
        if (token != ETH) {
            return 0;
        }

        return TroveManager(TROVE_MANAGER).getTroveColl(account);
    }
}
