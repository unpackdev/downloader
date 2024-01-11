// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "./ECDSA.sol";

import "./ITokens.sol";

contract GatewayMinter {
    using ECDSA for bytes32;

    address public starkExchangeAddress;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setStarkExchangeAddress(address _starkExchangeAddress) public {
        require(
            starkExchangeAddress == address(0),
            "stark exchange already set"
        );
        starkExchangeAddress = _starkExchangeAddress;
    }

    function mintForSelf(
        bytes calldata blob,
        bytes32 metadata,
        bytes calldata signature
    ) public {
        (ITokens tokensContract, bytes memory tokenBlob) = _decode(blob);

        require(
            tokensContract.hasRole(
                MINTER_ROLE,
                keccak256(abi.encode(blob, metadata))
                    .toEthSignedMessageHash()
                    .recover(signature)
            ),
            "Invalid signature"
        );

        tokensContract.mint(tokenBlob, metadata, address(this));
    }

    function mintFor(
        address destination,
        uint256 amount,
        bytes calldata blob
    ) public {
        require(amount == 1, "The amount can only be 1");
        require(
            msg.sender == starkExchangeAddress,
            "This can only be called by the gateway contract"
        );

        (ITokens tokensContract, bytes memory tokenBlob) = _decode(blob);

        tokensContract.transfer(address(this), destination, tokenBlob);
    }

    function _decode(bytes calldata blob)
        internal
        pure
        returns (ITokens, bytes memory)
    {
        (address contractAddress, bytes memory tokenBlob) = abi.decode(
            blob,
            (address, bytes)
        );

        return (ITokens(contractAddress), tokenBlob);
    }
}
