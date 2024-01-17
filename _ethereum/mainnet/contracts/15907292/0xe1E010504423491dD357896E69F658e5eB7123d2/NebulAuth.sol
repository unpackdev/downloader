// SPDX-License-Identifier: MIT
/**
 * NebulAuth protocol by DarkCenobyte
 * Usage:
 * - mint an ERC721-compatible read-only NFT (non-exchangeable, non-burnable, ...)
 * - associate this NFT with a "weight" value (only increasable) using USDT, USDC or BUSD
 * - use an ipfs stored with services using NebulAuth protocol for signup/signin
 * 
 * Official Websites:
 * - nebulauth.one
 * - nebulauth.blockchain
 * - nebulauth.crypto
 */

pragma solidity ^0.8.16;

import "./ERC721Frozen.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract NebulAuth is ERC721Frozen, EIP712, Ownable, ReentrancyGuard {
    // public
    string public constant AUTHORIZER_SIGNATURE = "Authorizer(string websiteDomain,uint256 currentBlock,bytes32 uniqueToken)";
    uint8 public constant blockTimeTolerance = 2;
    uint8 public constant weightDecimals = 18; // MUST BE >= TO THE HIGHEST PAYMENT CONTRACT DECIMAL VALUE
    uint256 public constant minimalWeight = 10 * (10 ** weightDecimals); // minimal weight to pay at mint (weight = 10)

    // private
    string private constant _baseTokenURI = "ipfs://bafkreiglvmyo6jjaj3etjtwvgf424z3mstb47zalatazf4q7jb5oxlnk34";
    bytes32 private constant _AUTHORIZER_SIGNATURE_TYPEHASH = keccak256(abi.encodePacked(keccak256(bytes(AUTHORIZER_SIGNATURE))));
    address private constant _fundsAddress = 0x62edbdDe4a140B3321969C573FCaCc0BEa3C7976;
    uint8 private constant _PAYMENT_CONTRACT_1 = 1;
    uint8 private constant _PAYMENT_CONTRACT_2 = 2;
    uint8 private constant _PAYMENT_CONTRACT_3 = 3;

    address private _paymentCurrencyContract1 = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
    uint8 private _paymentCurrencyContract1decimals = 6;
    address private _paymentCurrencyContract2 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
    uint8 private _paymentCurrencyContract2decimals = 6;
    address private _paymentCurrencyContract3 = 0x4Fabb145d64652a948d72533023f6E7A623C7C53; // BUSD
    uint8 private _paymentCurrencyContract3decimals = 18;

    mapping(address => uint256) private _weight;

    // Events
    event IncreasedWeight(address indexed userAddress, uint256 indexed totalWeight, uint256 addedWeight, address currencyContract);
    event ChangeAcceptedPaymentContracts(uint8 indexed paymentContractId, address indexed currencyContract, uint8 decimals);

    // Constructor
    constructor() ERC721("NebulAuth", "NAUTH") EIP712("NebulAuth", "1") {}

    // Owner function
    function admin_changePaymentContract(uint8 paymentContractId, address newAddress, uint8 newDecimals) onlyOwner external {
        require(paymentContractId <= _PAYMENT_CONTRACT_3, "");
        if (paymentContractId == _PAYMENT_CONTRACT_1) {
            _paymentCurrencyContract1 = newAddress;
            _paymentCurrencyContract1decimals = newDecimals;
        } else if (paymentContractId == _PAYMENT_CONTRACT_2) {
            _paymentCurrencyContract2 = newAddress;
            _paymentCurrencyContract2decimals = newDecimals;
        } else { // _PAYMENT_CONTRACT_3
            _paymentCurrencyContract3 = newAddress;
            _paymentCurrencyContract3decimals = newDecimals;
        }
        emit ChangeAcceptedPaymentContracts(paymentContractId, newAddress, newDecimals);
    }

    // Public functions
    function mint(uint256 weightPrice, address paymentContract) external {
        mint(msg.sender, weightPrice, paymentContract);
    }

    function mint(address to, uint256 weightPrice, address paymentContract) nonReentrant public {
        require(balanceOf(to) == 0, "NebulAuth: This address already own a NebulAuth NFT");
        uint256 decimals = _getDecimalForPaymentContract(paymentContract);
        uint256 weightValue = weightPrice * (10 ** (weightDecimals - decimals));
        require(weightValue >= minimalWeight, "NebulAuth: Unsufficient weight");

        _mint(to, _castAddressToUint256(to));
        _pay(weightPrice, paymentContract);
        _weight[to] = weightValue;
        emit IncreasedWeight(to, weightValue, weightValue, paymentContract);
    }

    function increaseWeight(uint256 additionalWeightPrice, address paymentContract) nonReentrant external {
        increaseWeight(msg.sender, additionalWeightPrice, paymentContract);
    }

    function increaseWeight(address to, uint256 additionalWeightPrice, address paymentContract) nonReentrant public {
        _requireOwnToken(to);
        uint256 decimals = _getDecimalForPaymentContract(paymentContract);
        _pay(additionalWeightPrice, paymentContract);
        uint256 additionalWeight = additionalWeightPrice * (10 ** (weightDecimals - decimals));
        _weight[to] += additionalWeight;
        emit IncreasedWeight(to, _weight[to], additionalWeight, paymentContract);
    }

    function weightOf(address owner) external view returns (uint256 weight) {
        _requireOwnToken(owner);
        return _weight[owner];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return _baseTokenURI;
    }

    function checkSignAndMetadata(string memory websiteDomain, uint256 signCurrentBlock, bytes32 uniqueToken, bytes memory signature) external view returns (bool, address) {
        return (true, _checkSignAndAddress(websiteDomain, signCurrentBlock, uniqueToken, signature));
    }

    function checkSignAndMetadata(string memory websiteDomain, uint256 signCurrentBlock, bytes32 uniqueToken, bytes memory signature, uint256 expectedWeight) external view returns (bool, address) {
        address signerAddr = _checkSignAndAddress(websiteDomain, signCurrentBlock, uniqueToken, signature);
        return (expectedWeight <= _weight[signerAddr], signerAddr);
    }

    // Private functions
    function _checkSignAndAddress(string memory websiteDomain, uint256 signCurrentBlock, bytes32 uniqueToken, bytes memory signature) private view returns (address) {
        require((block.number - signCurrentBlock) <= blockTimeTolerance, "NebulAuth: Request expired, signature block time out of tolerance range");
        address signerAddr = ECDSA.recover(_getDigest(websiteDomain, signCurrentBlock, uniqueToken), signature);
        _requireOwnToken(signerAddr);
        return signerAddr;
    }

    function _requireOwnToken(address addr) private view {
        require(balanceOf(addr) == 1, "NebulAuth: This address doesn't own a NebulAuth NFT");
    }

    function _pay(uint256 amount, address paymentContract) private {
        _requireValidPaymentContract(paymentContract);
        require(
            abi.decode(
                Address.functionCall(
                    paymentContract,
                    abi.encodeWithSignature(
                        "transferFrom(address,address,uint256)",
                        msg.sender,
                        _fundsAddress,
                        amount
                    )
                ),
                (bool)
            ) == true,
            "NebulAuth: Failure during payment"
        );
    }

    function _getDigest(string memory websiteDomain, uint256 signCurrentBlock, bytes32 uniqueToken) private view returns (bytes32) {
        return _hashTypedDataV4(
            _getStructHashFromPayloadMsg(websiteDomain, signCurrentBlock, uniqueToken)
        );
    }

    function _getStructHashFromPayloadMsg(string memory websiteDomain, uint256 signCurrentBlock, bytes32 uniqueToken) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _AUTHORIZER_SIGNATURE_TYPEHASH, // "message(string websiteDomain,uint256 currentBlock,bytes32 uniqueToken)"
                keccak256(bytes(websiteDomain)),
                signCurrentBlock,
                uniqueToken
            )
        );
    }

    function _requireValidPaymentContract(address paymentContract) private view {
        require(
            (paymentContract == _paymentCurrencyContract1 || paymentContract == _paymentCurrencyContract2 || paymentContract == _paymentCurrencyContract3) && paymentContract != address(0),
            "NebulAuth: Invalid payment contract selected"
        );
    }

    function _getDecimalForPaymentContract(address paymentContract) private view returns (uint256) {
        if (paymentContract == _paymentCurrencyContract1) {
            return _paymentCurrencyContract1decimals;
        } else if (paymentContract == _paymentCurrencyContract2) {
            return _paymentCurrencyContract2decimals;
        } else if (paymentContract == _paymentCurrencyContract3) {
            return _paymentCurrencyContract3decimals;
        }
        revert("NebulAuth: Invalid payment contract selected");
    }

    function _castAddressToUint256(address addr) private pure returns (uint256) {
        return uint256(uint160(addr));
    }
}