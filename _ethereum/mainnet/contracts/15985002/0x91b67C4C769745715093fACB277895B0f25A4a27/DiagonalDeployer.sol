// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./IDiagonalDeployer.sol";

/**
 * @title  DiagonalDeployer contract
 * @author Diagonal Finance
 */
contract DiagonalDeployer is IDiagonalDeployer {
    /// @inheritdoc IDiagonalDeployer
    function deploy(bytes memory code, uint256 salt) external override returns (address addr) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, salt);
    }

    /// @inheritdoc IDiagonalDeployer
    function getAddress(bytes memory code, uint256 salt) external view override returns (address addr) {
        bytes32 _hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code)));
        addr = address(uint160(uint256(_hash)));
    }
}
