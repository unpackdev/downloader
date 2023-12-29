// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "./UD60x18.sol";

import "./ISubscriber.sol";

struct Signature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

interface IXenoMining is ISubscriber {
    function startCycle(Signature memory _signature, bytes memory _proof) external;
    function claim(uint256 _amount, address _receiver, Signature memory _signature, bytes memory _voucher) external;
    function setToken(string calldata _tokenName, address _tokenContract) external;

    function decodeVoucher(bytes memory voucher) external pure returns (address claimer, address contractAddress, bytes32 tokenHash, uint256 cycle, uint256 value);
    function claimedAmount(string calldata _tokenName, address _claimer) external view returns (uint256);
}
