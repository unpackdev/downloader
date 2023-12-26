// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./EIP712.sol";
import "./ReentrancyGuard.sol";
import "./EchelonGateways.sol";

interface ICosmetics {
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
 * @notice This contract allows users to upgrade their Parallel Battlepass Cards.
 * @dev The redemption is gated behind server signature.
 */
contract CosmeticsUpgrader is
    Ownable,
    ReentrancyGuard,
    EIP712,
    EchelonGateways
{
    error ContractDisabled();
    error ParamLengthMismatch();
    error InvalidSig(bytes signature);
    error RedeemingTooMany(uint256 amount);
    error InvalidCaller(address caller);
    error InsufficientPrime();

    event CosmeticsUpgraded(
        address indexed account,
        uint256 userId,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );
    event IsDisabledSet(bool isDisabled);
    event ParallelCosmeticsSet(address indexed parallelCosmetics);
    event PrimeAddressSet(address indexed prime);
    event TrustedSignerSet(address indexed trustedSigner);
    event TokensSet(
        uint256[] tokenIds,
        string[] tokenUris,
        uint256[] tokenPrices
    );
    event MaxUpgradablePerTxnSet(uint256 maxUpgradablePerTxn);

    /// @notice Disabled state of the contract
    bool public isDisabled;

    /// @notice Prime token smart contract address
    address public prime = 0xb23d80f5FefcDDaa212212F028021B41DEd428CF;

    /// @notice Address of the battle contract
    ICosmetics public parallelCosmetics =
        ICosmetics(0x6E3bc168F6260Ff54257aE4B56449eFd7aFd5934);

    /// @notice Address of the trusted signer for signature
    address public trustedSigner = 0x9bc1AA36424eBFFe297EB4c9d2Ae4FA8C986A94e;

    /// @notice Mapping of token id to token uri
    mapping(uint256 => string) public tokenUris;

    /// @notice Nonce to prevent signature from being reused
    mapping(uint256 => uint256) public nonces;

    /// @notice Price to upgrade a cosmetic
    mapping(uint256 => uint256) public tokenPrices;

    /// @notice Max upgradeable per transaction
    uint256 public maxUpgradablePerTxn = 1;

    /// @notice EIP712("name", "version")
    constructor() EIP712("Cosmetics Upgrader", "1.0.0") {}

    /** @notice Set the isDisabled state
     *  @param _isDisabled new isDisabled state
     */
    function setIsDisabled(bool _isDisabled) external onlyOwner {
        isDisabled = _isDisabled;
        emit IsDisabledSet(_isDisabled);
    }

    /** @notice Set the address of Prime Token contract
     *  @param _prime prime token address
     */
    function setPrime(address _prime) external onlyOwner {
        prime = _prime;
        emit PrimeAddressSet(_prime);
    }

    /**
     * @notice Sets the battle pass contract address
     * @dev Only callable by owner
     * @param _parallelCosmetics Address of the battle pass contract
     */
    function setParallelCosmetics(
        ICosmetics _parallelCosmetics
    ) external onlyOwner {
        parallelCosmetics = _parallelCosmetics;
        emit ParallelCosmeticsSet(address(_parallelCosmetics));
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
     * @param _tokenIds List of token ids to configure
     * @param _tokenUris List of uris corresponding to token ids
     * @param _tokenPrices List of prices corresponding to token ids
     */
    function setTokens(
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris,
        uint256[] calldata _tokenPrices
    ) external onlyOwner {
        if (_tokenIds.length != _tokenUris.length) revert ParamLengthMismatch();
        if (_tokenIds.length != _tokenPrices.length)
            revert ParamLengthMismatch();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokenUris[_tokenIds[i]] = _tokenUris[i];
            tokenPrices[_tokenIds[i]] = _tokenPrices[i];
        }

        emit TokensSet(_tokenIds, _tokenUris, _tokenPrices);
    }

    /**
     * @notice Sets max upgradeable per transaction
     * @dev Only callable by owner
     * @param _maxUpgradablePerTxn Max upgradeable per transaction
     */
    function setMaxUpgradablePerTxn(
        uint256 _maxUpgradablePerTxn
    ) external onlyOwner {
        maxUpgradablePerTxn = _maxUpgradablePerTxn;
        emit MaxUpgradablePerTxnSet(maxUpgradablePerTxn);
    }

    /**
     * @notice Function invoked by the prime token contract to purchase terminals
     * @param _from The address of the original msg.sender
     * @param _primeValue The amount of prime that was sent from the prime token contract
     * @param _data Catch-all param to allow the caller to pass additional data to the handler, includes tokenIds and amounts
     */
    function handleInvokeEchelon(
        address _from,
        address,
        address,
        uint256,
        uint256,
        uint256 _primeValue,
        bytes memory _data
    ) public payable override {
        if (isDisabled) {
            revert ContractDisabled();
        }

        if (msg.sender != prime) {
            revert InvalidCaller(msg.sender);
        }

        (
            uint256 userId,
            uint256 tokenId,
            uint256 amount,
            bytes memory signature
        ) = abi.decode(_data, (uint256, uint256, uint256, bytes));

        if (amount > maxUpgradablePerTxn) revert RedeemingTooMany(amount);

        if (!_verify(_from, userId, tokenId, amount, signature)) {
            revert InvalidSig(signature);
        } else {
            nonces[userId] += 1;
        }

        if (_primeValue != tokenPrices[tokenId] * amount)
            revert InsufficientPrime();

        parallelCosmetics.mint(
            _from,
            tokenId,
            amount,
            tokenUris[tokenId],
            new bytes(0)
        );

        emit CosmeticsUpgraded(
            _from,
            userId,
            tokenId,
            amount,
            tokenPrices[tokenId]
        );
    }

    /**
     * @notice Verifies that the data was signed by the trusted signer
     * @param _account Account of the purchaser
     * @param _userId User id of the purchaser
     * @param _tokenId TokenId of the battle pass to upgrade
     * @param _amount Amount of battle pass to upgrade
     * @param _signature Signature of trusted signer
     */
    function _verify(
        address _account,
        uint256 _userId,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Message(address account,uint256 userId,uint256 tokenId,uint256 amount,uint256 nonce)"
                    ),
                    _account,
                    _userId,
                    _tokenId,
                    _amount,
                    nonces[_userId]
                )
            )
        );

        return ECDSA.recover(digest, _signature) == trustedSigner;
    }
}
