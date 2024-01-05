// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

import "./Token.sol";
import "./IDerivativeSpecification.sol";

interface IVault {
    /// @notice vault initialization time
    function initializationTime() external view returns(uint256);
    /// @notice start of live period
    function liveTime() external view returns(uint256);
    /// @notice end of live period
    function settleTime() external view returns(uint256);

    /// @notice underlying value at the start of live period
    function underlyingStarts(uint index) external view returns(int256);
    /// @notice underlying value at the end of live period
    function underlyingEnds(uint index) external view returns(int256);

    /// @notice primary token conversion rate multiplied by 10 ^ 12
    function primaryConversion() external view returns(uint256);
    /// @notice complement token conversion rate multiplied by 10 ^ 12
    function complementConversion() external view returns(uint256);

    // @notice derivative specification address
    function derivativeSpecification() external view returns(IDerivativeSpecification);
    // @notice collateral token address
    function collateralToken() external view returns(IERC20);
    // @notice oracle address
    function oracles(uint index) external view returns(address);
    function oracleIterators(uint index) external view returns(address);

    // @notice primary token address
    function primaryToken() external view returns(IERC20);
    // @notice complement token address
    function complementToken() external view returns(IERC20);
}
