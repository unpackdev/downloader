// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IRoyaltyEngine.sol";
import "./AdminControlUpgradeable.sol";
import "./IAdminControl.sol";
import "./IArtBlocksOverride.sol";
import "./IEIP2981.sol";
import "./IRoyaltyRegistry.sol";
import "./IRoyaltyEngineV1.sol";
import "./EnumerableSet.sol";
import "./IAccessControlUpgradeable.sol";
import "./ERC165Checker.sol";
import "./Address.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";

/**
 * @dev Engine to lookup royalty configurations
 */
contract RoyaltyEngineV2 is
    Initializable,
    IRoyaltyEngine,
    AdminControlUpgradeable,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // STATE VARIABLES - Ensure order and key names are maintained

    // Maximum basis points allowed to set during the royalty
    uint256 public maxBps;

    // Track blacklisted collectionAddress
    EnumerableSet.AddressSet private blacklistedCollectionAddress;

    // Track blacklisted walletAddress
    EnumerableSet.AddressSet private blacklistedWalletAddress;

    //Royalty Configurations stored at the collection level
    mapping(address => address payable[]) internal collectionRoyaltyReceivers;
    mapping(address => uint256[]) internal collectionRoyaltyBPS;

    //Royalty Configurations stored at the token level
    mapping(address => mapping(uint256 => address payable[]))
        internal tokenRoyaltyReceivers;
    mapping(address => mapping(uint256 => uint256[])) internal tokenRoyaltyBPS;

    // Royalty configured stored in seperate engine
    mapping(address => address) internal royaltyLookupAddress;

    // Royalty engine V1 contract Address
    IRoyaltyEngine public royaltyEngineV1;

    // Royalty Registry to get lookup address
    address public royaltyLookupProvider;

    // Royalty Engine to get royalty
    address public royaltyEngineProvider;

    /// @notice Emitted when setting the royalty lookup address
    /// @param owner Address that sets the lookup address
    /// @param tokenAddress The token address you wish to override
    /// @param royaltyAddress The royalty override address
    event RoyaltyOverride(
        address owner,
        address tokenAddress,
        address royaltyAddress
    );

    /// @notice Emitted when an Withdraw Payout is executed
    /// @param toAddress To Address amount is transferred
    /// @param amount The amount transferred
    event WithdrawPayout(address toAddress, uint256 amount);

    /**
     * Initializer
     */
    function initialize(
        address _royaltyEngineV1,
        uint16 _maxBasisPoints
    ) public initializer {
        require(
            _maxBasisPoints < 10_000,
            "maxBasisPoints should not be equal or exceed than the value 10_000"
        );
        maxBps = _maxBasisPoints;
        royaltyEngineV1 = IRoyaltyEngine(_royaltyEngineV1);
        __Ownable_init();
    }

    /**
     * @dev Set royalty for collection.
     */
    function setRoyalty(
        address collectionAddress,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external override nonReentrant {
        require(
            isAdmin(msg.sender) ||
                _isCollectionAdmin(collectionAddress, msg.sender) ||
                _isCollectionOwner(collectionAddress, msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            !blacklistedCollectionAddress.contains(collectionAddress) &&
                !blacklistedWalletAddress.contains(msg.sender),
            "Sender and CollectionAddress should not be blacklisted"
        );
        require(
            receivers.length == basisPoints.length,
            "Invalid input length for receivers and basis points"
        );
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(
            totalBasisPoints < maxBps,
            "Total basis points should be less than the maximum basis points"
        );
        collectionRoyaltyReceivers[collectionAddress] = receivers;
        collectionRoyaltyBPS[collectionAddress] = basisPoints;
        emit RoyaltiesUpdated(collectionAddress, receivers, basisPoints);
    }

    /**
     * @dev Set royalties of a token
     */
    function setTokenRoyalty(
        address collectionAddress,
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external override nonReentrant {
        require(
            isAdmin(msg.sender) ||
                _isCollectionAdmin(collectionAddress, msg.sender) ||
                _isCollectionOwner(collectionAddress, msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            !blacklistedCollectionAddress.contains(collectionAddress) &&
                !blacklistedWalletAddress.contains(msg.sender),
            "Sender and CollectionAddress should not be blacklisted"
        );
        require(
            receivers.length == basisPoints.length,
            "Invalid input length for receivers and basis points"
        );
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(
            totalBasisPoints < maxBps,
            "Total basis points should be less than the maximum basis points"
        );
        tokenRoyaltyReceivers[collectionAddress][tokenId] = receivers;
        tokenRoyaltyBPS[collectionAddress][tokenId] = basisPoints;
        emit TokenRoyaltiesUpdated(
            collectionAddress,
            tokenId,
            receivers,
            basisPoints
        );
    }

    /**
     * @dev Set royalty lookup address for collection
     **/
    function setRoyaltyLookupAddress(
        address _collectionAddress,
        address _royaltyLookupAddress
    ) external nonReentrant {
        require(
            isAdmin(msg.sender) ||
                _isCollectionAdmin(_collectionAddress, msg.sender) ||
                _isCollectionOwner(_collectionAddress, msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            !blacklistedCollectionAddress.contains(_collectionAddress) &&
                !blacklistedWalletAddress.contains(msg.sender),
            "Sender and CollectionAddress should not be blacklisted"
        );
        royaltyLookupAddress[_collectionAddress] = _royaltyLookupAddress;
        emit RoyaltyOverride(
            msg.sender,
            _collectionAddress,
            _royaltyLookupAddress
        );
    }

    /**
     * @dev Get royalty lookup address of a collection.  Returns list of receivers and basisPoints
     **/
    function getRoyaltyLookupAppress(
        address collectionAddress
    ) external view returns (address) {
        return royaltyLookupAddress[collectionAddress];
    }

    /**
     * @dev Get royalites of a collection.  Returns list of receivers and basisPoints
     **/
    function getCollectionRoyalty(
        address collectionAddress
    )
        external
        view
        override
        returns (
            address payable[] memory recipients,
            uint256[] memory basisPoints
        )
    {
        if (collectionRoyaltyReceivers[collectionAddress].length > 0) {
            recipients = collectionRoyaltyReceivers[collectionAddress];
            basisPoints = collectionRoyaltyBPS[collectionAddress];
            return (recipients, basisPoints);
        }
    }

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     **/
    function getRoyalty(
        address collectionAddress,
        uint256 tokenId
    )
        external
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory basisPoints
        )
    {
        if (tokenRoyaltyReceivers[collectionAddress][tokenId].length > 0) {
            recipients = tokenRoyaltyReceivers[collectionAddress][tokenId];
            basisPoints = tokenRoyaltyBPS[collectionAddress][tokenId];
        } else if (collectionRoyaltyReceivers[collectionAddress].length > 0) {
            recipients = collectionRoyaltyReceivers[collectionAddress];
            basisPoints = collectionRoyaltyBPS[collectionAddress];
        } else if (
            royaltyLookupProvider != address(0) &&
            royaltyEngineProvider != address(0) &&
            IRoyaltyRegistry(royaltyLookupProvider).getRoyaltyLookupAddress(
                collectionAddress
            ) !=
            collectionAddress
        ) {
            (recipients, basisPoints) = IRoyaltyEngineV1(royaltyEngineProvider)
                .getRoyaltyView(collectionAddress, tokenId, 10_000);
            // ToDo need to add all the upcomming royalty standard here
        } else if (royaltyLookupAddress[collectionAddress] != address(0)) {
            address lookupContract = royaltyLookupAddress[collectionAddress];
            uint256 value = 10_000;
            // ARTBLOCKS : Supports artblocks interface to get Royalty Info
            try
                IArtBlocksOverride(lookupContract).getRoyalties(
                    collectionAddress,
                    tokenId
                )
            returns (
                address payable[] memory recipients_,
                uint256[] memory bps
            ) {
                return (recipients_, bps);
            } catch {}
            // EIP2981 AND ROYALTYSPLITTER : Supports EIP2981 and royaltysplitter interface to get Royalty Info
            try IEIP2981(lookupContract).royaltyInfo(tokenId, value) returns (
                address recipient,
                uint256 amount
            ) {
                address payable[] memory recipients_ = new address payable[](1);
                uint256[] memory bps_ = new uint256[](1);
                recipients_[0] = payable(recipient);
                bps_[0] = amount;
                return (recipients_, bps_);
            } catch {}
            // ToDo need to add all the upcomming royalty lookup standards here
        } else {
            try royaltyEngineV1.getRoyalty(collectionAddress, tokenId) returns (
                address payable[] memory recipients_,
                uint256[] memory bps
            ) {
                return (recipients_, bps);
            } catch {
                return (recipients, basisPoints);
            }
        }
        return (recipients, basisPoints);
    }

    /**
     * @dev checks the admin role of caller
     **/
    function _isCollectionAdmin(
        address collectionAddress,
        address collectionAdmin
    ) internal view returns (bool isAdmin) {
        if (
            ERC165Checker.supportsInterface(
                collectionAddress,
                type(IAdminControl).interfaceId
            ) && IAdminControl(collectionAddress).isAdmin(collectionAdmin)
        ) {
            return true;
        }
    }

    /**
     * @dev checks the Owner role of caller
     **/
    function _isCollectionOwner(
        address collectionAddress,
        address collectionAdmin
    ) internal view returns (bool isOwner) {
        try OwnableUpgradeable(collectionAddress).owner() returns (
            address collectionowner
        ) {
            if (collectionowner == collectionAdmin) return true;
        } catch {}

        try
            IAccessControlUpgradeable(collectionAddress).hasRole(
                0x00,
                collectionAdmin
            )
        returns (bool hasRole) {
            if (hasRole) return true;
        } catch {}

        return false;
    }

    /**
     * @dev Sets the collection or wallet address as blacklisted
     **/
    function blacklistAddress(
        address commonAddress
    ) external override adminRequired {
        if (Address.isContract(commonAddress)) {
            if (!blacklistedCollectionAddress.contains(commonAddress)) {
                blacklistedCollectionAddress.add(commonAddress);
            }
        } else {
            if (!blacklistedWalletAddress.contains(commonAddress)) {
                blacklistedWalletAddress.add(commonAddress);
            }
        }
        emit AddedBlacklistedAddress(commonAddress, msg.sender);
    }

    /**
     * @dev revoke the blacklistedAddress
     **/
    function revokeBlacklistedAddress(
        address commonAddress
    ) external override adminRequired {
        if (blacklistedCollectionAddress.contains(commonAddress)) {
            emit RevokedBlacklistedAddress(commonAddress, msg.sender);
            blacklistedCollectionAddress.remove(commonAddress);
        } else if (blacklistedWalletAddress.contains(commonAddress)) {
            emit RevokedBlacklistedAddress(commonAddress, msg.sender);
            blacklistedWalletAddress.remove(commonAddress);
        }
    }

    /**
     * @dev Set royaltyLookupProvider address
     */
    function setRoyaltyLookupProvider(
        address _royaltyLookupProvider
    ) external adminRequired {
        require(
            Address.isContract(_royaltyLookupProvider),
            "lookupProvider should be a contract"
        );
        royaltyLookupProvider = _royaltyLookupProvider;
    }

    /**
     * @dev Set royaltyEngineProvider address
     */
    function setRoyaltyEngineProvider(
        address _royaltyEngineProvider
    ) external adminRequired {
        require(
            Address.isContract(_royaltyEngineProvider),
            "lookupProvider should be a contract"
        );
        royaltyEngineProvider = _royaltyEngineProvider;
    }

    /**
     * @dev checks the blacklistedAddress
     **/
    function isBlacklistedAddress(
        address commonAddress
    ) external view returns (bool) {
        return (blacklistedCollectionAddress.contains(commonAddress) ||
            blacklistedWalletAddress.contains(commonAddress));
    }
    /**
     * @dev Set royaltyEngineV1 address and basis points address
     */
    function updateContractData(
        address _royaltyEngineV1,
        uint16 _maxBasisPoints
    ) external adminRequired {
        require(
            _maxBasisPoints < 10_000,
            "maxBasisPoints should not be equal or exceed than the value 10_000"
        );
        maxBps = _maxBasisPoints;
        royaltyEngineV1 = IRoyaltyEngine(_royaltyEngineV1);
    }
    /**
     * @dev Withdraw the funds to owner
     **/
    function withdraw() external adminRequired {
        bool success;
        address payable to = payable(msg.sender);
        (success, ) = to.call{value: address(this).balance}(new bytes(0));
        require(success, "withdraw failed");
        emit WithdrawPayout(to, address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
