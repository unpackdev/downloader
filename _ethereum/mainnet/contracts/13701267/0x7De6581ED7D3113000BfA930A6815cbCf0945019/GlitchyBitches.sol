// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 Arran Schlosberg (@divergencearran / @divergence_art)
pragma solidity >=0.8.0 <0.9.0;

import "./MetaPurse.sol";
import "./SignatureRegistry.sol";
import "./ERC721Common.sol";
import "./FixedPriceSeller.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract GlitchyBitches is ERC721Common, FixedPriceSeller {
    /// @notice Separate contracts for GB metadata and signer set.
    MetaPurse public immutable metapurse;
    SignerRegistry public immutable signers;

    constructor(
        string memory name,
        string memory symbol,
        address openSeaProxyRegistry,
        address[] memory _signers,
        address payable beneficiary
    )
        ERC721Common(name, symbol, openSeaProxyRegistry)
        FixedPriceSeller(
            0.07 ether,
            Seller.SellerConfig({
                totalInventory: 10101,
                maxPerAddress: 10,
                maxPerTx: 10
            }),
            beneficiary
        )
    {
        metapurse = new MetaPurse();
        metapurse.transferOwnership(owner());

        signers = new SignerRegistry(_signers);
        signers.transferOwnership(owner());
    }

    /// @notice An initial mint window provides minters with an extra 30 days of
    /// version-changing allowance.
    bool public earlyMinting = true;

    /// @notice Limits minting to those with a valid signature.
    bool public onlyAllowList = true;

    /// @notice Toggle the early-minting and only-allowlist flags.
    function setMintingFlags(bool allowList, bool early) external onlyOwner {
        earlyMinting = early;
        onlyAllowList = allowList;
    }

    /// @notice Mints for the recipient., requiring a signature iff the
    /// onlyAllowList flag is set to true, otherwise signature is
    /// @dev The message sender MAY be different to the recipient although the
    /// signature is always expected to be for the recipient.
    /// @param signature Required iff the onlyAllowList flag is set to true,
    /// otherwise an empty value can be sent.
    function safeMint(
        address to,
        uint256 num,
        bytes calldata signature
    ) external payable {
        if (onlyAllowList) {
            signers.validateSignature(to, signature);
        }
        Seller._purchase(to, num);
    }

    /**
    @notice Maximum number of tokens that the contract owner can mint for free
    over the life of the contract.
     */
    uint256 public ownerQuota = 500;

    /// @notice Contract owner can mint free of charge up to the quota.
    function ownerMint(address to, uint256 num) external onlyOwner {
        require(
            num <= ownerQuota &&
                num <= sellerConfig.totalInventory - totalSupply(),
            "Owner quota reached"
        );
        ownerQuota -= num;
        _handlePurchase(to, num);
    }

    /// @notice Mint new tokens for the recipient.
    function _handlePurchase(address to, uint256 num) internal override {
        for (uint256 i = 0; i < num; i++) {
            ERC721._safeMint(to, totalSupply());
        }
        metapurse.newTokens(num, earlyMinting);
    }

    /// @notice Prefix for tokenURI(). MUST NOT include a trailing slash.
    string public _baseTokenURI;

    /// @notice Change the tokenURI() prefix value.
    /// @param uri The new base, which MUST NOT include a trailing slash.
    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /// @notice Required override of Seller.totalSold().
    function totalSold() public view override returns (uint256) {
        return ERC721Enumerable.totalSupply();
    }

    /// @notice Returns the URI for token metadata.
    /// @dev In the initial stages this will be centralised so as to hide future
    /// token versions, but will eventually be moved to IPFS after all are
    /// revealed.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    "/",
                    Strings.toString(tokenId),
                    "_",
                    Strings.toString(metapurse.tokenVersion(tokenId)),
                    ".json"
                )
            );
    }
}
