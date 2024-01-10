// SPDX-License-Identifier: MIT
// Author: ClubCards
// Developed by Max J. Rux
// Dev Twitter: @Rux_eth

pragma solidity ^0.8.0;

import "./ClubCards.sol";
import "./ERC1155Receiver.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

contract CCAuthTx is ERC1155Receiver, Context, ReentrancyGuard {
    event AuthTx(address indexed _address, uint256 newNonce);
    mapping(address => uint256) private _authTxNonce;
    ClubCards public cc;

    constructor(ClubCards _cc) {
        cc = _cc;
    }

    function mint(
        uint256 numMints,
        uint256 waveId,
        uint256 nonce,
        uint256 timestamp,
        bytes calldata sig1,
        bytes calldata sig2
    ) external payable nonReentrant {
        address sender = tx.origin;
        address recovered = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(sender, numMints, waveId, nonce, timestamp)
                )
            ),
            sig2
        );
        require(nonce == _authTxNonce[sender], "Incorrect nonce");
        require(
            recovered == cc.admin() || recovered == cc.owner(),
            "Sig doesnt recover to admin"
        );
        cc.whitelistMint{value: msg.value}(
            numMints,
            waveId,
            nonce,
            timestamp,
            sig1
        );
        emit AuthTx(sender, _authTxNonce[sender]);
        delete sender;
    }

    function claim(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 nonce,
        uint256 timestamp,
        bytes memory sig1,
        bytes memory sig2
    ) external nonReentrant {
        address sender = tx.origin;
        address recovered = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encode(sender, tokenIds, amounts, nonce, timestamp)
                )
            ),
            sig2
        );
        require(tokenIds.length <= 10, "Too many ids at a time");
        require(nonce == _authTxNonce[sender], "Incorrect nonce");
        require(
            recovered == cc.admin() || recovered == cc.owner(),
            "Sig doesnt recover to admin"
        );
        cc.claim(tokenIds, amounts, nonce, timestamp, sig1);
        emit AuthTx(sender, _authTxNonce[sender]);
        delete sender;
    }

    function authTxNonce(address _address) public view returns (uint256) {
        return _authTxNonce[_address];
    }

    function onERC1155Received(
        address operator,
        address,
        uint256 id,
        uint256,
        bytes calldata data
    ) public virtual override returns (bytes4 response) {
        address origin = tx.origin;
        require(
            _msgSender() == address(cc),
            "CCAuthTx(onERC1155Received): 'from' is not CC address"
        );
        ++_authTxNonce[origin];
        cc.safeTransferFrom(operator, origin, id, 1, data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        address origin = tx.origin;
        require(
            _msgSender() == address(cc),
            "CCAuthTx(onERC1155BatchReceived): 'from' is not CC address"
        );

        ++_authTxNonce[origin];
        cc.safeBatchTransferFrom(operator, origin, ids, values, data);
        return this.onERC1155BatchReceived.selector;
    }
}
