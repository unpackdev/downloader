// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC755.sol";
import "./Structs.sol";
import "./Constants.sol";
import "./PaymentSplitter.sol";

contract Artwork is ERC755 {
    address private _owner;

    mapping(uint256 => PaymentSplitter) private _paymentSplittersByTokenId;

    string[] private _supportedActions;
    mapping(string => string) private _actionGroup;
    mapping(string => bool) _supportedRolesMap;
    string[] private _supportedRoles;
    uint256 private _supportedActionsNum;

    mapping(string => uint256) private _paymentsReceived;

    mapping(uint256 => bool) private _signedTimestamp;

    mapping(address => bool) private _canMint;

    mapping(uint256 => string) private _tokenCertificate;

    function initialize(
        Structs.SupportedAction[] memory supportedActionsList,
        string[] memory supportedRolesList
    ) external initializer {
        __ERC755_init("LiveArt", "LIVEART");

        _owner = _msgSender();
        _canMint[_owner] = true;

        _updateSupportedRoles(supportedRolesList);
        _updateSupportedActions(supportedActionsList);
    }

    function updateSupportedActions(
        Structs.SupportedAction[] memory supportedActionsList,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV,
        uint256 timestamp
    ) public onlyOwner {
        _requireMessageSigned(sigR, sigS, sigV, timestamp);
        _updateSupportedActions(supportedActionsList);
    }

    function _updateSupportedActions(
        Structs.SupportedAction[] memory supportedActionsList
    ) private {
        require(
            supportedActionsList.length > 0,
            "no supported actions"
        );
        for (uint256 i = 0; i < _supportedActions.length; i++) {
            delete _actionGroup[_supportedActions[i]];
        }
        delete _supportedActions;

        for (uint256 i = 0; i < supportedActionsList.length; i++) {
            _actionGroup[supportedActionsList[i].action] =
            supportedActionsList[i].group;
            _supportedActions.push(supportedActionsList[i].action);
        }
        _supportedActionsNum = supportedActionsList.length;
    }

    function updateSupportedRoles(
        string[] memory supportedRolesList,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV,
        uint256 timestamp
    ) public onlyOwner {
        _requireMessageSigned(sigR, sigS, sigV, timestamp);
        _updateSupportedRoles(supportedRolesList);
    }

    function _updateSupportedRoles(
        string[] memory supportedRolesList
    ) private {
        require(
            supportedRolesList.length > 0,
            "no supported roles"
        );

        for (uint256 i = 0; i < _supportedRoles.length; i++) {
            delete _supportedRolesMap[_supportedRoles[i]];
        }
        delete _supportedRoles;

        bool ownerIsSupported = false;
        bool creatorIsSupported = false;
        for (uint256 i = 0; i < supportedRolesList.length; i++) {
            _supportedRolesMap[supportedRolesList[i]] = true;
            if (keccak256(bytes(supportedRolesList[i])) == Constants.ROLE_OWNER) {
                ownerIsSupported = true;
            }
            if (keccak256(bytes(supportedRolesList[i])) == Constants.ROLE_CREATOR) {
                creatorIsSupported = true;
            }
        }
        _supportedRoles = supportedRolesList;
        require(ownerIsSupported, "owner role should be supported");
        require(ownerIsSupported, "creator role should be supported");
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    function _requireMessageSigned(
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) private {
        require(
            !_signedTimestamp[timestamp],
            "timestamp already signed"
        );
        require(
            _msgSender() == ecrecover(
                keccak256(abi.encodePacked(
                    "\x19\x01",
                    Constants._DOMAIN_SEPARATOR,
                    keccak256(abi.encode(
                        keccak256("BasicOperation(uint256 timestamp)"),
                        timestamp
                    ))
                )),
                v,
                r,
                s
            ),
            "invalid sig"
        );

        _signedTimestamp[timestamp] = true;
    }

    function _requireCanMint() private view {
        require(
            _canMint[_msgSender()],
            "can't mint"
        );
    }

    function _actionSupported(string memory action) private view returns (bool) {
        return bytes(_actionGroup[action]).length > 0;
    }

    function supportedActions() external view override returns (string[] memory) {
        return _supportedActions;
    }

    function supportedRoles() external view returns (string[] memory) {
        return _supportedRoles;
    }

    function createArtwork(
        Structs.RoyaltyReceiver[] memory royaltyReceivers,
        Structs.Policy[] memory creationRights,
        string memory metadataURI,
        uint256 editionOf,
        uint256 maxTokenSupply,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV,
        uint256 timestamp
    ) external returns(uint256) {
        _requireMessageSigned(sigR, sigS, sigV, timestamp);
        _requireCanMint();
        require(
            creationRights.length >= _supportedActionsNum,
            "all rights should be set"
        );
        if (editionOf > 0) {
            require(
                maxTokenSupply == 1,
                "invalid token supply for edition"
            );
        }

        _tokenId++;

        uint256 newItemId = _tokenId;

        if (maxTokenSupply > 0) {
            _tokenSupply[newItemId] = maxTokenSupply;
            _tokenEditions[newItemId].push(newItemId);
        }
        if (editionOf > 0) {
            require(
                _exists(editionOf),
                "original token does not exist"
            );
            _tokenEditions[editionOf].push(newItemId);
            require(
                _tokenSupply[editionOf] >= _tokenEditions[editionOf].length,
                "editions limit reached"
            );
        }

        Structs.Policy[] storage tokenRights = _rightsByToken[newItemId];
        for (uint256 i = 0; i < creationRights.length; i++) {
            creationRights[i].target = newItemId;
            require(
                _actionSupported(creationRights[i].action),
                "unsupported action"
            );
            require(
                _supportedRolesMap[creationRights[i].permission.role],
                "unsupported role"
            );
            tokenRights.push(creationRights[i]);
        }

        PaymentSplitter paymentSplitterAddress = new PaymentSplitter(
            royaltyReceivers,
            newItemId
        );
        _paymentSplittersByTokenId[newItemId] = paymentSplitterAddress;
        _setTokenURI(newItemId, metadataURI);

        for (uint256 i = 0; i < creationRights.length; i++) {
            if (
                keccak256(bytes(creationRights[i].permission.role)) ==
                Constants.ROLE_CREATOR
            ) {
                if (
                    !isApprovedForAll(
                        creationRights[i].permission.wallet,
                        _msgSender()
                    )
                ) {
                    _setApprovalForAll(
                        creationRights[i].permission.wallet,
                        _msgSender(),
                        true
                    );
                }
            }
        }

        emit ArtworkCreated(
            newItemId,
            creationRights,
            metadataURI,
            editionOf,
            maxTokenSupply,
            block.timestamp
        );

        return newItemId;
    }

    function _generatePaymentReceivedKey(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) private pure returns (string memory) {
        string memory actions;

        for (uint256 i = 0; i < policies.length; i++) {
            actions = string(abi.encodePacked(actions, policies[i].action));
        }

        return string(abi.encodePacked(from, to, tokenId, actions));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) internal view override {
        if (_paymentSplittersByTokenId[tokenId].hasRoyaltyReceivers()) {
            require(
                _paymentsReceived[
                    _generatePaymentReceivedKey(from, to, tokenId, policies)
                ] > 0,
                "payment not received"
            );
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) internal override {
        delete _paymentsReceived[
            _generatePaymentReceivedKey(from, to, tokenId, policies)
        ];
    }

    function payForTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) external override payable {
        require(
            _exists(tokenId),
            "no token to pay for"
        );
        require(
            msg.value > 0,
            "no payment received"
        );

        for (uint256 i = 0; i < policies.length; i++) {
            policies[i].target = tokenId;
        }
        emit PaymentReceived(
            from,
            to,
            tokenId,
            msg.value,
            policies,
            block.timestamp
        );

        _paymentsReceived[
            _generatePaymentReceivedKey(from, to, tokenId, policies)
        ] = msg.value;

        AddressUpgradeable.sendValue(
            payable(address(_paymentSplittersByTokenId[tokenId])),
            msg.value
        );
        _paymentSplittersByTokenId[tokenId].releasePayment(
            msg.value,
            payable(from)
        );
    }

    function paymentSplitter(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId));
        return address(_paymentSplittersByTokenId[tokenId]);
    }

    function version() external virtual pure returns (uint256) {
        return 1;
    }

    function rightsOwned(
        address owner,
        Structs.Policy[] memory policies,
        uint256 tokenId
    ) external override view returns (bool) {
        require(_exists(tokenId), "token does not exist");

        for (uint256 i = 0; i < policies.length; i++) {
            if (policies[i].permission.wallet != owner) {
                return false;
            }

            bool foundTokenRight = false;
            for (uint256 j = 0; j < _rightsByToken[tokenId].length; j++) {
                if (
                    compareStrings(_rightsByToken[tokenId][j].action, policies[i].action) &&
                    _rightsByToken[tokenId][j].permission.wallet == owner
                ) {
                    foundTokenRight = true;
                }
            }
            if (!foundTokenRight) {
                return false;
            }
        }

        return true;
    }

    function approveByOperator(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(
            isApprovedForAll(
                from,
                _msgSender()
            ),
            "not operator for a token"
        );

        _approve(
            from,
            to,
            tokenId
        );
    }

    function addMinter(
        address minter,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external onlyOwner {
        _requireMessageSigned(r, s, v, timestamp);

        _canMint[minter] = true;
    }

    function removeMinter(
        address minter,
        bytes32 r,
        bytes32 s,
        uint8 v,
        uint256 timestamp
    ) external onlyOwner {
        _requireMessageSigned(r, s, v, timestamp);
        require(minter != _owner, "can't remove owner");

        delete _canMint[minter];
    }

    function setTokenCertificate(
        uint256 tokenId,
        string memory certificateURI
    ) external {
        _requireCanMint();
        require(
            bytes(_tokenCertificate[tokenId]).length == 0,
            "can't change certificate"
        );

        _tokenCertificate[tokenId] = certificateURI;
    }

    function getTokenCertificate(
        uint256 tokenId
    ) external view returns (string memory) {
        return _tokenCertificate[tokenId];
    }
}