// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
//
// An identifier that can only be incremented by one.
//
pragma solidity 0.8.19;

type Id is uint256;
using {neq as !=, eq as ==, gt as >, gte as >=} for Id global;

Id constant ID_ZERO = Id.wrap(0);
Id constant ID_ONE = Id.wrap(1);
function neq(Id a, Id b) pure returns (bool) { return Id.unwrap(a) != Id.unwrap(b); }
function eq(Id a, Id b) pure returns (bool) { return Id.unwrap(a) == Id.unwrap(b); }
function gt(Id a, Id b) pure returns (bool) { return Id.unwrap(a) > Id.unwrap(b); }
function gte(Id a, Id b) pure returns (bool) { return Id.unwrap(a) >= Id.unwrap(b); }

library IdLib {
    function increment(Id id) internal pure returns (Id) {
        unchecked {
            return Id.wrap(Id.unwrap(id) + Id.unwrap(ID_ONE));
        }
    }

    function isSubsequent(Id a, Id b) internal pure returns (bool) {
        unchecked {
            return Id.unwrap(a) == Id.unwrap(b) + 1;
        }
    }
}
