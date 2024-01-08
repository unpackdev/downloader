// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ECDSA.sol";

import "./ERC721Main.sol";
import "./ExchangeProvider.sol";

contract FactoryErc721 is AccessControl, ExchangeProvider {
    bytes32 public SIGNER_ROLE = keccak256("SIGNER_ROLE");

    event ERC721Made(
        address newToken,
        string name,
        string symbol,
        address indexed signer
    );

    constructor(address _exchange) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _msgSender());
        exchange = _exchange;
    }

    function makeERC721(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address signer,
        bytes memory signature
    ) external {
        _verifySigner(signer, signature);
        ERC721Main newAddress = new ERC721Main(name, symbol, baseURI, signer);

        emit ERC721Made(address(newAddress), name, symbol, signer);
    }

    function _verifySigner(address signer, bytes memory signature)
        private
        view
    {
        address messageSigner =
            ECDSA.recover(keccak256(abi.encodePacked(signer)), signature);
        require(
            hasRole(SIGNER_ROLE, messageSigner),
            "FactoryErc721: Signer should sign transaction"
        );
    }
}
