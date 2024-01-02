// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Math.sol";
import "./Pausable.sol";
import "./IDelegateRegistry.sol";
import "./IDelegationRegistry.sol";

contract GrapePreSale is Ownable, Pausable {
    /**
     * @dev Public immutable state
     */
    IERC721 public immutable grapeNFT;
    uint256 public immutable minimumSpendAmount; // must be in WEI. set by constructor only
    bytes32 public immutable referralCodeMerkleRoot;
    uint256 public immutable referralCapPerBuyer; // must be in WEI. set by constructor only
    uint256 public immutable capPerNFT; // must be in WEI. set by constructor only
    uint256 public immutable nftStartDate;
    uint256 public immutable referralStartDate;
    uint256 public immutable endDate;
    uint256 public immutable nftSaleCap;
    address payable public immutable receiverWallet;
    IDelegateRegistry public immutable delegateRegistryV2 =
        IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493);
    IDelegationRegistry public immutable delegateRegistryV1 =
        IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    /**
     * @dev Public mutable state
     */
    uint256 public nftSoldSupply = 0; // managed internally
    mapping(uint256 tokenId => uint256 amount) public nftPurchases; // managed internally
    mapping(address buyer => uint256 amount) public referralPurchases; // managed internally

    /**
     * @notice Emitted when a purchase is made with an NFT
     */
    event PurchaseWithNFT(address indexed buyer, uint256 amount);

    /**
     * @notice Emitted when a purchase is made with a referral code
     */
    event PurchaseWithReferralCode(address indexed buyer, uint256 amount);

    /**
     * @dev Errors
     */
    error BelowMinimumSpend();
    error Closed();
    error AmountExceedsSupply();
    error NotTokenOwner(uint256 tokenId);
    error InvalidPaymentAmount();
    error InvalidReferralCode();

    /**
     * @notice Creates a new instance of the GrapePreSale contract.
     * @param grapeNFTAddress_ The address of the ERC721 token (Grape NFT) involved in the pre-sale.
     * @param initialOwner_ The initial owner of the contract, typically the deployer or the main administrative account.
     * @param receiverWallet_ The wallet address where funds (ETH) collected from the pre-sale will be sent.
     * @param referralCodeMerkleRoot_ The root of the Merkle tree used for validating referral codes.
     * @param config_ Array containing the following config in order:
     *        referralCapPerBuyer: The maximum amount of WEI a buyer can spend using referral codes.
     *        capPerNFT: The maximum amount of WEI that can be spent per NFT in the pre-sale.
     *        nftStartDate: The start date of the NFT pre-sale, represented as a Unix timestamp.
     *        referralStartDate: The start date of the referral pre-sale, represented as a Unix timestamp.
     *        endDate: The end date of the pre-sale, represented as a Unix timestamp.
     *        minimumSpendAmount: The minimum amount of WEI that can be spent in the pre-sale.
     *        nftSaleCap: The maximum amount of WEI that can be spend for NFT purchases.
     */
    constructor(
        address grapeNFTAddress_,
        address initialOwner_,
        address payable receiverWallet_,
        bytes32 referralCodeMerkleRoot_,
        uint256[7] memory config_
    ) Ownable(initialOwner_) {
        grapeNFT = IERC721(grapeNFTAddress_);
        receiverWallet = receiverWallet_;
        referralCodeMerkleRoot = referralCodeMerkleRoot_;
        referralCapPerBuyer = config_[0];
        capPerNFT = config_[1];
        nftStartDate = config_[2];
        referralStartDate = config_[3];
        endDate = config_[4];
        minimumSpendAmount = config_[5];
        nftSaleCap = config_[6];
    }

    /**
     * @dev Modifiers
     */

    /**
     * @notice Require the amount to spend to be greater than the minimum spend value
     */
    modifier checkMinimumSpend() {
        if (msg.value < minimumSpendAmount) revert BelowMinimumSpend();
        _;
    }

    /**
     * @dev Public functions
     */

    /**
     * @notice Allows a buyer to purchase with a list of NFTs
     * @dev This function calculates the total amount of Ether sent and ensures it does not exceed the NFT Sale Cap.
     *      It checks each NFT provided, verifies ownership, and calculates the amount included for each NFT.
     *      It reverts if the NFT is not owned by the sender or their delegate, if the NFT Sale Cap is reached,
     *      or if the payment amount is not valid.
     * @param tokenIds_ An array of token IDs which the buyer uses to make the purchase.
     */
    function buyWithNFTs(
        uint256[] calldata tokenIds_
    ) external payable whenNotPaused checkMinimumSpend {
        // check if the nft sale is closed
        if (block.timestamp < nftStartDate || block.timestamp > endDate) {
            revert Closed();
        }

        // calculate new nft sold supply
        uint256 _newNftSoldSupply = nftSoldSupply + msg.value;

        // verify nft sold supply is not greater than the nft sale cap
        if (_newNftSoldSupply > nftSaleCap) {
            revert AmountExceedsSupply();
        }

        // update nft sold supply
        nftSoldSupply = _newNftSoldSupply;

        // track amount included in NFT
        uint256 _amountIncluded = 0;

        // check each provided NFTs
        uint256 _i;
        do {
            uint256 _tokenId = tokenIds_[_i];

            // verify tokenId is owned by sender
            _verifyTokenOwner(_tokenId);

            // grab current NFT purchase amount
            uint256 _nftPurchaseAmount = nftPurchases[_tokenId];

            // calculate how much amount can be used for this NFT
            uint256 _maxAmount = Math.min(
                capPerNFT - _nftPurchaseAmount, // maximum the cap per NFT minus the amount previously purchase with this NFT
                msg.value - _amountIncluded // otherwise the difference between the total amount and the amount already included in other NFT
            );

            // update amount used for this NFT
            nftPurchases[_tokenId] = _nftPurchaseAmount + _maxAmount;

            // increase amount included
            _amountIncluded += _maxAmount;
        } while (++_i < tokenIds_.length && _amountIncluded < msg.value);

        // check amount is fully included across the NFTs
        if (_amountIncluded != msg.value) {
            revert InvalidPaymentAmount();
        }

        // transfer ETH to receiver wallet
        receiverWallet.transfer(_amountIncluded);

        // emit event
        emit PurchaseWithNFT(msg.sender, _amountIncluded);
    }

    /**
     * @notice Allows a buyer to purchase using a referral code.
     * @dev This function allows users to buy with a referral code and ensures purchases per wallet do not exceed the referralCapPerBuyer
     *      It validates the referral code and calculates the total sold per wallet.
     *      It transfers the ETH to the receiver wallet.
     * @param referralCode_ An array of bytes32 representing the referral code used for the purchase.
     */
    function buyWithReferralCode(
        bytes32[] calldata referralCode_
    ) external payable whenNotPaused checkMinimumSpend {
        // check if the referral sale is closed
        if (block.timestamp < referralStartDate || block.timestamp > endDate) {
            revert Closed();
        }

        // verify referral code is valid
        if (!verifyReferralCode(msg.sender, referralCode_)) {
            revert InvalidReferralCode();
        }

        // calculate new referral purchase for this sender
        uint256 _newReferralPurchase = referralPurchases[msg.sender] +
            msg.value;

        // verify amount is not greater than the referral cap per buyer
        if (_newReferralPurchase > referralCapPerBuyer) {
            revert InvalidPaymentAmount();
        }

        // update referral amount bought by sender
        referralPurchases[msg.sender] = _newReferralPurchase;

        // transfer ETH to receiver wallet
        receiverWallet.transfer(msg.value);

        // emit event
        emit PurchaseWithReferralCode(msg.sender, msg.value);
    }

    /**
     * @notice Verifies if a given referral code is valid for a specific wallet address.
     * @dev Uses a Merkle proof to verify if the provided referral code is part of the Merkle tree
     *      represented by the referralCodeMerkleRoot. This is used to validate the authenticity of the referral codes.
     * @param wallet_ The address of the wallet for which the referral code is being verified.
     * @param referralCode_ Merkle Proof to check against.
     * @return bool True if the referral code is valid for the given wallet address, false otherwise.
     */
    function verifyReferralCode(
        address wallet_,
        bytes32[] calldata referralCode_
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                referralCode_,
                referralCodeMerkleRoot,
                keccak256(bytes.concat(keccak256(abi.encode(wallet_))))
            );
    }

    /**
     * @dev Only owner functions
     */

    /**
     * @notice Pause the purchase functions, only owner can call this function
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the purchase functions, only owner can call this function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Internal functions
     */

    /**
     * @notice Verifies if the sender is the owner of a given token or a valid delegate.
     * @dev This internal function checks if the sender is either the owner of the specified token or an authorized delegate.
     *      It supports two versions of delegate checks: a newer version (`dcV2`) and an older one (`dc`).
     *      The function reverts with `NotTokenOwner` if the sender is neither the owner nor a valid delegate.
     * @param tokenId_ The token ID to verify ownership or delegation for.
     */
    function _verifyTokenOwner(uint256 tokenId_) internal view {
        address _tokenOwner = grapeNFT.ownerOf(tokenId_);

        // check sender is owner
        if (_tokenOwner == msg.sender) return;

        // check with delegate registry v2
        if (
            delegateRegistryV2.checkDelegateForERC721(
                msg.sender,
                _tokenOwner,
                address(grapeNFT),
                tokenId_,
                ''
            )
        ) return;

        // check with delegate registry v1
        if (
            delegateRegistryV1.checkDelegateForToken(
                msg.sender,
                _tokenOwner,
                address(grapeNFT),
                tokenId_
            )
        ) return;

        // revert if not owner or delegate
        revert NotTokenOwner(tokenId_);
    }
}
