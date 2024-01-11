//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./console.sol";
import "./ECDSAUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";

contract RequestHandler is EIP712Upgradeable {
    using ECDSAUpgradeable for bytes32;

    enum RequestStatus {
        Pending,
        Cancelled,
        Fulfilled
    }

    uint256 private _requestDuration;
    address private _authorizedSigner;
    mapping(uint256 => RequestStatus) private _requestStatusById;

    bytes32 private constant CANCEL_REQUEST_TYPE_HASH =
        keccak256("CancelRequest(uint256 requestId,address account)");

    struct CancelRequest {
        uint256 requestId;
        address account;
    }

    event RequestUpdated(uint256 indexed id, RequestStatus status);

    modifier onlyIfPending(uint256 requestId) {
        require(
            _requestStatusById[requestId] == RequestStatus.Pending,
            "Request is not pending"
        );
        _;
    }

    modifier onlyIfNotExpired(uint256 createdAt) {
        require(
            block.timestamp <= createdAt + _requestDuration,
            "Expired request"
        );
        _;
    }

    modifier onlyIfCancelAuthorized(
        CancelRequest calldata request,
        bytes calldata signature
    ) {
        address signer = _hashAndRecover(
            keccak256(
                abi.encode(
                    CANCEL_REQUEST_TYPE_HASH,
                    request.requestId,
                    request.account
                )
            ),
            signature
        );
        require(signer == authorizedSigner(), "Cancel not authorized");
        _;
    }

    function requestDuration() public view returns (uint256) {
        return _requestDuration;
    }

    function authorizedSigner() public view returns (address) {
        return _authorizedSigner;
    }

    function requestStatusById(uint256 requestId)
        public
        view
        returns (RequestStatus)
    {
        return _requestStatusById[requestId];
    }

    function _hashAndRecover(bytes32 structHash, bytes memory signature)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(structHash);
        return digest.recover(signature);
    }

    function _markRequestAsFulfilled(uint256 requestId, uint256 createdAt)
        internal
        onlyIfPending(requestId)
        onlyIfNotExpired(createdAt)
    {
        _requestStatusById[requestId] = RequestStatus.Fulfilled;
        emit RequestUpdated(requestId, RequestStatus.Fulfilled);
    }

    function _markRequestAsCancelled(
        CancelRequest calldata request,
        bytes calldata signature
    )
        internal
        onlyIfPending(request.requestId)
        onlyIfCancelAuthorized(request, signature)
    {
        _requestStatusById[request.requestId] = RequestStatus.Cancelled;
        emit RequestUpdated(request.requestId, RequestStatus.Cancelled);
    }

    function _setRequestDuration(uint256 duration) internal {
        _requestDuration = duration;
    }

    function _setAuthorizedSigner(address signer) internal {
        _authorizedSigner = signer;
    }

    function _EIP712NameHash() internal pure override returns (bytes32) {
        return keccak256(bytes("WEED-GANG"));
    }

    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes("0.1.0"));
    }

    uint256[47] private __gap;
}
