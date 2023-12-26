// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./MessageHashUtils.sol";

abstract contract StatefulSale is Ownable {
    error SaleStateNotActive();

    enum SaleState {
        CLOSED,
        MEMBERS_LIST,
        ALLOW_LIST,
        PUBLIC
    }

    event SaleStateChanged(
        SaleState newSaleState
    );

    address public immutable SIGNER;

    SaleState public saleState;

    constructor(address _signer) {
        SIGNER = _signer;
    }

    function setSaleState(SaleState _state)
        external
        onlyOwner
    {
        saleState = _state;
        emit SaleStateChanged(_state);
    }

    function isValidSignature(
        bytes calldata _signature,
        address _sender,
        uint256 _chainId,
        address _contract,
        SaleState _state,
        uint256 _mintLimit
    )
        public
        view
        returns (bool)
    {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(
            keccak256(
                abi.encode(
                    _sender,
                    _chainId,
                    _contract,
                    _state,
                    _mintLimit
                )
            )
        );
        return SIGNER == ECDSA.recover(hash, _signature);
    }
}
