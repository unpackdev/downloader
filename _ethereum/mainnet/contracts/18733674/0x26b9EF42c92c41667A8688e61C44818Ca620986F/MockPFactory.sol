// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./MockPToken.sol";
import "./IPFactory.sol";

contract MockPFactory is IPFactory, Ownable {
    address public hub;

    function deploy(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) public payable returns (address) {
        address pTokenAddress = address(
            new MockPToken{salt: hex"0000000000000000000000000000000000000000000000000000000000000000"}(
                underlyingAssetName,
                underlyingAssetSymbol,
                underlyingAssetDecimals,
                underlyingAssetTokenAddress,
                underlyingAssetNetworkId,
                hub
            )
        );

        emit PTokenDeployed(pTokenAddress);
        return pTokenAddress;
    }

    function getBytecode(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) public view returns (bytes memory) {
        bytes memory bytecode = type(MockPToken).creationCode;

        return
            abi.encodePacked(
                bytecode,
                abi.encode(
                    underlyingAssetName,
                    underlyingAssetSymbol,
                    underlyingAssetDecimals,
                    underlyingAssetTokenAddress,
                    underlyingAssetNetworkId,
                    hub
                )
            );
    }

    function getPTokenAddress(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) public view returns (address) {
        bytes memory bytecode = getBytecode(
            underlyingAssetName,
            underlyingAssetSymbol,
            underlyingAssetDecimals,
            underlyingAssetTokenAddress,
            underlyingAssetNetworkId
        );

        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                hex"0000000000000000000000000000000000000000000000000000000000000000",
                                keccak256(bytecode)
                            )
                        )
                    )
                )
            );
    }

    function setHub(address hub_) external onlyOwner {
        hub = hub_;
    }
}
