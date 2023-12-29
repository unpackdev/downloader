// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./Ownable.sol";
import "./PausableInternal.sol";
import "./KeepersERC721Storage.sol";
import "./ERC721MetadataStorage.sol";
import "./AccessControlInternal.sol";
import "./ERC2981Storage.sol";
import "./MintOperatorModifiers.sol";
import "./ConstantsLib.sol";
import "./DiamondWritableRevokableStorage.sol";
import "./Counters.sol";

contract KeepersAdminFacet is OwnableInternal, AccessControlInternal, MintOperatorModifiers {
    /**
     * @notice Thrown if the receiver is a zero address
     */
    error ZeroAddressReceiver();
    error UpgradeabilityAlreadyRevoked();

    event UpgradeabilityRevoked();
    event SaleStartTimestampSet(uint32 indexed timestamp);
    event SaleCompleteTimestampSet(uint32 indexed timestamp);
    event MaxPerAddressSet(uint16 indexed count);
    event Withdraw(address indexed recipient, uint256 indexed amount);
    event BaseURISet(string indexed baseURI);
    event RoyaltyReceiverSet(address indexed receiver);

    /**
     * @notice Thrown if sale start is after the sale complete time
     */
    error SaleStartTimeMustBeBeforeEndTime();

    /**
     * @notice Thrown if sale complete is before the sale start time
     */
    error SaleEndTimeMustBeAfterStartTime();

    error WithdrawSendFailed();

    function setSaleStartTimestamp(uint32 timestamp) external onlyOwner {
        if (
            KeepersERC721Storage.layout().saleCompleteTimestamp != 0 &&
            timestamp >= KeepersERC721Storage.layout().saleCompleteTimestamp
        ) {
            revert SaleStartTimeMustBeBeforeEndTime();
        }
        KeepersERC721Storage.layout().saleStartTimestamp = timestamp;

        emit SaleStartTimestampSet(timestamp);
    }

    function getSaleStartTimestamp() external view returns (uint256) {
        return KeepersERC721Storage.layout().saleStartTimestamp;
    }

    function getSaleCompleteTimestamp() external view returns (uint256) {
        return KeepersERC721Storage.layout().saleCompleteTimestamp;
    }

    function setSaleCompleteTimestamp(uint32 timestamp) external onlyOwner {
        if (timestamp <= KeepersERC721Storage.layout().saleStartTimestamp) {
            revert SaleEndTimeMustBeAfterStartTime();
        }
        KeepersERC721Storage.layout().saleCompleteTimestamp = timestamp;

        emit SaleCompleteTimestampSet(timestamp);
    }

    function setMaxPerAddress(uint16 count) external onlyOwner {
        KeepersERC721Storage.layout().maxPerAddress = count;

        emit MaxPerAddressSet(count);
    }

    function withdraw() external onlyOwnerOrMintOperator {
        address recipient = KeepersERC721Storage.layout().withdrawAddress;
        if (recipient == address(0)) {
            revert ZeroAddressReceiver();
        }
        uint256 balance = address(this).balance;

        (bool success, ) = recipient.call{ value: balance }("");
        if (!success) {
            revert WithdrawSendFailed();
        }

        emit Withdraw(recipient, balance);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        ERC721MetadataStorage.layout().baseURI = baseURI_;

        emit BaseURISet(baseURI_);
    }

    function revokeUpgradeability() external onlyOwner {
        DiamondWritableRevokableStorage.Layout storage l = DiamondWritableRevokableStorage.layout();
        if (l.isUpgradeabiltyRevoked) revert UpgradeabilityAlreadyRevoked();

        DiamondWritableRevokableStorage.layout().isUpgradeabiltyRevoked = true;

        emit UpgradeabilityRevoked();
    }

    function setRoyaltyReceiver(address receiver) external onlyOwner {
        ERC2981Storage.layout().defaultRoyaltyReceiver = receiver;

        emit RoyaltyReceiverSet(receiver);
    }

    function setMaxMintsForSalesTier(uint256 max) external onlyOwner {
        KeepersERC721Storage.layout().maxMintsForSalesTier = max;
    }

    function getMaxMintsForSalesTier() external view returns (uint256) {
        return KeepersERC721Storage.layout().maxMintsForSalesTier;
    }

    function setWithdrawAddress(address withdrawAddress) external onlyOwner {
        ERC2981Storage.layout().defaultRoyaltyReceiver = withdrawAddress;
        KeepersERC721Storage.layout().withdrawAddress = withdrawAddress;
    }

    function getWithdrawAddress() external view returns (address) {
        return KeepersERC721Storage.layout().withdrawAddress;
    }

    function setVaultAddress(address vaultAddress) external onlyOwner {
        KeepersERC721Storage.layout().vaultAddress = vaultAddress;
    }

    function getVaultAddress() external view returns (address) {
        return KeepersERC721Storage.layout().vaultAddress;
    }

    function grantMintOperator(address mintOperator) external onlyOwner {
        _grantRole(ConstantsLib.KEEPERS_MINT_OPERATOR, mintOperator);
    }

    function revokeMintOperator(address mintOperator) external onlyOwner {
        _revokeRole(ConstantsLib.KEEPERS_MINT_OPERATOR, mintOperator);
    }

    function isMintOperator(address maybeOperator) external view returns (bool) {
        return _hasRole(ConstantsLib.KEEPERS_MINT_OPERATOR, maybeOperator);
    }

    function currentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}
