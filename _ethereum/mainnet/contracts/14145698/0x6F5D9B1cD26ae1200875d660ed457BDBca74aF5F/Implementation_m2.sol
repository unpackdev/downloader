pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./BaseImplementation.sol";
import "./ECDSA.sol";

/**
 * @title StakeAllImplementationM2.
 * @dev DeFi Smart Account Wallet with `castWithSignature`.
 */
contract StakeAllImplementationM2 is BaseImplementation {
    /**
     * Constructor
     * @param _stakeAllIndex Stakeall index contract address.
     * @param _connectors Connector address.
     */
    constructor(address _stakeAllIndex, address _connectors)
        BaseImplementation(_stakeAllIndex, _connectors)
    {}

    /**
     * @notice Getter to fetch nonce of chainId.
     *
     * @param encodedPayload Signature payload.
     * @param signature Signed data by user.
     */
    function recoverSignature(
        bytes memory encodedPayload,
        bytes calldata signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(keccak256(encodedPayload)),
                signature
            );
    }

    /**
     * @notice Getter to return nonce of chainId.
     *
     * @param _chainId Chain id.
     */
    function getNonce(uint256 _chainId) external view returns (uint256) {
        return _nonces[_chainId];
    }

    struct CastWithSignatureData {
        string[] targetNames;
        bytes[] datas;
        address origin;
        uint256 chainId;
        uint256 nonce;
    }

    /**
     * @notice Verifies signed data and executes connector function calls.
     *
     * @param _targetNames Connector addresses.
     * @param _datas CallData of function.
     * @param _origin Origin address.
     * @param _chainId Chain id.
     * @param signature Signed data by EOA.
     */
    function castWithSignature(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin,
        uint256 _chainId,
        bytes calldata signature
    ) external payable returns (bytes32) {
        require(
            _targetNames.length == _datas.length,
            "1: array-length-invalid"
        );
        uint256 nonce = _nonces[_chainId];

        _nonces[_chainId] = _nonces[_chainId] + 1;

        string[] memory targetNames = new string[](_targetNames.length);
        bytes[] memory datas = new bytes[](_datas.length);

        for (uint256 i = 0; i < _targetNames.length; i++) {
            targetNames[i] = _targetNames[i];
            datas[i] = _datas[i];
        }

        CastWithSignatureData memory payload = CastWithSignatureData({
            targetNames: targetNames,
            datas: datas,
            origin: _origin,
            chainId: _chainId,
            nonce: nonce
        });
        address owner = recoverSignature(abi.encode(payload), signature);
        require(_auth[owner], "!owner");

        return _cast(_targetNames, _datas, _origin);
    }
}
