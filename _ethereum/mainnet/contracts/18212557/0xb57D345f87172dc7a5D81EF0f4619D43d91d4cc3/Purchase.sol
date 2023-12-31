// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./EIP712Upgradeable.sol";

interface INFT {
    function upgradeNFT(address user, uint256 nftId) external;
    function nextLevelNFT() external view returns(address);
    function tokenIdCounter() external view returns (uint256);
}

error ZeroAddress();
error EmptyDomainDetails();
error InvalidUser();
error InvalidUserNonce();
error InvalidSignature();

/**
 * @dev Contract that can be used for tamadoge petStore purchase
 */
contract Purchase is
    Initializable,
    AccessControlUpgradeable,
    EIP712Upgradeable
{
    bytes32 private constant PURCHASE_DETAILS =
        keccak256(
            (
                "PurchaseFromPetStoreDetails(address nft,uint256 nftId,address user,uint256[] itemIds,uint256 amount,uint256 userNonce,bool isMinted,string purchaseType,uint256 petId)"
            )
        );
    bytes32 private constant NFT_UPGRADE_CONST =
        keccak256(abi.encodePacked("NFT_UPGRADE"));

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    /// @dev Tamadoge Token Address.
    IERC20Upgradeable public tamaToken;

    /// @dev wallet address to which tama token will be transferred.
    address public paymentWallet;

    /// @dev mapping of user address and their corresponding nonce for this contract.
    mapping(address => uint256) public userNonces;

    /// @dev Details of on-chain purchase.
    struct PurchaseFromPetStoreDetails {
        address nft;
        uint256 nftId;
        address user;
        uint256[] itemIds;
        uint256 amount;
        uint256 userNonce;
        bool isMinted;
        string purchaseType;
        uint256 petId;
    }

    /// @dev Emitted when a purchase is made.
    event PurchasedFromPetStore(
        address indexed nft,
        uint256 indexed nftId,
        uint256[] itemIds,
        uint256 amount,
        address indexed user,
        uint256 timestamp,
        bool isMinted,
        string purchaseType,
        uint256 petId
    );
    //add new petId

    event NFTUpgrade(
        address indexed previousNFT,
        uint256 indexed previousNFTId,
        address indexed newNFT,
        uint256 newNFTId,
        address user,
        uint256[] itemIds,
        uint256 amount,
        string purchaseType
    );

    /// @dev Emitted when wallet address is updated.
    event UpdatePaymentWallet(
        address indexed previousAddress,
        address indexed newAddress,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract.
     * @param _tamaToken address of tama token.
     * @param _paymentWallet address of wallet used to transfer tama when purchase is made.
     * @param _name domain name for EIP 712 Domain.
     * @param _version version for EIP 712 Domain.
     * @param _signer address of the signer.
     *
     * Requirements:
     * - Tama token, signer and payment wallet address should not be zero address.
     * - Domain name and version cannot be empty string
     * 
     * NOTE:
     * - Default Admin role is given to the contract deployer.
     *
     */
    function initialize(
        address _tamaToken,
        address _paymentWallet,
        string calldata _name,
        string calldata _version,
        address _signer
    ) external initializer {
        if (
            (_tamaToken == address(0) || _paymentWallet == address(0)) ||
            _signer == address(0)
        ) revert ZeroAddress();

        if (!(bytes(_name).length > 0 && bytes(_version).length > 0))
            revert EmptyDomainDetails();

        __AccessControl_init();
        __EIP712_init(_name, _version);

        tamaToken = IERC20Upgradeable(_tamaToken);
        paymentWallet = _paymentWallet;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SIGNER_ROLE, _signer);
    }

    /**
     * @dev Function to make purchase from petStore based on signer signature.
     * @param _data purchase details.
     * @param _signature signature of signer with purchase details.
     *
     * Requirements:-
     * - Caller should be the one making the purchase.
     * - Nonce of caller should be in consistent with the nonce of caller in the contract.
     * - Caller should have pre approved tama token to the purchase contract.
     *
     * NOTE:- Only for minted NFTs, nftId will be the Id of nft.
     *
     * Emits {PurchasedFromPetStore} event.
     */
    function purchaseFromPetStore(
        PurchaseFromPetStoreDetails calldata _data,
        bytes calldata _signature
    ) external {
        if (msg.sender != _data.user) revert InvalidUser();
        if (++userNonces[msg.sender] != _data.userNonce)
            revert InvalidUserNonce();
        if (!_verifySignature(_data, _signature)) revert InvalidSignature();

        require(
            tamaToken.transferFrom(msg.sender, paymentWallet, _data.amount)
        );

        //Only for minted NFTs, new NFTs are to be minted.
        if (
            keccak256(abi.encodePacked((_data.purchaseType))) == NFT_UPGRADE_CONST &&
            _data.isMinted
        ) {
            _upgradeNFTToken(_data.nft, _data.user, _data.nftId,_data.itemIds,_data.amount,_data.purchaseType);
        }else{
            emit PurchasedFromPetStore(
            _data.nft,
            _data.nftId,
            _data.itemIds,
            _data.amount,
            _data.user,
            block.timestamp,
            _data.isMinted,
            _data.purchaseType,
            _data.petId
        );
        }
    }

    /**
     * @dev Function to update the wallet address
     * @param _paymentWallet New address of the wallet
     *
     * Requirements:
     * - Only admin can call this function.
     * - Wallet address should not be zero address.
     *
     * Emits {UpdatePaymentWallet} event.
     */
    function updatePaymentWallet(
        address _paymentWallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paymentWallet == address(0)) revert ZeroAddress();

        address previousWallet = paymentWallet;
        paymentWallet = _paymentWallet;
        emit UpdatePaymentWallet(
            previousWallet,
            _paymentWallet,
            block.timestamp
        );
    }

    /**
     * @dev Function to upgrade nft
     * @param _nft Address of nft to be upgraded
     * @param _user User to which upgraded nft has to be trasferred.
     * @param _nftId id of the nft to be upgraded.
     *
     */
    function _upgradeNFTToken(
        address _nft,
        address _user,
        uint256 _nftId,
        uint256[] calldata _itemIds,
        uint256 _amount,
        string calldata _purchaseType
    ) private {
        address higherNFT = INFT(_nft).nextLevelNFT();
        uint256 higherNFTId = INFT(higherNFT).tokenIdCounter();
        INFT(_nft).upgradeNFT(_user, _nftId);
        emit NFTUpgrade(_nft,_nftId,higherNFT,higherNFTId,_user,_itemIds,_amount,_purchaseType);

    }

    // ----------------------------EIP-712 functions.------------------------------------------------------------------

    /**
     * @dev Returns a bool on completing verification of signature.
     * @param _data  Data to be used for signature verification.
     * @param _signature Signature to be verified.
     *
     * NOTE:
     * - Message signer should have SIGNER_ROLE.
     */
    function _verifySignature(
        PurchaseFromPetStoreDetails calldata _data,
        bytes calldata _signature
    ) private view returns (bool) {
        bytes32 digest = _getDigest(_data);
        address signer = _getSigner(digest, _signature);
        return hasRole(SIGNER_ROLE, signer);
    }

    function _getDigest(
        PurchaseFromPetStoreDetails calldata _data
    ) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        PURCHASE_DETAILS,
                        _data.nft,
                        _data.nftId,
                        _data.user,
                        keccak256(abi.encodePacked(_data.itemIds)),
                        _data.amount,
                        _data.userNonce,
                        _data.isMinted,
                        keccak256(abi.encodePacked(_data.purchaseType)),
                        _data.petId
                    )
                )
            );
    }

    /**
     * @dev Returns the signer address.
     */
    function _getSigner(
        bytes32 _digest,
        bytes calldata _signature
    ) private pure returns (address) {
        return ECDSAUpgradeable.recover(_digest, _signature);
    }
}
