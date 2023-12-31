// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./ERC721AUpgradeable.sol";
import "./MerkleProof.sol";
import "./IERC721.sol";
import "./IERC2981Upgradeable.sol";
import "./ERC2981Upgradeable.sol";

import "./DropStructs.sol";

import "./AdministratedUpgradeable.sol";
import "./ERC721DropMetadata.sol";
import "./Payout.sol";

import "./IERC721DropImplementation.sol";

contract ERC721DropImplementation is
    AdministratedUpgradeable,
    ERC721DropMetadata,
    Payout,
    IERC721DropImplementation
{
    PublicMintStage public publicMintStage;
    mapping(uint256 allowlistStageId => AllowlistMintStage allowlistMintStage) public allowlistMintStages;
    mapping(address nftContract => TokenGatedMintStage mintStage)
        public tokenGatedMintStages;
    mapping(address nftContract => mapping(uint256 tokenId => bool redeemed))
        private _tokenGatedTokenRedeems;

    mapping(address minter => mapping(address nftContract => mapping(uint256 tokenId => bool redeemed)))
        private _tokenHolderRedeemed;

    uint256 internal constant PUBLIC_STAGE_INDEX = 0;
    uint256 internal constant ALLOWLIST_STAGE_INDEX = 1;
    uint256 internal constant TOKEN_GATED_STAGE_INDEX = 2;

    uint256 internal constant UNLIMITED_MAX_SUPPLY_FOR_STAGE = type(uint256).max;

    function initialize(
        string memory _name,
        string memory _symbol,
        address _administrator
    ) external initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Administrated_init(_administrator);
        __Payout_init();
        __Ownable_init();
        __ERC2981_init();
    }

    function mintPublic(address recipient, uint256 quantity) external payable {
        // Get the minter address. Default to msg.sender.
        address minter = recipient != address(0) ? recipient : msg.sender;

        // Ensure the payer is allowed if not caller
        _checkPayer(minter);

        if (tx.origin != msg.sender) {
            revert PayerNotAllowed();
        }

        // Ensure that public mint stage is active
        _checkStageActive(publicMintStage.startTime, publicMintStage.endTime);

        // Ensure correct mint quantity
        _checkMintQuantity(
            minter,
            quantity,
            publicMintStage.mintLimitPerWallet,
            UNLIMITED_MAX_SUPPLY_FOR_STAGE
        );

        // Ensure enough ETH is provided
        _checkFunds(msg.value, quantity, publicMintStage.mintPrice);

        // Mint tokens
        _mintBase(minter, quantity, PUBLIC_STAGE_INDEX);
    }

    function mintAllowlist(
        uint256 allowlistStageId,
        address recipient,
        uint256 quantity,
        bytes32[] calldata merkleProof
    ) external payable {
        // Get the minter address. Default to msg.sender.
        address minter = recipient != address(0) ? recipient : msg.sender;

        // Ensure the payer is allowed if not caller
        _checkPayer(minter);

        AllowlistMintStage memory allowlistMintStage = allowlistMintStages[allowlistStageId];

        // Ensure that allowlist mint stage is active
        _checkStageActive(
            allowlistMintStage.startTime,
            allowlistMintStage.endTime
        );

        // Ensure correct mint quantity
        _checkMintQuantity(
            minter,
            quantity,
            allowlistMintStage.mintLimitPerWallet,
            allowlistMintStage.maxSupplyForStage
        );

        // Ensure enough ETH is provided
        _checkFunds(msg.value, quantity, allowlistMintStage.mintPrice);

        if (
            !MerkleProof.verifyCalldata(
                merkleProof,
                allowlistMintStage.merkleRoot,
                keccak256(abi.encodePacked(minter))
            )
        ) {
            revert AllowlistStageInvalidProof();
        }

        _mintBase(minter, quantity, ALLOWLIST_STAGE_INDEX);
    }

    function mintTokenGated(
        address recipient,
        address nftContract,
        uint256[] calldata tokenIds
    ) external payable {
        // Get the minter address. Default to msg.sender.
        address minter = recipient != address(0) ? recipient : msg.sender;

        // Ensure the payer is allowed if not caller
        _checkPayer(minter);

        // Get token gated mint stage for NFT contract
        TokenGatedMintStage memory tokenGatedMintStage = tokenGatedMintStages[
            nftContract
        ];

        // For easier access
        uint256 quantity = tokenIds.length;

        // Ensure that token holder mint stage is active
        _checkStageActive(
            tokenGatedMintStage.startTime,
            tokenGatedMintStage.endTime
        );

        // Ensure correct mint quantity
        _checkMintQuantity(
            minter,
            quantity,
            tokenGatedMintStage.mintLimitPerWallet,
            tokenGatedMintStage.maxSupplyForStage
        );

        // Ensure enough ETH is provided
        _checkFunds(msg.value, quantity, tokenGatedMintStage.mintPrice);

        // For easier and cheaper access.
        mapping(uint256 => bool)
            storage redeemedTokenIds = _tokenGatedTokenRedeems[nftContract];

        // Iterate through each tokenIds to make sure it's not already claimed
        for (uint256 i = 0; i < quantity; ) {
            // For easier and cheaper access.
            uint256 tokenId = tokenIds[i];

            // Check that the minter is the owner of the tokenId.
            if (IERC721(nftContract).ownerOf(tokenId) != minter) {
                revert TokenGatedNotTokenOwner();
            }

            // Check that the token id has not already been redeemed.
            if (redeemedTokenIds[tokenId]) {
                revert TokenGatedTokenAlreadyRedeemed();
            }

            // Mark the token id as redeemed.
            redeemedTokenIds[tokenId] = true;

            unchecked {
                ++i;
            }
        }

        // Mint tokens
        _mintBase(minter, quantity, TOKEN_GATED_STAGE_INDEX);
    }

    function getTokenGatedIsRedeemed(
        address nftContract,
        uint256 tokenId
    ) external view returns (bool) {
        return _tokenGatedTokenRedeems[nftContract][tokenId];
    }

    function updatePublicMintStage(
        PublicMintStage calldata publicMintStageData
    ) external onlyOwnerOrAdministrator {
        _updatePublicMintStage(publicMintStageData);
    }

    function updateAllowlistMintStage(
        AllowlistMintStageConfig calldata allowlistMintStageConfig
    ) external onlyOwnerOrAdministrator {
        _updateAllowlistMintStage(allowlistMintStageConfig);
    }

    function updateTokenGatedMintStage(
        TokenGatedMintStageConfig calldata tokenGatedMintStageConfig
    ) external onlyOwnerOrAdministrator {
        _updateTokenGatedMintStage(tokenGatedMintStageConfig);
    }

    function updateConfiguration(
        MultiConfig calldata config
    ) external onlyOwnerOrAdministrator {
        // Update max supply
       _updateMaxSupply(config.maxSupply);

        // Update base URI
        _updateBaseURI(config.baseURI);

        // Update royalties
        if (config.royaltiesReceiver != address(0)) {
            _updateRoyalties(config.royaltiesReceiver, config.royaltiesFeeNumerator);
        }

        // Update payout
        if (config.payoutAddress != address(0)) {
            _updatePayoutAddress(config.payoutAddress);
        }

        // Update public phase
        _updatePublicMintStage(config.publicMintStage);

        // Update allowlist phases
       for (uint256 i = 0; i < config.allowlistMintStages.length; ) {
            _updateAllowlistMintStage(config.allowlistMintStages[i]);

            unchecked {
                ++i;
            }
        }

        // Update token gated phases
        for (uint256 i = 0; i < config.tokenGatedMintStages.length; ) {
            _updateTokenGatedMintStage(config.tokenGatedMintStages[i]);

            unchecked {
                ++i;
            }
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC2981Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function _updatePublicMintStage(
        PublicMintStage calldata publicMintStageData
    ) internal {
        publicMintStage = publicMintStageData;

        emit PublicMintStageUpdated(publicMintStageData);
    }

    function _updateAllowlistMintStage(
        AllowlistMintStageConfig calldata allowlistMintStageConfig
    ) internal {
        allowlistMintStages[allowlistMintStageConfig.id] = allowlistMintStageConfig.data;

        emit AllowlistMintStageUpdated(allowlistMintStageConfig.id, allowlistMintStageConfig.data);
    }

    function _updateTokenGatedMintStage(
        TokenGatedMintStageConfig calldata tokenGatedMintStageConfig
    ) internal {
        if (tokenGatedMintStageConfig.nftContract == address(0)) {
            revert TokenGatedNftContractCannotBeZeroAddress();
        }

        tokenGatedMintStages[tokenGatedMintStageConfig.nftContract] = tokenGatedMintStageConfig.data;

        emit TokenGatedMintStageUpdated(tokenGatedMintStageConfig.nftContract, tokenGatedMintStageConfig.data);
    }
}
