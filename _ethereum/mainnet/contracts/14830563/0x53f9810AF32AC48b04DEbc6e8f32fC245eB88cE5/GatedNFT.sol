// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

// solhint-disable-next-line max-line-length
import "./ITier.sol";
import "./base64.sol";
// solhint-disable-next-line max-line-length
import "./TierReport.sol";
// solhint-disable-next-line max-line-length
import "./OwnableUpgradeable.sol";
// solhint-disable-next-line max-line-length
import "./IERC2981Upgradeable.sol";
// solhint-disable-next-line max-line-length
import "./ERC721Upgradeable.sol";
// solhint-disable-next-line max-line-length
import "./CountersUpgradeable.sol";

contract GatedNFT is
    IERC165Upgradeable,
    IERC2981Upgradeable,
    ERC721Upgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event CreatedGatedNFT(
        address contractAddress,
        address creator,
        Config config,
        ITier tier,
        uint256 minimumStatus,
        uint256 maxPerAddress,
        Transferrable transferrable,
        uint256 maxMintable,
        address royaltyRecipient,
        uint256 royaltyBPS
    );

    event UpdatedRoyaltyRecipient(
        address royaltyRecipient
    );

    struct Config {
        string name;
        string symbol;
        string description;
        string animationUrl;
        string imageUrl;
        bytes32 animationHash;
        bytes32 imageHash;
    }

    enum Transferrable {
        NonTransferrable,
        Transferrable,
        TierGatedTransferrable
    }

    CountersUpgradeable.Counter private tokenIdCounter;

    Config private config;

    ITier public tier;

    uint256 private minimumStatus;

    uint256 private maxPerAddress;

    Transferrable private transferrable;

    uint256 private maxMintable;

    address private royaltyRecipient;

    uint256 private royaltyBPS;

    function initialize(
        address owner_,
        Config memory config_,
        ITier tier_,
        uint256 minimumStatus_,
        uint256 maxPerAddress_,
        Transferrable transferrable_,
        uint256 maxMintable_,
        address royaltyRecipient_,
        uint256 royaltyBPS_
    ) external initializer {
        require(
            royaltyRecipient_ != address(0),
            "Recipient cannot be 0 address"
        );
        __ERC721_init(config_.name, config_.symbol);
        __Ownable_init();
        transferOwnership(owner_);
        tier = ITier(tier_);
        config = config_;
        minimumStatus = minimumStatus_;
        maxPerAddress = maxPerAddress_;
        transferrable = transferrable_;
        maxMintable = maxMintable_;
        royaltyRecipient = royaltyRecipient_;
        royaltyBPS = royaltyBPS_;
        // Set tokenId to start at 1 instead of 0
        tokenIdCounter.increment();

        emit CreatedGatedNFT(
            address(this),
            owner_,
            config_,
            tier_,
            minimumStatus_,
            maxPerAddress_,
            transferrable_,
            maxMintable_,
            royaltyRecipient_,
            royaltyBPS_
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");
        return base64JSONMetadata();
    }

    function mint(address to) external returns (uint256) {
        require(
            TierReport.tierAtBlockFromReport(
                tier.report(to),
                block.number
            ) >= minimumStatus,
            "Address missing required tier"
        );
        require(
            balanceOf(to) < maxPerAddress,
            "Address has exhausted allowance"
        );
        uint256 tokenId = tokenIdCounter.current();
        require(tokenId <= maxMintable, "Total supply exhausted");
        _safeMint(to, tokenId);
        tokenIdCounter.increment();
        return tokenId;
    }

    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (royaltyRecipient == address(0x0)) {
            return (royaltyRecipient, 0);
        }
        return (royaltyRecipient, (salePrice_ * royaltyBPS) / 10_000);
    }

    function updateRoyaltyRecipient(address royaltyRecipient_) external
    {
        require(
            royaltyRecipient_ != address(0),
            "Recipient cannot be 0 address"
        );
        // solhint-disable-next-line reason-string
        require(
            msg.sender == royaltyRecipient,
            "Only current recipient can update"
        );

        royaltyRecipient = royaltyRecipient_;

        emit UpdatedRoyaltyRecipient(royaltyRecipient_);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) override internal virtual {
        require(
            transferrable != Transferrable.NonTransferrable,
            "Transfer not supported"
        );

        if (transferrable == Transferrable.TierGatedTransferrable) {
            require(
                TierReport.tierAtBlockFromReport(
                    tier.report(to),
                    block.number
                ) >= minimumStatus,
                "Address missing required tier"
            );
        }

        require(
            balanceOf(to) < maxPerAddress,
            "Address has exhausted allowance"
        );

        super._transfer(from, to, tokenId);
    }

    /// @dev returns the number of minted tokens
    function totalSupply() external view returns (uint256) {
        return tokenIdCounter.current() - 1;
    }

    function base64JSONMetadata()
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            // solhint-disable-next-line quotes
                            '{"name": "',
                            config.name,
                            // solhint-disable-next-line quotes
                            '", "description": "',
                            config.description,
                            // solhint-disable-next-line quotes
                            '"',
                            mediaJSONParts(),
                            // solhint-disable-next-line quotes
                            '}'
                        )
                    )
                )
            );
    }

    function mediaJSONParts() internal view returns (string memory) {
        bool hasImage = bytes(config.imageUrl).length > 0;
        bool hasAnimation = bytes(config.animationUrl).length > 0;
        if (hasImage && hasAnimation) {
            return
                string(
                    abi.encodePacked(
                    // solhint-disable-next-line quotes
                        ', "image": "',
                        config.imageUrl,
                        // solhint-disable-next-line quotes
                        '", "animation_url": "',
                        config.animationUrl,
                        // solhint-disable-next-line quotes
                        '"'
                    )
                );
        }
        if (hasImage) {
            return
                string(
                    abi.encodePacked(
                        // solhint-disable-next-line quotes
                        ', "image": "',
                        config.imageUrl,
                        // solhint-disable-next-line quotes
                        '"'
                    )
                );
        }
        if (hasAnimation) {
            return
                string(
                    abi.encodePacked(
                        // solhint-disable-next-line quotes
                        ', "animation_url": "',
                        config.animationUrl,
                        // solhint-disable-next-line quotes
                        '"'
                    )
                );
        }
        return "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }
}
