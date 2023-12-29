// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./EIP712.sol";
import "./ReentrancyGuard.sol";

interface IBattlepass {
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        string memory _tokenUri,
        bytes memory _data
    ) external;
}

/**
 * @title Battlepass Redeemer Contract
 * @notice This contract allows users to redeem their Parallel Battlepass Cards.
 * @dev The redemption is gated behind server signature.
 */
contract BattlepassRedeemer is Ownable, ReentrancyGuard, EIP712 {
    error ParamLengthMismatch();
    error InvalidSig(bytes signature);
    error RedeemingTooMany(uint256 amount);

    event BattlepassRedeemed(
        address indexed account,
        uint256 tokenId,
        uint256 amount
    );
    event ParallelBattlepassSet(address indexed parallelBattlepass);
    event TrustedSignerSet(address indexed trustedSigner);
    event TokenUrisSet(uint256[] tokenIds, string[] tokenUris);
    event MaxRedeemablePerTxnSet(uint256 maxRedeemablePerTxn);

    /// @notice Address of the battle contract
    IBattlepass public parallelBattlepass = IBattlepass(0x9d764bcf1AFFd83554B7626F22EAB2ffC60590C7);

    /// @notice Address of the trusted signer for signature
    address public trustedSigner = 0xdB38fCC65EB2c42a0B43Df36C2f1bb6EE707A751;

    /// @notice Mapping of token id to token uri
    mapping(uint256 => string) public tokenUri;

    /// @notice Nonce to prevent signature from being reused
    mapping(address => uint256) public nonces;

    /// @notice Max redeemable per transaction
    uint256 public maxRedeemablePerTxn = 1;

    /// @notice EIP712("name", "version")
    constructor() EIP712("Battle Pass Redeemer", "1.0.0") {}

    /**
     * @notice Sets the battle pass contract address
     * @dev Only callable by owner
     * @param _parallelBattlepass Address of the battle pass contract
     */
    function setParallelBattlepass(
        IBattlepass _parallelBattlepass
    ) external onlyOwner {
        parallelBattlepass = _parallelBattlepass;
        emit ParallelBattlepassSet(address(_parallelBattlepass));
    }

    /**
     * @notice Sets the trusted signer address
     * @dev Only callable by owner
     * @param _trustedSigner Address of the trusted signer
     */
    function setTrustedSigner(address _trustedSigner) external onlyOwner {
        trustedSigner = _trustedSigner;
        emit TrustedSignerSet(_trustedSigner);
    }

    /**
     * @notice Sets token uri for list of token ids
     * @dev Only callable by owner
     * @param tokenIds List of token ids to configure
     * @param tokenUris List of uris corresponding to token ids
     */
    function setTokenUris(
        uint256[] calldata tokenIds,
        string[] memory tokenUris
    ) external onlyOwner {
        if (tokenIds.length != tokenUris.length) revert ParamLengthMismatch();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenUri[tokenIds[i]] = tokenUris[i];
        }

        emit TokenUrisSet(tokenIds, tokenUris);
    }

    /**
     * @notice Sets max redeemable per transaction
     * @dev Only callable by owner
     * @param _maxRedeemablePerTxn Max redeemable per transaction
     */
    function setMaxRedeemablePerTxn(
        uint256 _maxRedeemablePerTxn
    ) external onlyOwner {
        maxRedeemablePerTxn = _maxRedeemablePerTxn;
        emit MaxRedeemablePerTxnSet(maxRedeemablePerTxn);
    }

    /**
     * @notice Lets user redeem their battle pass
     * @param _tokenId TokenId of the battle pass to redeem
     * @param _amount Amount of battle pass to redeem
     * @param _signature Signature of trusted signer
     */
    function redeem(
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _signature
    ) external nonReentrant {
        if (_amount > maxRedeemablePerTxn) revert RedeemingTooMany(_amount);

        if (!_verify(msg.sender, _tokenId, _amount, _signature)) {
            revert InvalidSig(_signature);
        } else {
            nonces[msg.sender] += 1;
        }

        parallelBattlepass.mint(
            msg.sender,
            _tokenId,
            _amount,
            tokenUri[_tokenId],
            new bytes(0)
        );

        emit BattlepassRedeemed(msg.sender, _tokenId, _amount);
    }

    /**
     * @notice Verifies that the data was signed by the trusted signer
     * @param _account Address of the purchaser
     * @param _tokenId TokenId of the battle pass to redeem
     * @param _amount Amount of battle pass to redeem
     * @param _signature Signature of trusted signer
     */
    function _verify(
        address _account,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Message(address account,uint256 tokenId,uint256 amount,uint256 nonce)"
                    ),
                    _account,
                    _tokenId,
                    _amount,
                    nonces[_account]
                )
            )
        );

        return ECDSA.recover(digest, _signature) == trustedSigner;
    }
}
