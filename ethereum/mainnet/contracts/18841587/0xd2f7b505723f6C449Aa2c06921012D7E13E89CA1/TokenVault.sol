// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./ITokenVault.sol";
import "./IFNFT.sol";
import "./LockAccessControl.sol";

error INVALID_PARAM();
error INVALID_ADDRESS();
error INVALID_AMOUNT();
error INVALID_WALLET();
error INVALID_BALANCE();
error INVALID_RECIPIENT();
error UNAUTHORIZED_RECIPIENT();
error BLACKLISTED_RECIPIENT();
error DUPLICATED_NFT();

contract TokenVault is
    ITokenVault,
    LockAccessControl,
    Pausable
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice rnft configuration
    mapping(uint256 => RedeemNFTConfig) public rnfts;

    // @notice address wallets => received tokens
    mapping(address => uint256) public recipientTokens;

    // @notice list of wallets qualified to receive tokens
    EnumerableSet.AddressSet private eligibleWallets;

    /// @notice A list of blacklisted wallets
    EnumerableSet.AddressSet private blacklistedWallets;

    /* ======= CONSTRUCTOR ======= */

   constructor(address provider) LockAccessControl(provider) {}

    ///////////////////////////////////////////////////////
    //               MANAGER CALLED FUNCTIONS            //
    ///////////////////////////////////////////////////////

    function pause() external onlyOwner whenNotPaused {
        return _pause();
    }

    function unpause() external onlyOwner whenPaused {
        return _unpause();
    }

    ///////////////////////////////////////////////////////
    //               USER CALLED FUNCTIONS               //
    ///////////////////////////////////////////////////////

    /**
     * @notice Mint a new rnft to acknowledge receipt of user's tokens
     * @param recipient The address to receive the rnft
     * @param rnftConfig The rnft configuration
     * @return The rnft ID
     */
    function mint(address recipient, RedeemNFTConfig memory rnftConfig)
        external
        whenNotPaused
        onlyModerator
        returns (uint256)
    {
        IRedemptionNFT rnft = getRNFT();

        if (recipient == address(0)) revert INVALID_ADDRESS();
        if (!eligibleWallets.contains(recipient)) revert UNAUTHORIZED_RECIPIENT();
        if (blacklistedWallets.contains(recipient)) revert BLACKLISTED_RECIPIENT();
        if (rnftConfig.redeemableAmount == 0 ||
            (rnftConfig.eligibleTORAmount == 0 && 
            rnftConfig.eligibleHECAmount == 0)) revert INVALID_AMOUNT();
        if (rnft.balanceOf(recipient) > 0) revert DUPLICATED_NFT();

        uint256 rnftId = rnft.mint(recipient);
        rnfts[rnftId] = rnftConfig;

        emit RedeemNFTMinted(
            recipient,
            rnftId,
            rnftConfig.eligibleTORAmount,
            rnftConfig.eligibleHECAmount, 
            rnftConfig.redeemableAmount
        );

        return rnftId;
    }
  
    /**
     * @notice Withdraw a rnft and redeem the user's tokens
     * @param recipient The address to receive the rnft
     * @param rnftId The rnft ID
     */
    function withdraw(address recipient, uint256 rnftId)
        external
        whenNotPaused
        onlyModerator
    {
        IRedemptionNFT rnft = getRNFT();

        if (rnft.ownerOf(rnftId) != recipient || rnft.balanceOf(recipient) == 0) revert INVALID_RECIPIENT();
        if (!eligibleWallets.contains(recipient)) revert UNAUTHORIZED_RECIPIENT();
        if (blacklistedWallets.contains(recipient)) revert BLACKLISTED_RECIPIENT();
        if (rnft.balanceOf(recipient) > 1) revert DUPLICATED_NFT();

        RedeemNFTConfig memory rnftConfig = rnfts[rnftId];

        getTreasury().transferRedemption(
            rnftId,
            rnftConfig.redeemableToken,
            recipient,
            rnftConfig.redeemableAmount
        );

        rnft.burnFromOwner(rnftId, recipient); 

        delete rnfts[rnftId];

        emit RedeemNFTWithdrawn(recipient, rnftId, rnftConfig.redeemableAmount);
    }

    /**
     * @notice Mint & Withdraw from one recipient
     * @param recipient The address to receive the rnft
     */
    function mintWithdraw(address recipient)  external
        whenNotPaused
        returns (uint256) {

        uint256 redeemAmount = recipientTokens[recipient];
        uint256 rnftId = _mintWithdraw(recipient, redeemAmount);
        return rnftId;
    }

    /**
     * @notice Mint & Withdraw from a list of recipients
     * @param recipients The address to receive the rnft
     * @param amounts amount to be redeemed
     */
    function mintWithdraws(address[] memory recipients, uint256[] memory amounts)  external
        whenNotPaused
        onlyModerator
    {
        uint256 totalRecipients = recipients.length;
        uint256 totalConfig = amounts.length;

        if (totalRecipients != totalConfig) revert INVALID_PARAM();

        for (uint256 i = 0; i < totalRecipients; i++) {
            address recipient = recipients[i];
            uint256 redeemAmount = amounts[i];
            _mintWithdraw(recipient, redeemAmount);
        }   
    }

    /**
        * @notice Mint & Withdraw from a recipient
        * @param recipient The address to receive the rnft
        * @param redeemAmount The amount to redeem
     */
    function _mintWithdraw(address recipient, uint256 redeemAmount)  internal
        returns (uint256) {

        if (recipient == address(0)) revert INVALID_ADDRESS();
        if (redeemAmount == 0) revert INVALID_AMOUNT();
        if (!eligibleWallets.contains(recipient)) revert UNAUTHORIZED_RECIPIENT();
        if (blacklistedWallets.contains(recipient)) revert BLACKLISTED_RECIPIENT();
        if (getRNFT().balanceOf(recipient) > 1) revert DUPLICATED_NFT();

        RedeemNFTConfig memory rnftConfig = RedeemNFTConfig({
            eligibleTORAmount: 1,
            eligibleHECAmount: 1,
            redeemableAmount: redeemAmount,
            redeemableToken: getRedeemToken()
        });

        uint256 rnftId = getRNFT().mint(recipient);
        rnfts[rnftId] = rnftConfig;

        emit RedeemNFTMinted(
            recipient,
            rnftId,
            rnftConfig.eligibleTORAmount,
            rnftConfig.eligibleHECAmount, 
            rnftConfig.redeemableAmount
        );

        IRedemptionNFT rnft = getRNFT();

        getTreasury().transferRedemption(
            rnftId,
            rnftConfig.redeemableToken,
            recipient,
            rnftConfig.redeemableAmount
        );

        rnft.burnFromOwner(rnftId, recipient); 

        delete rnfts[rnftId];

        return rnftId;
    }

     /**
        @notice add wallet to eligibleWallets
        @param wallet Wallet address
     */
    function addEligibleWallet(address wallet, uint256 _eligibleAmount) external onlyModerator {
        _addEligibleWallet(wallet, _eligibleAmount);
    }

    /**
        @notice add wallets to eligibleWallets
        @param wallets Wallet addresses
     */
    function addEligibleWallets(address[] memory wallets, uint256[] memory eligibleAmounts) external onlyModerator {
        uint256 length = wallets.length;
        uint256 lengthAmounts = eligibleAmounts.length;
        if (length != lengthAmounts) revert INVALID_PARAM();
        for (uint256 i = 0; i < length; i++) {
            address wallet = wallets[i];
            uint256 _eligibleAmount = eligibleAmounts[i];
            _addEligibleWallet(wallet, _eligibleAmount);
        }
    }

    function _addEligibleWallet(address wallet, uint256 _eligibleAmount) internal {
        if (wallet == address(0)) revert INVALID_ADDRESS();
        bool status;
        if (!eligibleWallets.contains(wallet)) {
            status = eligibleWallets.add(wallet);
            if (!status) revert INVALID_WALLET();
            recipientTokens[wallet] += _eligibleAmount;
        }
    }

    /**
        @notice remove wallet from eligibleWallets
        @param wallet Wallet address
     */
    function removeEligibleWallet(address wallet) external onlyModerator {
        _removeEligibleWallet(wallet);
    }

    /**
        @notice remove wallets from eligibleWallets
        @param wallets Wallet addresses
     */
    function removeEligibleWallets(address[] memory wallets) external onlyModerator {
        uint256 length = wallets.length;
        for (uint256 i = 0; i < length; i++) {
            address wallet = wallets[i];
            _removeEligibleWallet(wallet);
        }        
    }

    function _removeEligibleWallet(address wallet) internal {
        if (wallet == address(0)) revert INVALID_ADDRESS();
        bool status;
        if (eligibleWallets.contains(wallet)) {
            status = eligibleWallets.remove(wallet);
            if (!status) revert INVALID_WALLET();
        }
    }

    /**
        @notice add blacklist wallet 
        @param _wallet  wallet address
     */
    function _addBlacklistWallet(address _wallet) private {
        if (_wallet == address(0) || blacklistedWallets.contains(_wallet)) revert INVALID_WALLET();

        bool status = blacklistedWallets.add(_wallet);
        if (!status) revert INVALID_WALLET();
	}

     /**
        @notice add blacklist wallet 
        @param _wallet  wallet address
     */
    function _removeBlacklistWallet(address _wallet) private {
        //check for duplicate
        if (_wallet == address(0) || !blacklistedWallets.contains(_wallet)) revert INVALID_WALLET();

        bool status = blacklistedWallets.remove(_wallet);
        if (!status) revert INVALID_WALLET();
	}

    ///////////////////////////////////////////////////////
    //                  VIEW FUNCTIONS                   //
    ///////////////////////////////////////////////////////

     /// @notice Returns the length of eligible wallets
	function getEligibleWalletsCount() external view returns (uint256) {
		return eligibleWallets.length();
	}

    /// @notice Returns all eligible wallets
    function getAllEligibleWallets() external view returns (address[] memory) {
        return eligibleWallets.values();
    }

    /**
        @notice return if wallet is registered
        @param _walletAddress address
        @return bool
     */
	function isRegisteredWallet(address _walletAddress) external view returns (bool) {
		return eligibleWallets.contains(_walletAddress);
	}

    /// @notice Returns all wallet addresses from a range
    function getEligibleWalletsFromRange(uint16 fromIndex, uint16 toIndex) external view returns (address[] memory) {
        uint256 length = eligibleWallets.length();
        if (fromIndex >= toIndex || toIndex > length) revert INVALID_PARAM();

        address[] memory _wallets = new address[](toIndex - fromIndex);
        uint256 index = 0;

        for (uint256 i = fromIndex; i < toIndex; i++) {
            _wallets[index] = eligibleWallets.at(i);
            index++;
        }

        return _wallets;
    }

    /// @notice Returns wallet at index
    function getEligibleWalletAtIndex(uint16 index) external view returns (address) {
        return eligibleWallets.at(index);
    }

     /**
        @notice add blacklist wallet 
        @param _wallets  wallet address
     */
    function addBlacklistWallets(address[] memory _wallets) external onlyModerator {
        uint256 length = _wallets.length;

        for (uint256 i = 0; i < length; i++) {
            _addBlacklistWallet(_wallets[i]);
        }
	}

    /**
        @notice add blacklist wallet 
        @param _wallets  wallet address
     */
    function removeBlacklistWallet(address[] memory _wallets) external onlyModerator {
       uint256 length = _wallets.length;

        for (uint256 i = 0; i < length; i++) {
            _removeBlacklistWallet(_wallets[i]);
        }
	}

     /// @notice Returns all blacklisted wallets
    function getAllBlackListed() external view returns (address[] memory) {
        return blacklistedWallets.values();
    }

    /**
        @notice return if recipient is blaclisted
        @param recipient address
        @return bool
     */
	function isBlacklisted(address recipient) external view returns (bool) {
		return blacklistedWallets.contains(recipient);
	}

    /// @notice Returns the count of redeemed wallets
	function getBlacklistCount() external view returns (uint256) {
		return blacklistedWallets.length();
	}
}
