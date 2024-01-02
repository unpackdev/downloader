// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./BeaconProxy.sol";
import "./XNFTBase.sol";
import "./IXNFTClone.sol";
import "./IXNFTLiquidityPool.sol";
import "./StringsUtils.sol";

/// @title XNFT Admin Contract
/// @author Wilson A.
/// @notice Used for setting up accounts and managing fees
abstract contract XNFTAdmin is XNFTBase {
    modifier onlyOperatorOrOwner() {
        require(
            msg.sender == _operator || msg.sender == owner(),
            "only operator or owner"
        );
        _;
    }

    function setMarketplaceFeeAddress(
        address _marketplaceFeeAddress
    ) external onlyOwner {
        require(_marketplaceFeeAddress != address(0), "invalid address");
        require(
            _marketplaceFeeAddress != marketplaceFeeAddress,
            "address already set"
        );
        marketplaceFeeAddress = _marketplaceFeeAddress;
        emit MarketplaceFeeAddressUpdated(_marketplaceFeeAddress);
    }

    function setMarketplaceFeeBps(
        uint32 _marketplaceFeeBps
    ) external onlyOwner {
        require(_marketplaceFeeBps <= MAX_FEE_BPS, "invalid fee bps");
        marketplaceFeeBps = _marketplaceFeeBps;
        emit MarketplaceFeeBpsUpdated(_marketplaceFeeBps);
    }

    function setMarketplaceSecondaryFeeBps(
        uint32 _marketplaceSecondaryFeeBps
    ) external onlyOwner {
        require(_marketplaceSecondaryFeeBps <= MAX_FEE_BPS, "invalid fee bps");
        marketplaceSecondaryFeeBps = _marketplaceSecondaryFeeBps;
        emit MarketplaceSecondaryFeeBpsUpdated(_marketplaceSecondaryFeeBps);
    }

    function setCreatorFeeBps(uint32 _creatorFeeBps) external onlyOwner {
        require(_creatorFeeBps <= MAX_FEE_BPS, "invalid fee bps");
        creatorFeeBps = _creatorFeeBps;
        emit CreatorFeeBpsUpdated(_creatorFeeBps);
    }

    function setRoyaltyFeeBps(uint32 _royaltyFeeBps) external onlyOwner {
        require(_royaltyFeeBps <= MAX_FEE_BPS, "invalid fee bps");
        royaltyFeeBps = _royaltyFeeBps;
        emit RoyaltyFeeBpsUpdated(_royaltyFeeBps);
    }

    function setMinMintPrice(uint256 _minMintPrice) external onlyOwner {
        minMintPrice = _minMintPrice;
        emit MinMintPriceUpdated(_minMintPrice);
    }

    function pauseWhitelist(bool _status) external onlyOwner {
        whitelistPaused = _status;
        emit WhitelistPaused(_status);
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "invalid address");
        _operator = newOperator;
        emit OperatorUpdated(newOperator);
    }

    function setMarketplaceHash(bytes4 _marketplaceHash) external onlyOwner {
        marketplaceHash = _marketplaceHash;
        emit MarketplaceHashUpdated(_marketplaceHash);
    }

    function setPause(bool _status) external onlyOwner {
        _status ? _pause() : _unpause();
    }

    // --- Operator Functions --- //
    function setUpAccount(
        string memory accountName,
        uint256 _mintTimestamp,
        uint256 _revealTimestamp,
        uint32 _maxMintCount,
        uint32 _maxMintPerWallet,
        uint256 _mintPrice,
        address payable _accountFeeAddress,
        bytes32 _accountNameHash,
        bytes32 _accountIdHash
    ) public whenNotPaused onlyOperatorOrOwner nonReentrant {
        require(_accountFeeAddress != address(0), "invalid address");
        require(_mintPrice >= minMintPrice, "mint price is too low");
        require(!accountIdsHash[_accountIdHash], "account id already exists");
        require(
            accountNames[_accountNameHash] == 0,
            "account name already exists"
        );
        require(
            keccak256(bytes(StringsUtils._toLower(accountName))) ==
                _accountNameHash,
            "accountNameHash does not match accountName"
        );
        string memory name = string(abi.encodePacked("@", accountName));
        accountIdsHash[_accountIdHash] = true;
        accountNames[_accountNameHash] = accountId;
        accounts[accountId] = AccountInfo(
            _mintTimestamp,
            _revealTimestamp,
            _maxMintCount,
            _maxMintPerWallet,
            _mintPrice,
            _accountFeeAddress,
            _accountNameHash
        );
        address instance = createNFT(name);
        ++accountId;
        IXNFTClone(instance).transferOwnership(_accountFeeAddress);
        emit AccountCreated(
            name,
            instance,
            _mintTimestamp,
            _revealTimestamp,
            _maxMintCount,
            _maxMintPerWallet,
            _mintPrice
        );
    }

    function createNFT(string memory name) internal returns (address) {
        BeaconProxy proxy = new BeaconProxy(
            _xnftBeacon,
            abi.encodeCall(IXNFTClone.initialize, (name, name, accountId))
        );
        address instance = address(proxy);
        xnftContracts[instance] = true;
        createLP(instance);
        return instance;
    }

    function createLP(address instance) internal {
        BeaconProxy proxyLP = new BeaconProxy(
            _xnftLPBeacon,
            abi.encodeCall(IXNFTLiquidityPool.initialize, (instance, accountId))
        );
        accountAddresses[accountId] = AccountAddressInfo(
            instance,
            address(proxyLP)
        );
    }

    function updateAccount(
        uint256 _accountId,
        uint256 _mintTimestamp,
        uint256 _revealTimestamp,
        uint32 _maxMintCount,
        uint32 _maxMintPerWallet,
        uint256 _mintPrice,
        address payable _accountFeeAddress,
        bytes32 _accountNameHash
    ) public whenNotPaused onlyOperatorOrOwner {
        require(_accountFeeAddress != address(0), "invalid address");
        require(_mintPrice >= minMintPrice, "mint price is too low");
        require(
            accountNames[_accountNameHash] == _accountId,
            "accountId does not match accountNameHash"
        );
        if (msg.sender == _operator)
            require(
                accounts[_accountId].accountFeeAddress == _accountFeeAddress,
                "operator cannot change accountFeeAddress"
            );
        if (accounts[_accountId].mintTimestamp <= block.timestamp)
            require(
                _mintPrice >= accounts[_accountId].mintPrice,
                "mint price cannot be reduced after mint starts"
            );
        accounts[_accountId] = AccountInfo(
            _mintTimestamp,
            _revealTimestamp,
            _maxMintCount,
            _maxMintPerWallet,
            _mintPrice,
            _accountFeeAddress,
            _accountNameHash
        );
    }

    function setWhitelist(
        address _whitelist,
        bool _status
    ) external onlyOperatorOrOwner {
        whitelists[_whitelist] = _status;
        emit WhitelistUpdated(_whitelist, _status);
    }

    function setLocklist(
        bytes32 _accountNameHash,
        uint256 _tokenId,
        bool _status
    ) external onlyOperatorOrOwner {
        uint256 refAccountId = accountNames[_accountNameHash];
        require(refAccountId > 0, "account does not exist");
        locklists[refAccountId][_tokenId] = _status;
        emit LocklistUpdated(_accountNameHash, _tokenId, _status);
    }
}
