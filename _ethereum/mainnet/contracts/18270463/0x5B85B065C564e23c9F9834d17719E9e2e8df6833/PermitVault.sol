// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./Multicall.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IAccountFactory.sol";
import "./Permit20.sol";
import "./Permit721.sol";
import "./Permit1155.sol";

contract PermitVault is
    Initializable,
    UUPSUpgradeable,
    Permit20,
    Permit721,
    Permit1155,
    PausableUpgradeable,
    Multicall
{
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    using AddressUpgradeable for address payable;
    using SafeERC20 for IERC20;
    using Address for address;

    /// Events
    event RevokeApprovals();
    event WithdrawnNativeToken(address indexed owner, uint256 balance);
    event PlatformFeeTransferred(address indexed previousFeeAddress, address indexed newReceiverAddress);
    event AccountFactoryTransferred(
        address indexed previousAccountFactoryAddress,
        address indexed newAccountFactoryAddress
    );

    event TransferPermit20(
        address token,
        address indexed receiverAddress,
        uint256 receiverFee,
        address indexed platformFeeAddress,
        uint256 platformFee,
        address indexed feeCreatorAddr,
        uint256 feeCreator,
        uint32 metadata
    );

    event TransferPermit721(AssetIdentifierData asset, address token, FeeData feeData, uint32 metadata);
    event TransferPermit1155(AssetIdentifierData asset, address token, FeeData feeData, uint256 value, uint32 metadata);

    address public _platformFeeAddr;
    address public _accountFactoryAddr;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * Initializes the contract
     * @param   name The contract name.
     * @param   version The contract Address.
     */
    function initialize(string memory name, string memory version) external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Pausable_init();
        __EIP712_init(name, version);
        _platformFeeAddr = owner();
    }

    /**
     * @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
     *          Called by upgradeTo and upgradeToAndCall.
     * @param   newImplementation new implamentation Address.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Transfer ETH or ERC20 to "to" param if the value is greater than 0 and "to" is not a Zero address
     * @param   token Token Address.
     * @param   from Sender Address.
     * @param   to Receiver Address.
     * @param   value Amount.
     */
    function transfer(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        require(to != address(0), "PermitVault: zero address is not authorized");
        if (value == 0) {
            return;
        }

        if (token == ETH_ADDRESS) {
            payable(to).sendValue(value);
        } else {
            IERC20(token).safeTransferFrom(from, to, value);
        }
    }

    /**
     * @notice External method to transfer erc20 token with signature and fees.
     * @dev The signature can be provisioned by owner and GOTCHA.
     * @param   registry Address
     * @param   from Address.
     * @param   to Address.
     * @param   receiverFee Receiver fee value.
     * @param   feeData Transfer20 fee data.
     * @param   nonce Nonce Value.
     * @param   deadline Deadline Timestamp.
     * @param   metadata Metadata information needed to create the graph.
     * @param   signatures Signatures. position0 owner.
     *                                 position1 paragon.
     */
    function transfer20(
        address registry,
        address from,
        address to,
        uint256 receiverFee,
        Transfer20FeeData memory feeData,
        uint256 nonce,
        uint256 deadline,
        uint32 metadata,
        bytes[2] calldata signatures
    ) external whenNotPaused {
        super.transfer20WithSign(registry, from, to, receiverFee, feeData, nonce, deadline, metadata, signatures);

        transfer(registry, from, _platformFeeAddr, feeData.platformFee);
        transfer(registry, from, feeData.creatorFeeAddr, feeData.creatorFee);

        emit TransferPermit20(
            registry,
            to,
            receiverFee,
            _platformFeeAddr,
            feeData.platformFee,
            feeData.creatorFeeAddr,
            feeData.creatorFee,
            metadata
        );
    }

    /**
     * @notice External method to transfer erc721 token with signature and fees.
     * @dev The signature can be provisioned by the nft owner or GOTCHA.
     * @param   assetIdentifierData Asset Identifier Data.
     * @param   tokenFee Token Fee Address.
     * @param   to Address.
     * @param   feeData Fee Data.
     * @param   nonce Nonce Value.
     * @param   deadline Deadline Timestamp.
     * @param   salt Salt Id.
     * @param   metadata Metadata information needed to create the graph
     * @param   signature Signature.
     */
    function transfer721(
        AssetIdentifierData memory assetIdentifierData,
        address tokenFee,
        address to,
        FeeData memory feeData,
        uint256 nonce,
        uint256 deadline,
        uint256 salt,
        uint32 metadata,
        bytes memory signature
    ) external payable whenNotPaused {
        revertIfWrongPayableValue(tokenFee, feeData);
        createAccountIfNeeded(salt);

        super.transfer721WithSign(
            Transfer721WithSignData({
                assetIdentifierData: assetIdentifierData,
                to: to,
                feeData: feeData,
                nonce: nonce,
                deadline: deadline,
                salt: salt,
                metadata: metadata,
                signature: signature
            })
        );

        uint256 ownerFee = feeData.ownerFee;
        uint256 platformFee = feeData.platformFee;

        address sender = msg.sender;
        transfer(tokenFee, sender, feeData.receiverFeeAddr, ownerFee);
        transfer(tokenFee, sender, _platformFeeAddr, platformFee);
        transfer(tokenFee, sender, feeData.creatorFeeAddr, feeData.creatorFee);

        emit TransferPermit721(assetIdentifierData, tokenFee, feeData, metadata);
    }

    /**
     * @notice External method to transfer erc1155 token with signature and fees.
     * @dev The signature can be provisioned by the nft owner or GOTCHA.
     * @param   assetIdentifierData Asset Identifier Data.
     * @param   tokenFee Token Fee address.
     * @param   from Address.
     * @param   to Address.
     * @param   value Amount.
     * @param   feeData Fee Data.
     * @param   nonce Nonce Value.
     * @param   deadline Deadline Timestamp.
     * @param   salt Salt Id.
     * @param   metadata Metadata information needed to create the graph.
     * @param   data Data.
     * @param   signature Signature.
     */
    function transfer1155(
        AssetIdentifierData memory assetIdentifierData,
        address tokenFee,
        address from,
        address to,
        uint256 value,
        FeeData memory feeData,
        uint256 nonce,
        uint256 deadline,
        uint256 salt,
        uint32 metadata,
        bytes memory data,
        bytes memory signature
    ) external payable whenNotPaused {
        revertIfWrongPayableValue(tokenFee, feeData);
        createAccountIfNeeded(salt);

        super.transfer1155WithSign(
            Transfer1155WithSignData({
                assetIdentifierData: assetIdentifierData,
                from: from,
                to: to,
                value: value,
                feeData: feeData,
                nonce: nonce,
                deadline: deadline,
                salt: salt,
                metadata: metadata,
                data: data,
                signature: signature
            })
        );
        address sender = msg.sender;
        transfer(tokenFee, sender, feeData.receiverFeeAddr, feeData.ownerFee);
        transfer(tokenFee, sender, _platformFeeAddr, feeData.platformFee);
        transfer(tokenFee, sender, feeData.creatorFeeAddr, feeData.creatorFee);

        emit TransferPermit1155(assetIdentifierData, tokenFee, feeData, value, metadata);
    }

    /**
     * @notice Replaces the contract platform fee address.
     * @dev Can only be called by the current owner.
     * @param   newPlatformFeeAddress New Platform Fee Address.
     */
    function transferPlatformFeeAddress(address newPlatformFeeAddress) external whenNotPaused onlyOwner {
        require(newPlatformFeeAddress != address(0), "PermitVault:: new platform fee address is the zero address");
        require(
            newPlatformFeeAddress != _platformFeeAddr,
            "PermitVault:: newPlatformFeeAddress is the same as the current one"
        );
        address oldPlatformFeeAddr = _platformFeeAddr;
        _platformFeeAddr = newPlatformFeeAddress;
        emit PlatformFeeTransferred(oldPlatformFeeAddr, newPlatformFeeAddress);
    }

    /**
     * @notice Replaces the contract account factory.
     * @dev Can only be called by the current owner.
     * @param   newAccountFactoryAddress New Account Factory Address.
     */
    function transferAccountFactoryAddress(address newAccountFactoryAddress) external whenNotPaused onlyOwner {
        require(newAccountFactoryAddress != address(0), "PermitVault:: newAccountFactoryAddress is the zero address");
        require(
            newAccountFactoryAddress != _accountFactoryAddr,
            "PermitVault:: newAccountFactoryAddress is the same as the current one"
        );
        address oldAccountFactoryAddr = _accountFactoryAddr;
        _accountFactoryAddr = newAccountFactoryAddress;
        emit AccountFactoryTransferred(oldAccountFactoryAddr, newAccountFactoryAddress);
    }

    /**
     * @notice revert if payable value is not valid
     * @dev Internal method.
     * @param   token Token Address
     * @param   feeData Fee Data.
     */
    function revertIfWrongPayableValue(address token, FeeData memory feeData) internal {
        if (token == ETH_ADDRESS) {
            require(
                feeData.platformFee + feeData.ownerFee + feeData.creatorFee == msg.value,
                "PermitVault:: The ETH amount sent is wrong"
            );
        }
    }

    /**
     * @notice create an account if is needed.
     * @dev Internal method.
     * @param   salt Salt Id.
     */
    function createAccountIfNeeded(uint256 salt) internal {
        address addr = IAccountFactory(_accountFactoryAddr).getAddress(salt);
        if (addr.code.length == 0) {
            IAccountFactory(_accountFactoryAddr).createAccount(salt);
        }
    }

    /**
     * @notice Allows the contract owner to withdraw all Ether stored in the contract.
     * @dev
     *  1- Fetches the current Ether balance of the contract.
     *  2- Transfers the entire balance to the owner's address.
     *  3- Emits a `WithdrawnNativeToken` event.
     *  Can only be called by the current owner.
     */
    function withdrawNativeToken() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).sendValue(balance);
        emit WithdrawnNativeToken(owner(), balance);
    }

    /**
     * @notice The owner revoke all approvals.
     * @dev
     *  1- Pause the contract, the functions transfer721, transfer1155 and transferPlatformFeeAddress stops working.
     *  2- Renounce ownership.
     *  Can only be called by the current owner.
     */
    function revokeApprovals() external onlyOwner {
        _pause();
        if (address(this).balance > 0) {
            payable(owner()).sendValue(address(this).balance);
        }
        _transferOwnership(address(0));
        emit RevokeApprovals();
    }

    /**
     * @notice Overrides the base contract's renounceOwnership method to disable it.
     * @dev This function overrides the parent contract's renounceOwnership method to prevent
     * ownership from being renounced. It leaves the ownership unchanged.
     */
    function renounceOwnership() public override onlyOwner {
        // Intentionally left blank. This overrides the parent contract's method to disable
        // the ability to renounce ownership.
    }

    receive() external payable {}
}
