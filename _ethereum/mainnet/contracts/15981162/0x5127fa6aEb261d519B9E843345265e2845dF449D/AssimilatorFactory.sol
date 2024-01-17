// SPDX-License-Identifier: MIT

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

pragma solidity ^0.7.3;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IOracle.sol";
import "./BaseToUsdAssimilator.sol";
import "./UsdcToUsdAssimilator.sol";

contract AssimilatorFactory is Ownable {
    event NewAssimilator(address indexed caller, bytes32 indexed id, address indexed assimilatorAddress);

    mapping(bytes32 => address) public assimilators;
    IOracle public immutable usdcOracle;
    IERC20 public immutable usdc;
    UsdcToUsdAssimilator public immutable usdcAssimilator;

    constructor(IOracle _usdcOracle, IERC20 _usdc) {
        usdcOracle = _usdcOracle;
        usdc = _usdc;

        usdcAssimilator = new UsdcToUsdAssimilator(_usdcOracle, _usdc);
    }

    function getAssimilator(address _base) external view returns (address) {
        bytes32 id = keccak256(abi.encode(_base, usdc));
        return (assimilators[id]);
    }

    function newBaseAssimilator(
        IERC20 _base,
        uint256 _baseDecimals,
        IOracle _baseOracle
    ) public onlyOwner returns (BaseToUsdAssimilator) {
        bytes32 id = keccak256(abi.encode(_base, usdc));
        if (assimilators[id] != address(0)) revert('AssimilatorFactory/already-exists');
        BaseToUsdAssimilator assimilator = new BaseToUsdAssimilator(_baseDecimals, _base, usdc, _baseOracle);
        assimilators[id] = address(assimilator);
        emit NewAssimilator(msg.sender, id, address(assimilator));
        return assimilator;
    }
}
