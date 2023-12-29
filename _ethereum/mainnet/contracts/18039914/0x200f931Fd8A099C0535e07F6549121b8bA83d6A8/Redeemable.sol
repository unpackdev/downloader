// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ERC165Checker.sol";
import "./IERC721CreatorCore.sol";
import "./IERC1155CreatorCore.sol";
import "./AdminControlUpgradeable.sol";
import "./IAdminControl.sol";
import "./IAccessControlUpgradeable.sol";
import "./INiftyGateway.sol";
import "./IFoundation.sol";
import "./ECDSA.sol";

interface ERC721 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ERC1155 {
    function uri(uint256 tokenId) external view returns (string memory);
}

/**
 * @title Redeemable
 * @dev This contract facilitates the users to provide a nft from one collection and reedem an
 * nft from an another collection.
 */
contract Redeemable is AdminControlUpgradeable {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    // Total No.of token quantity limt in this contract
    uint256 public Max_Quantity;

    // Interface ID constants
    bytes4 constant ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 constant ERC1155_INTERFACE_ID = 0xd9b67a26;

    /// @notice The details to be provided to RedeemDetails
    /// @param newCollectionAddress New Collection token contract address
    /// @param tokenHoldingAddress Address to hold the old collection - nft token
    /// @param mintLimit total limit to mint in a collection
    /// @param maxEndRange should not allow to mint more than the set end range
    /// @param extensionBaseUri the token uri set for the extension in a collection
    /// @param clientName Name of the client
    struct RedeemDetails {
        address newCollectionAddress;
        address tokenHoldingAddress;
        uint256 mintLimit;
        uint256 maxEndRange;
        bool extensionBaseUri;
        string clientName;
    }

    /// @notice The details to be provided to Redeemer
    /// @param CollectionAddress NFT Collection address
    /// @param tokenId New minted tokenId
    /// @param quantity the number of tokens
    /// @param owneraddress the owner of the tokenId
    /// @param status Status that token is redeemed or not
    struct Redeemer {
        address newCollectionAddress;
        uint256 tokenId;
        uint256 quantity;
        address owneraddress;
    }

    /// @notice The signing data by admin
    /// @param expirationTime the expiration time for the signature
    /// @param nonce the unique nonce for the signature
    /// @param signature the signature data given by signer
    /// @param signer the address of the signer
    struct Approval {
        uint32 expirationTime;
        string nonce;
        bytes signature;
        address signer;
    }

    // total minted tokens mapped against the collectons address
    mapping(address => uint256) public totalMinted;

    // storing the RedeemDetails against the redeemCollection Address
    mapping(address => RedeemDetails) public RedeemDetailsList;

    // storing the RedeemerDetails against the Collection Address and tokenId
    mapping(address => mapping(uint256 => Redeemer)) public RedeemerDetailsList;

    // admin approval requirement
    bool public adminApprovalRequired;

    // signature validation
    mapping(bytes => bool) public signatureUsed;

    // Event log to emit when the redeemCollections is given
    event RedeemCreatedOrUpdated(
        address redeemCollectionAddress,
        address newCollectionAddress,
        address tokenHoldingAddress,
        uint256 mintLimit,
        uint256 maxEndRange,
        bool extensionBaseUri,
        string clientName,
        string createOrupdate
    );

    // Event log to emit when the redeemCollections is removed
    event RedeemRemoved(
        address redeemCollectionAddress,
        address newCollectionAddress,
        string clientName
    );

    // Event log to emit when the token is redeemed
    event RedeemedDetails(
        address redeemCollectionAddress,
        address MintedCollectionAddress,
        uint256[] tokenId,
        uint256 quantity,
        address owneraddress,
        bool status
    );

    // Event log to emit url
    event CollectionBaseURL(string url, address nftContractAddress);

    /// @param _maxQuantity Total No.of token quantity limt for minting in this contract
    /// @param _adminApprovalRequired the admin approval required flag for executing the transaction
    constructor(uint256 _maxQuantity, bool _adminApprovalRequired) {
        Max_Quantity = _maxQuantity;
        adminApprovalRequired = _adminApprovalRequired;
        __Ownable_init();
    }

    /// @notice Create a Redeem functionality for the collection Address
    /// @param redeemCollectionAddress Order struct consists of the listedtoken details
    /// @param list list struct consists of the
    function createorUpdateRedeem(
        address redeemCollectionAddress,
        RedeemDetails memory list
    ) external {
        require(
            isAdmin(msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            redeemCollectionAddress != list.newCollectionAddress,
            "Redeemable and Unredeemable Collection Addresses should not be the same"
        );
        require(
            list.mintLimit > 0 && list.maxEndRange >= 0,
            "token minting limit should not be zero while creating the sale"
        );
        string memory createorUpdate = RedeemDetailsList[
            redeemCollectionAddress
        ].newCollectionAddress == address(0)
            ? "Created"
            : "updated";
        RedeemDetailsList[redeemCollectionAddress] = list;

        emit RedeemCreatedOrUpdated(
            redeemCollectionAddress,
            list.newCollectionAddress,
            list.tokenHoldingAddress,
            list.mintLimit,
            list.maxEndRange,
            list.extensionBaseUri,
            list.clientName,
            createorUpdate
        );
    }

    //Redeem an NFT From the List.

    function redeem(
        address redeemCollectionAddress,
        uint256 tokenId,
        address claimer,
        uint256 quantity,
        string memory tokenURI,
        Approval calldata approval
    ) external {
        RedeemDetails memory reedemDetails = RedeemDetailsList[
            redeemCollectionAddress
        ];
        require(
            reedemDetails.newCollectionAddress != address(0),
            "Mentioned address doesn't have any proper details. Please create and update the details if necessary"
        );
        require(
            isAdmin(msg.sender) || msg.sender == claimer,
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            reedemDetails.mintLimit >
                totalMinted[reedemDetails.newCollectionAddress],
            "the collection has reached its mint limit"
        );
        if (adminApprovalRequired ) {
            require(
                isAdmin(approval.signer),
                "only owner or admin can sign for discount"
            );
            require(
                !signatureUsed[approval.signature],
                "signature already applied"
            );
            require(
                _verifySignature(
                    claimer,
                    approval.expirationTime,
                    approval.signer,
                    approval.nonce,
                    approval.signature
                ),
                "invalid approval signature"
            );
            signatureUsed[approval.signature] = true;

        }

        // transfer token from customer wallet to our tokenHolding address

        _tokenTransaction(
            redeemCollectionAddress,
            tokenId,
            claimer,
            reedemDetails.tokenHoldingAddress,
            quantity
        );

        string[] memory baseuri = new string[](1);
        if (reedemDetails.extensionBaseUri ||reedemDetails.tokenHoldingAddress == address(0) ) {
            baseuri[0] = tokenURI;            
        } else {
            baseuri[0] = getbaseURL(redeemCollectionAddress, tokenId);
        }
        uint256 mintTokenId;
        Redeemer memory reedener = RedeemerDetailsList[redeemCollectionAddress][
            tokenId
        ];
        if (
            IERC165(redeemCollectionAddress).supportsInterface(
                ERC1155_INTERFACE_ID
            ) && reedener.tokenId != 0
        ) {
            mintTokenId = reedener.tokenId;
        } else {
            require(reedener.tokenId == 0, "Given tokenId is already redeemed");
        }

        // mint token to the customer
        uint256[] memory nftTokenId = _tokenMint(
            reedemDetails.newCollectionAddress,
            claimer,
            mintTokenId,
            quantity,
            baseuri,
            reedemDetails.maxEndRange
        );
        totalMinted[reedemDetails.newCollectionAddress] += 1;

        if (reedener.tokenId != 0) {
            RedeemerDetailsList[redeemCollectionAddress][tokenId]
                .quantity += quantity;
        } else {
            RedeemerDetailsList[redeemCollectionAddress][tokenId] = Redeemer(
                reedemDetails.newCollectionAddress,
                nftTokenId[0],
                quantity,
                claimer
            );
        }

        emit RedeemedDetails(
            redeemCollectionAddress,
            reedemDetails.newCollectionAddress,
            nftTokenId,
            quantity,
            claimer,
            true
        );

    }

    //Remove newCollectionAddress
    function removeCollectionAddress(address redeemCollectionAddress) external {
        require(
            isAdmin(msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            RedeemDetailsList[redeemCollectionAddress].newCollectionAddress !=
                address(0),
            "invalid redeemCollectionAddress"
        );
        delete (RedeemDetailsList[redeemCollectionAddress]);

        emit RedeemRemoved(
            redeemCollectionAddress,
            RedeemDetailsList[redeemCollectionAddress].newCollectionAddress,
            RedeemDetailsList[redeemCollectionAddress].clientName
        );
    }

    function getbaseURL(
        address collectionAddress,
        uint256 tokenId
    ) internal view returns (string memory uri) {
        if (IERC165(collectionAddress).supportsInterface(ERC721_INTERFACE_ID)) {
            uri = ERC721(collectionAddress).tokenURI(tokenId);
        } else if (
            IERC165(collectionAddress).supportsInterface(ERC1155_INTERFACE_ID)
        ) {
            uri = ERC1155(collectionAddress).uri(tokenId);
        }

        return uri;
    }

    // transfer function

    function _tokenTransaction(
        address _tokenContract,
        uint256 _tokenId,
        address _tokenOwner,
        address _receiver,
        uint256 _quantity
    ) internal  {
        bool status;
        if (IERC165(_tokenContract).supportsInterface(ERC721_INTERFACE_ID)) {
            require(
                IERC721(_tokenContract).ownerOf(_tokenId) == _tokenOwner,
                "maker is not the owner"
            );
            if(_receiver != address(0)) {
            IERC721(_tokenContract).safeTransferFrom(
                _tokenOwner,
                _receiver,
                _tokenId
            );
            }else {
                IERC721CreatorCore(_tokenContract).burn(_tokenId);
            }

            status = true;
        } else if (
            IERC165(_tokenContract).supportsInterface(ERC1155_INTERFACE_ID)
        ) {
            uint256 ownerBalance = IERC1155(_tokenContract).balanceOf(
                _tokenOwner,
                _tokenId
            );
            require(
                _quantity <= ownerBalance && _quantity > 0,
                "Insufficeint token balance"
            );
            if(_receiver != address(0)) {
            IERC1155(_tokenContract).safeTransferFrom(
                _tokenOwner,
                _receiver,
                _tokenId,
                _quantity,
                "0x"
            );
            } else {
            uint256[] memory tokenIds = new uint256[](1);
            uint256[] memory amounts = new uint256[](1);
            tokenIds[0] = _tokenId;
            amounts[0] = _quantity;
                IERC1155CreatorCore(_tokenContract).burn(_tokenOwner,tokenIds,amounts);
            }
            status = true;
        }
        require(status == true, "token transaction not executed for the collection nft");

    }

    // Minting function

    function _tokenMint(
        address _tokenContract,
        address _claimer,
        uint256 mintTokenId,
        uint256 _quantity,
        string[] memory _uris,
        uint256 maxEndRange
    ) internal returns (uint256[] memory ) {
        uint256[] memory nftTokenId = new uint256[](1);
        //ERC721
        if (IERC165(_tokenContract).supportsInterface(ERC721_INTERFACE_ID)) {
            nftTokenId[0] = IERC721CreatorCore(_tokenContract).mintExtension(
                _claimer,
                _uris[0]
            );
        }
        //ERC1155
        else if (
            IERC165(_tokenContract).supportsInterface(ERC1155_INTERFACE_ID)
        ) {
            require(_quantity > 0, "Need to mint at least 1 token.");
            require(_quantity <= Max_Quantity, "Cannot exceed Max_Quantity.");

            address[] memory to = new address[](1);
            uint256[] memory quantity = new uint256[](1);
            to[0] = _claimer;
            quantity[0] = _quantity;
            if (
                IERC1155CreatorCore(_tokenContract).totalSupply(mintTokenId) ==
                0
            ) {
                nftTokenId = IERC1155CreatorCore(_tokenContract)
                    .mintExtensionNew(to, quantity, _uris);
            } else if (
                IERC1155CreatorCore(_tokenContract).totalSupply(mintTokenId) > 0
            ) {
                uint256[] memory tokenId = new uint256[](1);
                tokenId[0] = mintTokenId;
                // Minting new ERC1155 tokens
                IERC1155CreatorCore(_tokenContract).mintExtensionExisting(
                    to,
                    tokenId,
                    quantity
                );
                nftTokenId = tokenId;
            }
        }
        if(maxEndRange != 0) {
        require(
            nftTokenId[0] <= maxEndRange,
            "nft token Id has reached the max range"
        );
        }
        return nftTokenId;
    }

    /**
     * @notice Update extension's baseURI
     * @dev Can only be done by Admin
     */
    function setBaseURI(
        address redeemcollectionaddress,
        string memory baseURI_
    ) external {
        require(
            isAdmin(msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );

        address _tokenContract = RedeemDetailsList[redeemcollectionaddress]
            .newCollectionAddress;

        if (IERC165(_tokenContract).supportsInterface(ERC721_INTERFACE_ID)) {
            IERC721CreatorCore(_tokenContract).setBaseTokenURIExtension(
                baseURI_
            );
        } else if (
            IERC165(_tokenContract).supportsInterface(ERC1155_INTERFACE_ID)
        ) {
            IERC1155CreatorCore(_tokenContract).setBaseTokenURIExtension(
                baseURI_,
                false
            );
        }
        emit CollectionBaseURL(baseURI_, _tokenContract);
    }

    function _verifySignature(
        address buyer,
        uint32 expirationTime,
        address _signer,
        string calldata nonce,
        bytes calldata _signature
    ) internal view returns (bool) {
        require(
            expirationTime >= block.timestamp,
            "admin signature is already expired"
        );
        return
            keccak256(
                abi.encodePacked(
                    buyer,
                    expirationTime,
                    nonce,
                    "REEDEMABLES",
                    block.chainid
                )
            ).toEthSignedMessageHash().recover(_signature) == _signer;
    }

    /**
     * @notice updateAdminApproval, updates the admin approval
     * @param _adminApprovalRequired the boolean value of _adminApprovalRequired
     */
    function updateAdminApproval(bool _adminApprovalRequired) external adminRequired {
        adminApprovalRequired = _adminApprovalRequired;
    }
    /**
     * @notice updateMaxQuantity, updates the 1155 nft toke quantity
     * @param _maxQuantity the uint value of _maxQuantity
     */
    function updateMaxQuantity(uint256 _maxQuantity) external adminRequired {
        Max_Quantity = _maxQuantity;
    }
}