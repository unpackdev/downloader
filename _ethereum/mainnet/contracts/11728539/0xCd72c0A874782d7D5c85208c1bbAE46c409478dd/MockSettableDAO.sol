/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./Decimal.sol";
import "./IDAO.sol";

contract MockSettableDAO is IDAO {
    uint256 internal _epoch;
    address internal _oracle;

    function set(uint256 epoch) external {
        _epoch = epoch;
    }

    function setOracle(address oracle) external {
        _oracle = oracle;
    }

    function oracle() external view returns (IOracle) {
        return IOracle(_oracle);
    }

    function epoch() external view returns (uint256) {
        return _epoch;
    }

    function bootstrappingAt(uint256 i) external view returns (bool) {
        return i < 5;
    }

    function oracleCaptureP() public returns (Decimal.D256 memory price) {
        (price, ) = IOracle(_oracle).capture();
    }
}
