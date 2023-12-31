// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

// restriction: uint<n> n needs to be different for each type to support function overloading

// allows for chain ids up to 13 digits
type ChainId is bytes5;

using {
    eqChainId as ==,
    neqChainId as !=
}
    for ChainId global;

function eqChainId(ChainId a, ChainId b) pure returns(bool isSame) { return ChainId.unwrap(a) == ChainId.unwrap(b); }
function neqChainId(ChainId a, ChainId b) pure returns(bool isDifferent) { return ChainId.unwrap(a) != ChainId.unwrap(b); }

function toChainId(uint256 chainId) pure returns(ChainId) { return ChainId.wrap(bytes5(uint40(chainId)));}
function thisChainId() view returns(ChainId) { return toChainId(block.chainid); }

type Timestamp is uint40;

using {
    gtTimestamp as >,
    gteTimestamp as >=,
    ltTimestamp as <,
    lteTimestamp as <=,
    eqTimestamp as ==,
    neqTimestamp as !=
}
    for Timestamp global;

function gtTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) > Timestamp.unwrap(b); }
function gteTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) >= Timestamp.unwrap(b); }

function ltTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) < Timestamp.unwrap(b); }
function lteTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) <= Timestamp.unwrap(b); }

function eqTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) == Timestamp.unwrap(b); }
function neqTimestamp(Timestamp a, Timestamp b) pure returns(bool) { return Timestamp.unwrap(a) != Timestamp.unwrap(b); }

function toTimestamp(uint256 timestamp) pure returns(Timestamp) { return Timestamp.wrap(uint40(timestamp));}

// solhint-disable-next-line not-rely-on-time
function blockTimestamp() view returns(Timestamp) { return toTimestamp(block.timestamp); }

function zeroTimestamp() pure returns(Timestamp) { return toTimestamp(0); }

type Blocknumber is uint32;


interface IBaseTypes {

    function intToBytes(uint256 x, uint8 shift) external pure returns(bytes memory);

    function toInt(Blocknumber x) external pure returns(uint);
    function toInt(Timestamp x) external pure returns(uint);
    function toInt(ChainId x) external pure returns(uint);

    function blockNumber() external view returns(Blocknumber);
}