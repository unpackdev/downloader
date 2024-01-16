// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./XENCrypto.sol";

contract XENMinter {

    // original contract marking to distinguish from proxy copies
    address private immutable _original;
    // pointer to XEN Crypto contract
    XENCrypto immutable public xenCrypto;
    // mapping: msg.sender => salt => minters count
    mapping(address => mapping(uint256 =>uint256)) public minters;

    constructor(address xenCrypto_) {
        require(xenCrypto_ != address(0));
        _original = address(this);
        xenCrypto = XENCrypto(xenCrypto_);
    }

    function callClaimRank(uint256 term) external {
        require(msg.sender == _original, 'unauthorized');
        bytes memory callData = abi.encodeWithSignature("claimRank(uint256)", term);
        (bool success, ) = address(xenCrypto).call(callData);
        require(success, 'call failed');
    }

    function callClaimMintReward(address to) external {
        require(msg.sender == _original, 'unauthorized');
        bytes memory callData = abi.encodeWithSignature("claimMintRewardAndShare(address,uint256)", to, uint256(100));
        (bool success, ) = address(xenCrypto).call(callData);
        require(success, 'call failed');
    }

    function bulkClaimRank0(uint256 count, uint256 term, uint256 salt_) external {
        bytes memory bytecode = bytes.concat(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            bytes20(address(this)),
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        require(count > 0, "Claim0: illegal count");
        require(term > 0, "Claim0: illegal term");
        bytes memory callData = abi.encodeWithSignature("callClaimRank(uint256)", term);
        uint256 start = minters[msg.sender][salt_] + 1;
        bool result = true;
        for (uint i = start; i < start + count; i++) {
            bytes32 salt = keccak256(abi.encodePacked(salt_, i, msg.sender));
            bool succeeded;
            assembly {
                let proxy := create2(
                    0,
                    add(bytecode, 0x20),
                    mload(bytecode),
                    salt)
                succeeded := call(
                    gas(),
                    proxy,
                    0,
                    add(callData, 0x20),
                    mload(callData),
                    0,
                    0
                )
            }
            result = result && succeeded;
        }
        require(result, "Claim0: Error while claiming rank");
        minters[msg.sender][salt_] += count;
    }

    function bulkClaimRank(uint256 count, uint256 term, uint256 salt_) external {
        bytes memory bytecode = bytes.concat(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            bytes20(address(this)),
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        require(count > 0, "Claim: illegal count");
        require(term > 0, "Claim: illegal term");
        uint256 start = minters[msg.sender][salt_] + 1;
        bytes memory callData = abi.encodeWithSignature("callClaimRank(uint256)", term);
        bool result = true;
        for (uint i = start; i < start + count; i++) {
            bytes32 salt = keccak256(abi.encodePacked(salt_, i, msg.sender));
            bool succeeded;
            bytes32 hash = keccak256(abi.encodePacked(hex'ff', address(this), salt, keccak256(bytecode)));
            address proxy = address(uint160(uint(hash)));
            assembly {
                succeeded := call(
                    gas(),
                    proxy,
                    0,
                    add(callData, 0x20),
                    mload(callData),
                    0,
                    0
                )
            }
            result = result && succeeded;
        }
        require(result, "Claim: Error while claiming rank");
        minters[msg.sender][salt_] += count;
    }

    function bulkClaimMintReward(uint256 count, address to, uint256 salt_) public {
        bytes memory bytecode = bytes.concat(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            bytes20(address(this)),
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        require(minters[msg.sender][salt_] > 0, 'Mint: No record');
        uint256 _count = count > 0 ? count + 1 : minters[msg.sender][salt_] + 1;
        bytes memory callData = abi.encodeWithSignature("callClaimMintReward(address)", to);
        uint256 result = 0;
        for (uint i = 1; result < _count - 1; i++) {
            bytes32 salt = keccak256(abi.encodePacked(salt_, i, msg.sender));
            bool succeeded;
            bytes32 hash = keccak256(abi.encodePacked(hex'ff', address(this), salt, keccak256(bytecode)));
            address proxy = address(uint160(uint(hash)));
            assembly {
                succeeded := call(
                    gas(),
                    proxy,
                    0,
                    add(callData, 0x20),
                    mload(callData),
                    0,
                    0
                )
            }
            if (succeeded) {
                result++;
            }
        }
        require(result > 0, "Mint: Error while claiming rewards");
        minters[msg.sender][salt_] -= result;
    }

    function bulkClaimMintReward(address to, uint256 salt_) external {
        bulkClaimMintReward(0, to, salt_);
    }

}
