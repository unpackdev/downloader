// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 IEXEC BLOCKCHAIN TECH                                       *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./draft-EIP712.sol";

/*
 * This SaltyForwarder contract is based on OpenZeppelin's MinimalForwarder:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/metatx/MinimalForwarder.sol
 *
 * This forwarder use salts (instead of nonces) which still protect against replay attacks
 * but is compatible with contracts that does not require transaction ordering
 *
 * Original note from the OpenZeppelin team:
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 *
 * MinimalForwarder is mainly meant for testing, as it is missing features to be a good production-ready forwarder. This
 * contract does not intend to have all the properties that are needed for a sound forwarding system. A fully
 * functioning forwarding system with good properties requires more complexity. We suggest you look at other projects
 * such as the GSN which do have the goal of building a system like that.
 */
contract SaltyForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        bytes32 salt;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,bytes32 salt,bytes data)"
        );

    //Note: Might use Bitmap at some point for a more gas-saving approach
    mapping(address => mapping(bytes32 => bool)) private _consumedSalts;

    constructor() EIP712("SaltyForwarder", "0.0.1") {}

    function isConsumedSalt(address from, bytes32 salt) public view returns (bool) {
        return _consumedSalts[from][salt];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature)
        public
        view
        returns (bool)
    {
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _TYPEHASH,
                    req.from,
                    req.to,
                    req.value,
                    req.gas,
                    req.salt,
                    keccak256(req.data)
                )
            )
        ).recover(signature);
        return !isConsumedSalt(req.from, req.salt) && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(
            verify(req, signature),
            "SaltyForwarder: invalid signature or salt"
        );
        _consumedSalts[req.from][req.salt] = true;

        (bool success, bytes memory returndata) = req.to.call{
            gas: req.gas,
            value: req.value
        }(abi.encodePacked(req.data, req.from));

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
}
