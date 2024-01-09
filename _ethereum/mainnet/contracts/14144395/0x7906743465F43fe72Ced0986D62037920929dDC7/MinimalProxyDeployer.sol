/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./MinimalMaker.sol";
import "./MinimalMakerWithCall.sol";

/**
 * @title MinimalProxyDeployer
 * @author yoonsung.eth
 * @notice Minimal Proxy를 배포하는 기능을 가진 라이브러리
 */
library MinimalProxyDeployer {
    function deploy(address template, bytes memory initializationCalldata) internal returns (address result) {
        bytes memory createCode = creation(template, initializationCalldata);

        (bytes32 salt, ) = getSaltAndTarget(createCode);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                0, // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(extcodesize(result)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function deploy(
        string memory seed,
        address template,
        bytes memory initializationCalldata
    ) internal returns (address result) {
        bytes memory createCode = creation(template, initializationCalldata);

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, seed));

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                0, // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(extcodesize(result)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function calculateAddress(address template, bytes memory initializationCalldata)
        internal
        view
        returns (address addr)
    {
        bytes memory createCode = creation(template, initializationCalldata);

        (, addr) = getSaltAndTarget(createCode);
    }

    function calculateAddress(
        string memory seed,
        address template,
        bytes memory initializationCalldata
    ) internal view returns (address addr) {
        bytes memory createCode = creation(template, initializationCalldata);

        addr = getTargetFromSeed(createCode, seed);
    }

    function isMinimal(address templateAddr, address target) internal view returns (bool result) {
        bytes20 templateAddrBytes = bytes20(templateAddr);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), templateAddrBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(target, other, 0, 0x2d)
            result := eq(mload(clone), mload(other))
        }
    }

    function getSaltAndTarget(bytes memory initCode) internal view returns (bytes32 salt, address target) {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        // set the initial nonce to be provided when constructing the salt.
        uint256 nonce = 0;

        // declare variable for code size of derived address.
        bool exist;

        while (true) {
            // derive `CREATE2` salt using `msg.sender` and nonce.
            salt = keccak256(abi.encodePacked(msg.sender, nonce));

            target = address( // derive the target deployment address.
                uint160( // downcast to match the address type.
                    uint256( // cast to uint to truncate upper digits.
                        keccak256( // compute CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                bytes1(0xff), // pass in the control character.
                                address(this), // pass in the address of this contract.
                                salt, // pass in the salt from above.
                                initCodeHash // pass in hash of contract creation code.
                            )
                        )
                    )
                )
            );

            // determine if a contract is already deployed to the target address.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                exist := gt(extcodesize(target), 0)
            }

            // exit the loop if no contract is deployed to the target address.
            if (!exist) {
                break;
            }

            // otherwise, increment the nonce and derive a new salt.
            nonce++;
        }
    }

    function getTargetFromSeed(bytes memory initCode, string memory seed) internal view returns (address target) {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, seed));

        target = address( // derive the target deployment address.
            uint160( // downcast to match the address type.
                uint256( // cast to uint to truncate upper digits.
                    keccak256( // compute CREATE2 hash using 4 inputs.
                        abi.encodePacked( // pack all inputs to the hash together.
                            bytes1(0xff), // pass in the control character.
                            address(this), // pass in the address of this contract.
                            salt, // pass in the salt from above.
                            initCodeHash // pass in hash of contract creation code.
                        )
                    )
                )
            )
        );
    }

    function creation(address addr, bytes memory initializationCalldata)
        private
        pure
        returns (bytes memory createCode)
    {
        createCode = initializationCalldata.length > 0
            ? abi.encodePacked(
                type(MinimalMakerWithCall).creationCode,
                abi.encode(address(addr), initializationCalldata)
            )
            : abi.encodePacked(type(MinimalMaker).creationCode, abi.encode(address(addr)));
    }
}
