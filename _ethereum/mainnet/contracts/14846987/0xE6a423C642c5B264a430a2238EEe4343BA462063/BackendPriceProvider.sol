// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./PriceProvider.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";

/**
 * Backend price verifier.
 */
contract BackendPriceProvider is PriceProvider,
                                 Initializable,
                                 AccessControlUpgradeable
{

    bytes32 public constant TRUSTED_BACKEND_ROLE = keccak256("TRUSTED_BACKEND_ROLE");

    string public constant DESCRIPTION = "Price provider that uses trusted backend";

    uint8 public usdDecimals;

    mapping(address => BackendMetadata) public backendMetadata;

    struct BackendMetadata {
        bool isListed; // true - listed, false - not listed
        bool isActive; // true - active, false - not active
    }

    event GrandTrustedBackendRole(address indexed who, address indexed newTrustedBackend);
    event RevokeTrustedBackendRole(address indexed who, address indexed trustedBackend);
    event SetToken(address indexed who, address indexed token);
    event ChangeActive(address indexed who, address indexed token, bool active);
    

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TRUSTED_BACKEND_ROLE, msg.sender);
        usdDecimals = 6;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the Admin");
        _;
    }

    modifier onlyTrustedBackend() {
        require(hasRole(TRUSTED_BACKEND_ROLE, msg.sender), "Caller is not the trusted backend");
        _;
    }

    /****************** Admin functions ****************** */

    function grandTrustedBackendRole(address newTrustedBackend) public onlyAdmin {
        grantRole(TRUSTED_BACKEND_ROLE, newTrustedBackend);
        emit GrandTrustedBackendRole(msg.sender, newTrustedBackend);
    }

    function revokeTrustedBackendRole(address trustedBackend) public onlyAdmin {
        revokeRole(TRUSTED_BACKEND_ROLE, trustedBackend);
        emit RevokeTrustedBackendRole(msg.sender, trustedBackend);
    }

    /****************** TrustedBackendRole functions ****************** */

    function setToken(address token) public onlyTrustedBackend {
        backendMetadata[token].isListed = true;
        backendMetadata[token].isActive = true;
        emit SetToken(msg.sender, token);
    }

    function changeActive(address token, bool active) public override onlyTrustedBackend {
        backendMetadata[token].isActive = active;
        emit ChangeActive(msg.sender, token, active);
    }

    /****************** sign steps ****************** */

    /**
     * @notice 1. step. Backend creates offchain data and get hash of this data. This data calls message.
     * @dev returns the keccak256 of concatenated input data
     * @param token the address of asset
     * @param priceMantissa the price of asset that include decimals
     * @param validTo the unix timestamp in seconds that define the validity of given price to `validTo` timestamp
     */
    function getMessageHash(address token, uint256 priceMantissa, uint256 validTo) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, priceMantissa, validTo));
    }

    /**
     * @notice 2. step. Backend formatting the message and get hash of this message.
     * @dev returns the keccak256 of formatted message
     * @param messageHash the keccak256 of message
     */
    function getEthSignedMessageHash(bytes32 messageHash) public pure returns (bytes32){
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        Where   + (plus) is concatenation operation
                \x19 is 0x19
                len(msg) = 32, because keccak256 returns 32 bytes, i.e. lenght of data is 32 bytes
                msg is hash of massage
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    /**
     * @notice 3. step. Backend sign the message using web3 library and get signature.
        # using browser
        account = "copy paste account of signer here"
        ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

        # using web3
        web3.personal.sign(hash, web3.eth.defaultAccount, console.log)
        
        # using rust secp256k1 and web3:
        let signature = secret_key.sign(&ethSignedMessageHash,None).unwrap();

        Signature will be different for different accounts
        Example of sign:
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
        
        Than backend provide the tuple:
        (token, priceMantissa, priceDecimals, validTo, signature)
     */

    /**
     * @notice 4. step. Smart contract verify the message (tuple)
     * @dev returns true if the message is signed by trusted backend. Else returns false.
     * @param token the address of asset
     * @param priceMantissa the price of asset that include decimals
     * @param validTo the unix timestamp in seconds that define the validity of given price to `validTo` timestamp
     * @param signature the sign of message.
     */
    function verify(address token, uint256 priceMantissa, uint256 validTo, bytes memory signature) public view returns (bool) {
        require(block.timestamp <= validTo, "BackendPriceProvider: expired price!");
        
        bytes32 messageHash = getMessageHash(token, priceMantissa, validTo);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        address messageSigner = recoverSigner(ethSignedMessageHash, signature);
        return hasRole(TRUSTED_BACKEND_ROLE, messageSigner);
    }

    /**
     * @dev returns the signer of `ethSignedMessageHash`
     */
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) public pure returns (address){
        require(signature.length == 65, "BackendPriceProvider: invalid signature length");
        bytes32 r; bytes32 s; uint8 v; //splitting signature in (r,s,v)
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */
            // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }
        //return the signer by ecrecover
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    /****************** end sign functions ****************** */

    /****************** View functions ****************** */

    function isListed(address token) public override view returns(bool){
        return backendMetadata[token].isListed;
    }

    function isActive(address token) public override view returns(bool){
        return backendMetadata[token].isActive;
    }

    /**
     * @notice Returns the latest asset price and price decimals
     * @param token the token address
     */
    function getPrice(address token) public override pure returns(uint256 price, uint8 priceDecimals) {
        token; price; priceDecimals;
        revert("Use getPriceSigned(...)");
    }

    function getPriceSigned(address token, uint256 priceMantissa, uint256 validTo, bytes memory signature) public override view returns(uint256 _priceMantissa, uint8 priceDecimals){
        require(isActive(token),"BackendPriceProvider: token is not active!");
        require(verify(token, priceMantissa, validTo, signature),"BackendPriceProvider: signer is not moderator");
        return (priceMantissa, getPriceDecimals());
    }

    function getEvaluation(address token, uint256 tokenAmount) public override pure returns(uint256 evaluation) {
        token; tokenAmount; evaluation;
        revert("Use getEvaluationSigned(...)");
    }
    
    /**
     * @dev return the evaluation in $ of `tokenAmount` with signed price
     * @param token the address of token to get evaluation in $
     * @param tokenAmount the amount of token to get evaluation. Amount is scaled by 10 in power token decimals
     * @param priceMantissa the price multiplied by priceDecimals. The dimension of priceMantissa should be $/token
     * @param validTo the timestamp in seconds, when price is gonna be not valid.
     * @param signature the ECDSA sign on eliptic curve secp256k1.        
     */
    function getEvaluationSigned(address token, uint256 tokenAmount, uint256 priceMantissa, uint256 validTo, bytes memory signature) public override view returns(uint256 evaluation){
        require(isActive(token),"BackendPriceProvider: token is not active!");
        require(verify(token, priceMantissa, validTo, signature), "BackendPriceProvider: signer is not moderator");
        evaluation = tokenAmount * priceMantissa / (10 ** getPriceDecimals());
        uint8 tokenDecimals = ERC20Upgradeable(token).decimals();
        if (tokenDecimals >= usdDecimals) {
            evaluation = evaluation / (10 ** (tokenDecimals - usdDecimals)); //get the evaluation in USD.
        } else {
            evaluation = evaluation * (10 ** (usdDecimals - tokenDecimals)); 
        }
    }

    function getPriceDecimals() public view override returns (uint8) {
        return usdDecimals;
    }
}
