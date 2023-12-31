// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IUpshotOracle.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./Ownable2Step.sol";

/**
 * @title Upshot Oracle
 */
contract UpshotOracle is Ownable2Step, IUpshotOracle {
    // ***************************************************************
    // * ========================= STATE =========================== *
    // ***************************************************************
    mapping(address => uint256) private _collectionNonce;
    
    address private _authenticator;

    event UpshotOracleAdminSetNonce();
    error UpshotOracleInvalidNonce();

    constructor (address authenticator_) Ownable(msg.sender) {
        _setAuthenticator(authenticator_);
    }

    /**
     * @inheritdoc IUpshotOracle
     */
    function decodeTokenPrices(
        PriceData[] calldata priceData
    ) external override returns (uint256[] memory tokenPrices) {
        uint256 priceDataCount = priceData.length;
        tokenPrices = new uint256[](priceDataCount);

        PriceData memory data;
        for(uint256 i = 0; i < priceDataCount;) {
            data = priceData[i];

            if (
                block.timestamp < data.timestamp ||
                data.expiration < block.timestamp 
            ) {
                revert UpshotOracleInvalidPriceTime();
            }

            address signer =
                ECDSA.recover(
                    ECDSA.toEthSignedMessageHash(getPriceMessage(
                        data.nonce,
                        data.nft, 
                        data.nftId, 
                        data.token, 
                        data.price, 
                        data.timestamp,
                        data.expiration,
                        data.extraData
                    )),
                    data.signature
                );

            if (signer != _authenticator) {
                revert UpshotOracleInvalidSigner();
            }

            _validateNonce(data.nft, data.nonce);

            tokenPrices[i] = data.price;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice  
    function getPriceMessage(
        uint256 nonce_,
        address nft, 
        uint256 nftId, 
        address token,
        uint256 price, 
        uint96 timestamp,
        uint96 expiration,
        bytes memory extraData
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(
            block.chainid, 
            nonce_,
            nft, 
            nftId, 
            token,
            price, 
            timestamp,
            expiration,
            extraData
        ));
    }

    // ***************************************************************
    // * ========================= ADMIN =========================== *
    // ***************************************************************
    /**
     * @notice Admin function to set the new authenticator address
     *
     * @param authenticator_ The new authenticator address
     */
    function setAuthenticator(address authenticator_) external onlyOwner {
        _setAuthenticator(authenticator_);
    }

    /**
     * @notice Admin function to set the nonce for the collection
     * nonce is used to invalidate all prices for a collection at once
     * 
     * @param collection The collection to update the nonce for
     * @param nonce The new nonce
     */
    function setNonce(address collection, uint256 nonce) external onlyOwner {
        _collectionNonce[collection] = nonce;
        emit UpshotOracleAdminSetNonce();
    }

    // ***************************************************************
    // * ========================== VIEW =========================== *
    // ***************************************************************

    /**
     * @notice Get current nonce by NFT collection address
     * nonce is used to invalidate all prices for a collection at once
     */
    function getNonce(address collection) public view returns (uint256 nonce) {
        nonce = _collectionNonce[collection];
    }

    /**
     * @inheritdoc IUpshotOracle
     */
    function authenticator() public view override returns (address) {
        return _authenticator;
    }

    // ***************************************************************
    // * ======================= INTERNAL ========================== *
    // ***************************************************************
    /**
     * @dev Set the new authenticator address and emit an event
     *
     * @param authenticator_ The new authenticator address
     */
    function _setAuthenticator(address authenticator_) internal {
        _authenticator = authenticator_;
        emit UpshotOracleAdminSetAuthenticator(authenticator_);
    }

    /**
     * @dev Update the nonce for the collection and revert if the nonce is invalid
     *
     * @param collection The collection to update the nonce for
     * @param nonce The new nonce
     */
    function _validateNonce(address collection, uint256 nonce) private {
        if (nonce < _collectionNonce[collection]) {
            revert UpshotOracleInvalidNonce();
        }
        _collectionNonce[collection] = nonce;
    }
}
