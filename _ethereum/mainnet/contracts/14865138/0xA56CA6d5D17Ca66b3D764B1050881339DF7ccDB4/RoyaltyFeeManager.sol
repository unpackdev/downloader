// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./IERC2981.sol";
import "./IOwnable.sol";
import "./IRoyaltyFeeManager.sol";

/**
 * @title RoyaltyFeeManager
 * @notice It is a royalty fee registry for the LooksRare exchange.
 */
contract RoyaltyFeeManager is IRoyaltyFeeManager, Ownable {
    struct FeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }

    struct JumyCollectionTokenFeeInfo {
        address receiver;
        uint256 fee;
    }
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // ERC2981 interfaceID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Limit (if enforced for fee royalty in percentage (10,000 = 100%)
    uint256 public royaltyFeeLimit;

    bool public mutableRoyalty;

    mapping(address => FeeInfo) private _royaltyFeeInfoCollection;

    mapping(address => bool) public isRoyaltySetter;

    mapping(address => mapping(uint256 => JumyCollectionTokenFeeInfo))
        public jumyCollectionTokenFeeInfos;

    modifier onlyIfMutable() {
        require(!mutableRoyalty, "Royalty: Not mutable");
        _;
    }

    event NewRoyaltyFeeLimit(uint256 royaltyFeeLimit);
    event RoyaltyFeeUpdate(
        address indexed collection,
        address indexed setter,
        address indexed receiver,
        uint256 fee
    );

    // Dismiss indexing to save gas fees
    event JumyTokenRoyaltyFeeUpdated(
        address collection,
        uint256 tokenId,
        address receiver,
        uint256 fee
    );

    /**
     * @notice Constructor
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    constructor(uint256 _royaltyFeeLimit) {
        require(_royaltyFeeLimit <= 3000, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    function changeMutability(bool state) external onlyOwner {
        require(mutableRoyalty != state, "Already in state");
        mutableRoyalty = state;
    }

    function setJumyTokenRoyalty(
        address collection,
        uint256 tokenId,
        address receiver,
        uint256 percentage
    ) external override {
        require(isRoyaltySetter[msg.sender], "Not Allowed");

        require(
            jumyCollectionTokenFeeInfos[collection][tokenId].receiver ==
                address(0),
            "RoyaltyManager: Already set"
        );
        require(
            percentage <= royaltyFeeLimit,
            "Registry: Royalty fee too high"
        );

        jumyCollectionTokenFeeInfos[collection][
            tokenId
        ] = JumyCollectionTokenFeeInfo({fee: percentage, receiver: receiver});

        emit JumyTokenRoyaltyFeeUpdated(
            collection,
            tokenId,
            receiver,
            percentage
        );
    }

    function updateRoyaltySetter(address setter, bool state)
        external
        onlyOwner
    {
        isRoyaltySetter[setter] = state;
    }

    /**
     * @notice Update royalty info for collection if admin
     * @dev Only to be called if there is no setter address
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyIfMutable {
        require(
            !IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981),
            "Admin: Must not be ERC2981"
        );
        require(
            msg.sender == IOwnable(collection).admin(),
            "Admin: Not the admin"
        );

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
            collection,
            setter,
            receiver,
            fee
        );
    }

    /**
     * @notice Update royalty info for collection if owner
     * @dev Only to be called if there is no setter address
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfOwner(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyIfMutable {
        require(
            !IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981),
            "Owner: Must not be ERC2981"
        );
        require(
            msg.sender == IOwnable(collection).owner(),
            "Owner: Not the owner"
        );

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
            collection,
            setter,
            receiver,
            fee
        );
    }

    /**
     * @notice Update royalty info for collection
     * @dev Only to be called if there msg.sender is the setter
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfSetter(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyIfMutable {
        (address currentSetter, , ) = getRoyaltyFeeInfoCollection(collection);
        require(msg.sender == currentSetter, "Setter: Not the setter");

        _updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     * @notice Update royalty info for collection
     * @dev Can only be called by contract owner (of this)
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external override onlyOwner {
        _updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     * @notice Check royalty info for collection
     * @param collection collection address
     * @return (whether there is a setter (address(0 if not)),
     * Position
     * 0: Royalty setter is set in the registry
     * 1: ERC2981 and no setter
     * 2: setter can be set using owner()
     * 3: setter can be set using admin()
     * 4: setter cannot be set, nor support for ERC2981
     */
    function checkForCollectionSetter(address collection)
        external
        view
        returns (address, uint8)
    {
        (address currentSetter, , ) = getRoyaltyFeeInfoCollection(collection);

        if (currentSetter != address(0)) {
            return (currentSetter, 0);
        }

        try
            IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)
        returns (bool interfaceSupport) {
            if (interfaceSupport) {
                return (address(0), 1);
            }
        } catch {}

        try IOwnable(collection).owner() returns (address setter) {
            return (setter, 2);
        } catch {
            try IOwnable(collection).admin() returns (address setter) {
                return (setter, 3);
            } catch {
                return (address(0), 4);
            }
        }
    }

    /**
     * @notice Update information and perform checks before updating royalty fee registry
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal {
        (address currentSetter, , ) = getRoyaltyFeeInfoCollection(collection);
        require(currentSetter == address(0), "Setter: Already set");

        require(
            (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
                IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            "Setter: Not ERC721/ERC1155"
        );

        _updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }

    /**
     * @notice Calculate royalty fee and get recipient
     * @param collection address of the NFT contract
     * @param tokenId tokenId
     * @param amount amount to transfer
     */
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view override returns (address, uint256) {
        address jumyTokenReceiver = jumyCollectionTokenFeeInfos[collection][
            tokenId
        ].receiver;

        if (jumyTokenReceiver != address(0)) {
            uint256 royaltyPercentage = jumyCollectionTokenFeeInfos[collection][
                tokenId
            ].fee;

            return (jumyTokenReceiver, (amount * royaltyPercentage) / 10_000);
        }

        // 2. Check if there is a royalty info in the system
        (address receiver, uint256 royaltyAmount) = _royaltyInfo(
            collection,
            amount
        );

        // 3. If the receiver is address(0), fee is null, check if it supports the ERC2981 interface
        if ((receiver == address(0)) || (royaltyAmount == 0)) {
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)) {
                (receiver, royaltyAmount) = IERC2981(collection).royaltyInfo(
                    tokenId,
                    amount
                );
            }
        }
        return (receiver, royaltyAmount);
    }

    /**
     * @notice Update royalty info for collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit)
        external
        override
        onlyOwner
    {
        require(_royaltyFeeLimit <= 9500, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;

        emit NewRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     * @notice Update royalty info for collection
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal {
        require(fee <= royaltyFeeLimit, "Registry: Royalty fee too high");
        _royaltyFeeInfoCollection[collection] = FeeInfo({
            setter: setter,
            receiver: receiver,
            fee: fee
        });

        emit RoyaltyFeeUpdate(collection, setter, receiver, fee);
    }

    /**
     * @notice Calculate royalty info for a collection address and a sale gross amount
     * @param collection collection address
     * @param amount amount
     * @return receiver address and amount received by royalty recipient
     */
    function royaltyInfo(address collection, uint256 amount)
        external
        view
        override
        returns (address, uint256)
    {
        return _royaltyInfo(collection, amount);
    }

    function _royaltyInfo(address collection, uint256 amount)
        private
        view
        returns (address, uint256)
    {
        return (
            _royaltyFeeInfoCollection[collection].receiver,
            (amount * _royaltyFeeInfoCollection[collection].fee) / 10_000
        );
    }

    /**
     * @notice View royalty info for a collection address
     * @param collection collection address
     */
    function royaltyFeeInfoCollection(address collection)
        external
        view
        override
        returns (
            address,
            address,
            uint256
        )
    {
        return getRoyaltyFeeInfoCollection(collection);
    }

    /**
     * @notice View royalty info for a collection address
     * @param collection collection address
     */
    function getRoyaltyFeeInfoCollection(address collection)
        private
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (
            _royaltyFeeInfoCollection[collection].setter,
            _royaltyFeeInfoCollection[collection].receiver,
            _royaltyFeeInfoCollection[collection].fee
        );
    }
}
