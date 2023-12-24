// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "./ILayerZeroUltraLightNodeV2.sol";

import "./Worker.sol";
import "./MultiSig.sol";
import "./IVerifier.sol";
import "./IVerifierFeeLib.sol";
import "./IUltraLightNode.sol";
import "./MessageLibBase.sol";

struct ExecuteParam {
    uint32 vid;
    address target;
    bytes callData;
    uint expiration;
    bytes signatures;
}

contract VerifierNetwork is Worker, MultiSig, IVerifier {
    // to uniquely identify this VerifierNetwork instance
    // set to endpoint v1 eid if available OR endpoint v2 eid % 30_000
    uint32 public immutable vid;

    mapping(uint32 dstEid => DstConfig) public dstConfig;
    mapping(bytes32 executableHash => bool used) public usedHashes;

    event VerifySignaturesFailed(uint idx);
    event ExecuteFailed(uint _index, bytes _data);
    event HashAlreadyUsed(ExecuteParam param, bytes32 _hash);
    event VerifierFeePaid(uint fee);

    // ========================= Constructor =========================

    /// @dev VerifierNetwork doesn't have a roleAdmin (address(0x0))
    /// @dev Supports all of ULNv2, ULN301, ULN302 and more
    /// @param _messageLibs array of message lib addresses that are granted the MESSAGE_LIB_ROLE
    /// @param _priceFeed price feed address
    /// @param _signers array of signer addresses for multisig
    /// @param _quorum quorum for multisig
    /// @param _admins array of admin addresses that are granted the ADMIN_ROLE
    constructor(
        uint32 _vid,
        address[] memory _messageLibs,
        address _priceFeed,
        address[] memory _signers,
        uint64 _quorum,
        address[] memory _admins
    ) Worker(_messageLibs, _priceFeed, 12000, address(0x0), _admins) MultiSig(_signers, _quorum) {
        vid = _vid;
    }

    // ========================= Modifier =========================

    /// @dev depending on role, restrict access to only self or admin
    /// @dev ALLOWLIST, DENYLIST, MESSAGE_LIB_ROLE can only be granted/revoked by self
    /// @dev ADMIN_ROLE can only be granted/revoked by admin
    /// @dev reverts if not one of the above roles
    /// @param _role role to check
    modifier onlySelfOrAdmin(bytes32 _role) {
        if (_role == ALLOWLIST || _role == DENYLIST || _role == MESSAGE_LIB_ROLE) {
            // self required
            require(address(this) == msg.sender, "Verifier: caller must be self");
        } else if (_role == ADMIN_ROLE) {
            // admin required
            _checkRole(ADMIN_ROLE);
        } else {
            revert("Verifier: invalid role");
        }
        _;
    }

    modifier onlySelf() {
        require(address(this) == msg.sender, "Verifier: caller must be self");
        _;
    }

    // ========================= OnlySelf =========================

    /// @dev set signers for multisig
    /// @dev function sig 0x31cb6105
    /// @param _signer signer address
    /// @param _active true to add, false to remove
    function setSigner(address _signer, bool _active) external onlySelf {
        _setSigner(_signer, _active);
    }

    /// @dev set quorum for multisig
    /// @dev function sig 0x8585c945
    /// @param _quorum to set
    function setQuorum(uint64 _quorum) external onlySelf {
        _setQuorum(_quorum);
    }

    /// @dev one function to verify and deliver to ULN302 and more (does not support ULN301)
    /// @dev if last verifier, can use this function to save overhead gas on deliver
    /// @dev function sig 0xb724b133
    /// @param _uln IUltraLightNode compatible contract
    /// @param _packetHeader packet header
    /// @param _payloadHash payload hash
    /// @param _confirmations block confirmations
    function verifyAndDeliver(
        IUltraLightNode _uln,
        bytes calldata _packetHeader,
        bytes32 _payloadHash,
        uint64 _confirmations
    ) external onlySelf {
        require(hasRole(MESSAGE_LIB_ROLE, address(_uln)), "Verifier: invalid uln");
        _uln.verify(_packetHeader, _payloadHash, _confirmations);
        // if deliverable, deliver. else, skip or it will revert in uln
        if (_uln.deliverable(_packetHeader, _payloadHash) == DeliveryState.Deliverable) {
            _uln.deliver(_packetHeader, _payloadHash);
        }
    }

    // ========================= OnlySelf / OnlyAdmin =========================

    /// @dev overrides AccessControl to allow self/admin to grant role'
    /// @dev function sig 0x2f2ff15d
    /// @param _role role to grant
    /// @param _account account to grant role to
    function grantRole(bytes32 _role, address _account) public override onlySelfOrAdmin(_role) {
        _grantRole(_role, _account);
    }

    /// @dev overrides AccessControl to allow self/admin to revoke role
    /// @dev function sig 0xd547741f
    /// @param _role role to revoke
    /// @param _account account to revoke role from
    function revokeRole(bytes32 _role, address _account) public override onlySelfOrAdmin(_role) {
        _revokeRole(_role, _account);
    }

    // ========================= OnlyQuorum =========================

    // @notice function for quorum to change admin without going through execute function
    // @dev calldata in the case is abi.encode new admin address
    function quorumChangeAdmin(ExecuteParam calldata _param) external {
        require(_param.expiration > block.timestamp, "Verifier: expired");
        require(_param.target == address(this), "Verifier: invalid target");
        require(_param.vid == vid, "Verifier: invalid vid");

        // generate and validate hash
        bytes32 hash = hashCallData(_param.vid, _param.target, _param.callData, _param.expiration);
        (bool sigsValid, ) = verifySignatures(hash, _param.signatures);
        require(sigsValid, "Verifier: invalid signatures");
        require(!usedHashes[hash], "Verifier: hash already used");

        usedHashes[hash] = true;
        _grantRole(ADMIN_ROLE, abi.decode(_param.callData, (address)));
    }

    // ========================= OnlyAdmin =========================

    /// @param _params array of DstConfigParam
    function setDstConfig(DstConfigParam[] calldata _params) external onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < _params.length; ++i) {
            DstConfigParam calldata param = _params[i];
            dstConfig[param.dstEid] = DstConfig(param.gas, param.multiplierBps, param.floorMarginUSD);
        }
        emit SetDstConfig(_params);
    }

    /// @dev takes a list of instructions and executes them in order
    /// @dev if any of the instructions fail, it will emit an error event and continue to execute the rest of the instructions
    /// @param _params array of ExecuteParam, includes target, callData, expiration, signatures
    function execute(ExecuteParam[] calldata _params) external onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < _params.length; ++i) {
            ExecuteParam calldata param = _params[i];
            // 1. skip if invalid vid
            if (param.vid != vid) {
                continue;
            }

            // 2. skip if expired
            if (param.expiration <= block.timestamp) {
                continue;
            }

            // generate and validate hash
            bytes32 hash = hashCallData(param.vid, param.target, param.callData, param.expiration);

            // 3. check signatures
            (bool sigsValid, ) = verifySignatures(hash, param.signatures);
            if (!sigsValid) {
                emit VerifySignaturesFailed(i);
                continue;
            }

            // 4. should check hash
            bool shouldCheckHash = _shouldCheckHash(bytes4(param.callData));
            if (shouldCheckHash) {
                if (usedHashes[hash]) {
                    emit HashAlreadyUsed(param, hash);
                    continue;
                } else {
                    usedHashes[hash] = true; // prevent reentry and replay attack
                }
            }

            (bool success, bytes memory rtnData) = param.target.call(param.callData);
            if (!success) {
                if (shouldCheckHash) {
                    // need to unset the usedHash otherwise it cant be used
                    usedHashes[hash] = false;
                }
                // emit an event in any case
                emit ExecuteFailed(i, rtnData);
            }
        }
    }

    /// @dev to support ULNv2
    /// @dev the withdrawFee function for ULN30X is built in the Worker contract
    /// @param _lib message lib address
    /// @param _to address to withdraw to
    /// @param _amount amount to withdraw
    function withdrawFeeFromUlnV2(address _lib, address payable _to, uint _amount) external onlyRole(ADMIN_ROLE) {
        require(hasRole(MESSAGE_LIB_ROLE, _lib), "Verifier: Invalid message lib");
        ILayerZeroUltraLightNodeV2(_lib).withdrawNative(_to, _amount);
    }

    // ========================= OnlyMessageLib =========================

    /// @dev for ULN301, ULN302 and more to assign job
    /// @dev verifier network can reject job from _sender by adding/removing them from allowlist/denylist
    /// @param _param assign job param
    /// @param _options verifier options
    function assignJob(
        AssignJobParam calldata _param,
        bytes calldata _options
    ) external payable onlyRole(MESSAGE_LIB_ROLE) onlyAcl(_param.sender) returns (uint totalFee) {
        IVerifierFeeLib.FeeParams memory feeParams = IVerifierFeeLib.FeeParams(
            priceFeed,
            _param.dstEid,
            _param.confirmations,
            _param.sender,
            quorum,
            defaultMultiplierBps
        );
        totalFee = IVerifierFeeLib(workerFeeLib).getFeeOnSend(feeParams, dstConfig[_param.dstEid], _options);
    }

    /// @dev to support ULNv2
    /// @dev verifier network can reject job from _sender by adding/removing them from allowlist/denylist
    /// @param _dstEid destination EndpointId
    /// @param //_outboundProofType outbound proof type
    /// @param _confirmations block confirmations
    /// @param _sender message sender address
    function assignJob(
        uint16 _dstEid,
        uint16 /*_outboundProofType*/,
        uint64 _confirmations,
        address _sender
    ) external onlyRole(MESSAGE_LIB_ROLE) onlyAcl(_sender) returns (uint totalFee) {
        IVerifierFeeLib.FeeParams memory params = IVerifierFeeLib.FeeParams(
            priceFeed,
            _dstEid,
            _confirmations,
            _sender,
            quorum,
            defaultMultiplierBps
        );
        // ULNV2 does not have verifier options
        totalFee = IVerifierFeeLib(workerFeeLib).getFeeOnSend(params, dstConfig[_dstEid], bytes(""));
        emit VerifierFeePaid(totalFee);
    }

    // ========================= View =========================

    /// @dev getFee can revert if _sender doesn't pass ACL
    /// @param _dstEid destination EndpointId
    /// @param _confirmations block confirmations
    /// @param _sender message sender address
    /// @param _options verifier options
    /// @return fee fee in native amount
    function getFee(
        uint32 _dstEid,
        uint64 _confirmations,
        address _sender,
        bytes calldata _options
    ) external view onlyAcl(_sender) returns (uint fee) {
        IVerifierFeeLib.FeeParams memory params = IVerifierFeeLib.FeeParams(
            priceFeed,
            _dstEid,
            _confirmations,
            _sender,
            quorum,
            defaultMultiplierBps
        );
        return IVerifierFeeLib(workerFeeLib).getFee(params, dstConfig[_dstEid], _options);
    }

    /// @dev to support ULNv2
    /// @dev getFee can revert if _sender doesn't pass ACL
    /// @param _dstEid destination EndpointId
    /// @param //_outboundProofType outbound proof type
    /// @param _confirmations block confirmations
    /// @param _sender message sender address
    function getFee(
        uint16 _dstEid,
        uint16 /*_outboundProofType*/,
        uint64 _confirmations,
        address _sender
    ) public view onlyAcl(_sender) returns (uint fee) {
        IVerifierFeeLib.FeeParams memory params = IVerifierFeeLib.FeeParams(
            priceFeed,
            _dstEid,
            _confirmations,
            _sender,
            quorum,
            defaultMultiplierBps
        );
        return IVerifierFeeLib(workerFeeLib).getFee(params, dstConfig[_dstEid], bytes(""));
    }

    /// @param _target target address
    /// @param _callData call data
    /// @param _expiration expiration timestamp
    /// @return hash of above
    function hashCallData(
        uint32 _vid,
        address _target,
        bytes calldata _callData,
        uint _expiration
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_vid, _target, _expiration, _callData));
    }

    // ========================= Internal =========================

    /// @dev to save gas, we don't check hash for some functions (where replaying won't change the state)
    /// @dev for example, some administrative functions like changing signers, the contract should check hash to double spending
    /// @dev should ensure that all onlySelf functions have unique functionSig
    /// @param _functionSig function signature
    /// @return true if should check hash
    function _shouldCheckHash(bytes4 _functionSig) internal pure returns (bool) {
        // never check for these selectors to save gas
        return
            _functionSig != IUltraLightNode.verify.selector && // 0x0223536e, replaying won't change the state
            _functionSig != this.verifyAndDeliver.selector && // 0xb724b133, replaying calls deliver on top of verify, which will be rejected at uln if not deliverable
            _functionSig != ILayerZeroUltraLightNodeV2.updateHash.selector; // 0x704316e5, replaying will be revert at uln
    }
}
