/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./ReserveSwapper.sol";
import "./Implementation.sol";
import "./ReserveIssuer.sol";

/**
 * @title ReserveImpl
 * @notice Top-level Reserve contract that extends all other reserve sub-contracts
 * @dev This contract should be used an implementation contract for an AdminUpgradeabilityProxy
 */
contract ReserveImpl is IReserve, ReserveComptroller, ReserveIssuer, ReserveSwapper { }
