// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./RequestTypes.sol";
import "./GelatoMetaBoxBase.sol";
import "./Proxied.sol";
import "./Initializable.sol";

/// @title Gelato Meta Box contract
/// @notice This contract must NEVER hold funds!
/// @dev    Maliciously crafted transaction payloads could wipe out any funds left here.
contract GelatoMetaBox is Proxied, Initializable, GelatoMetaBoxBase {
    address public immutable gelato;
    uint256 public immutable chainId;

    mapping(address => uint256) public nonce;
    address public gasTank;
    address public gasTankAdmin;

    event LogMetaTxRequestAsyncGasTankFee(
        address indexed sponsor,
        address indexed user,
        address indexed target,
        uint256 sponsorChainId,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogMetaTxRequestSyncGasTankFee(
        address indexed sponsor,
        address indexed user,
        address indexed target,
        address feeToken,
        uint256 fee,
        bytes32 taskId
    );

    event LogSetGasTank(address oldGasTank, address newGasTank);

    event LogSetGasTankAdmin(address oldGasTankAdmin, address newGasTankAdmin);

    modifier onlyGelato() {
        require(msg.sender == gelato, "Only callable by gelato");
        _;
    }

    modifier onlyGasTankAdmin() {
        require(msg.sender == gasTankAdmin, "Only callable by gasTankAdmin");
        _;
    }

    constructor(address _gelato) {
        gelato = _gelato;

        uint256 _chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _chainId := chainid()
        }

        chainId = _chainId;
    }

    function init(address _gasTankAdmin) external initializer {
        gasTankAdmin = _gasTankAdmin;

        emit LogSetGasTankAdmin(address(0), _gasTankAdmin);
    }

    function setGasTank(address _gasTank) external onlyGasTankAdmin {
        require(_gasTank != address(0), "Invalid gasTank address");

        emit LogSetGasTank(gasTank, _gasTank);

        gasTank = _gasTank;
    }

    function setGasTankAdmin(address _gasTankAdmin) external onlyGasTankAdmin {
        require(_gasTankAdmin != address(0), "Invalid gasTankAdmin address");

        emit LogSetGasTankAdmin(gasTankAdmin, _gasTankAdmin);

        gasTankAdmin = _gasTankAdmin;
    }

    /// @notice Relay request + async Gas Tank payment deductions (off-chain accounting)
    /// @param _req Relay request data
    /// @param _userSignature EIP-712 compliant signature from _req.user
    /// @param _sponsorSignature EIP-712 compliant signature from _req.sponsor
    ///                          (can be same as _userSignature)
    /// @notice   EOA that originates the tx, but does not necessarily pay the relayer
    /// @param _gelatoFee Fee to be charged by Gelato relayer, denominated in _req.feeToken
    // solhint-disable-next-line function-max-lines
    function metaTxRequestGasTankFee(
        MetaTxRequest calldata _req,
        bytes calldata _userSignature,
        bytes calldata _sponsorSignature,
        uint256 _gelatoFee,
        bytes32 _taskId
    ) external onlyGelato {
        require(
            // solhint-disable-next-line not-rely-on-time
            _req.deadline == 0 || _req.deadline >= block.timestamp,
            "Request expired"
        );

        require(_req.chainId == chainId, "Wrong chainId");

        require(
            _req.paymentType == 1 || _req.paymentType == 2,
            "paymentType must be 1 or 2"
        );

        require(_gelatoFee <= _req.maxFee, "Executor over-charged");

        // Verify and increment user's nonce
        uint256 userNonce = nonce[_req.user];
        require(_req.nonce == userNonce, "Invalid nonce");
        nonce[_req.user] = userNonce + 1;

        _verifyMetaTxRequestSignature(_req, _userSignature, _req.user);
        // If is sponsored tx, we also verify sponsor's signature
        if (_req.user != _req.sponsor) {
            _verifyMetaTxRequestSignature(
                _req,
                _sponsorSignature,
                _req.sponsor
            );
        }

        require(_req.target != gasTank, "target address cannot be gasTank");
        require(_isContract(_req.target), "Cannot call EOA");
        (bool success, ) = _req.target.call{gas: _req.gas}(
            abi.encodePacked(_req.data, _req.user)
        );
        require(success, "External call failed");

        if (_req.paymentType == 1) {
            emit LogMetaTxRequestAsyncGasTankFee(
                _req.sponsor,
                _req.user,
                _req.target,
                _req.sponsorChainId == 0 ? chainId : _req.sponsorChainId,
                _req.feeToken,
                _gelatoFee,
                _taskId
            );
        } else {
            // TODO: deduct balance from GasTank
            emit LogMetaTxRequestSyncGasTankFee(
                _req.sponsor,
                _req.user,
                _req.target,
                _req.feeToken,
                _gelatoFee,
                _taskId
            );
        }
    }

    function getDomainSeparator() public view returns (bytes32) {
        return _getDomainSeparator(chainId);
    }
}
