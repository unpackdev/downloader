pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

import "./IERC721.sol";

// import "./console.sol";

abstract contract card_with_card {
    struct saleInfo {
        address token_address;
        uint256 start;
        uint256 end;
        uint256 price;
        uint256 max_per_user;
        uint256 total;
        bool oneForOne;
        bytes signature;
    }

    address cwc_signer;

    constructor(address _signer) {
        cwc_signer = _signer;
    }

    function _mintCards(uint256 numberOfCards, address recipient)
        internal
        virtual;

    function _mintDiscountCards(uint256 numberOfCards, address recipient)
        internal
        virtual;

    function _mintDiscountPayable(
        uint256 numberOfCards,
        address recipient,
        uint256 price
    ) internal virtual;

    function _mintPayable(
        uint256 numberOfCards,
        address recipient,
        uint256 price
    ) internal virtual;

    function verify(saleInfo calldata sp) internal view returns (bool) {
        require(sp.token_address != address(0), "INVALID_TOKEN_ADDRESS");
        bytes memory cat =
            abi.encode(
                sp.token_address,
                sp.start,
                sp.end,
                sp.price,
                sp.max_per_user,
                sp.total,
                sp.oneForOne
            );

        bytes32 hash = keccak256(cat);

        require(sp.signature.length == 65, "Invalid signature length");
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        bytes memory signature = sp.signature;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }

        bytes32 data =
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
        address recovered = ecrecover(data, sigV, sigR, sigS);
        return cwc_signer == recovered;
    }
}
