// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Address.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./EIP712Upgradeable.sol";
import "./ECDSA.sol";
import "./NoncesUpgradeable.sol";

import "./IBlurPool.sol";
import "./IBlend.sol";
import "./Helpers.sol";
import "./Structs.sol";

import "./OwnableUpgradeable.sol";
import "./RangeProtocolBlurVaultStorage.sol";
import "./VaultErrors.sol";
import "./FullMath.sol";
import "./DataTypes.sol";

/**
 * @title RangeProtocolBlurVault
 * @dev The contract provides fungible interface for lending ETH on Blur protocol based on strategy run by Range.
 */
contract RangeProtocolBlurVault is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    PausableUpgradeable,
    EIP712Upgradeable,
    NoncesUpgradeable,
    IERC721Receiver,
    RangeProtocolBlurVaultStorage
{
    uint256 public constant MAX_MANAGER_FEE = 1000; // capped at 10%

    // Typehash for liquidation of seized NFT.
    bytes32 private constant LIQUIDATE_ORDER_TYPEHASH =
        keccak256(
            "LiquidateOrder(address collection,uint256 tokenId,uint256 amount,address recipient,uint256 nonce,uint256 deadline)"
        );

    // Receives ETH from BlurPool contract upon redeeming of BlurPool tokens.
    receive() external payable {
        require(msg.sender == address(state.blurPool));
    }

    /**
     * @notice Authorizes manager to upgrade the vault implementation.
     * @param newImplementation address of new implementation.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyManager {}

    /**
     * @dev initializes the contract upon proxy deployment.
     * @param data contains the data to initialize the vault's initial storage state.
     */
    function initialize(bytes memory data) external override initializer {
        (
            address _manager,
            address _blurPool,
            address _blend,
            string memory _name,
            string memory _symbol
        ) = abi.decode(data, (address, address, address, string, string));
        if (_manager == address(0x0)) {
            revert VaultErrors.ZeroManagerAddress();
        }
        if (_blurPool == address(0x0)) {
            revert VaultErrors.ZeroBlurPoolAddress();
        }
        if (_blend == address(0x0)) {
            revert VaultErrors.ZeroBlendAddress();
        }

        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __Pausable_init();
        __EIP712_init("https://app.rangeprotocol.com", "1");
        __Nonces_init();
        _transferOwnership(_manager);

        state.blurPool = IBlurPool(_blurPool);
        state.blend = IBlend(_blend);

        _setManagerFee(0); // TODO check the default fee to set
    }

    /**
     * @dev mints vault shares to the user.
     * @param amount the amount of ETH to deposit to the vault.
     * @return shares amount of vault shares minted to the depositor.
     */
    function mint(
        uint256 amount
    ) external payable override nonReentrant returns (uint256 shares) {
        if (amount == 0 || amount > msg.value) {
            revert VaultErrors.InvalidETHAmount(amount);
        }

        shares = totalSupply() != 0
            ? FullMath.mulDivRoundingUp(
                amount,
                totalSupply(),
                getUnderlyingBalance()
            )
            : amount;

        _mint(msg.sender, shares);
        state.blurPool.deposit{value: amount}();

        if (amount > msg.value) {
            Address.sendValue(payable(msg.sender), amount - msg.value);
        }

        emit Minted(msg.sender, shares, amount);
    }

    /**
     * @dev burns vault shares and redeems underlying asset for the user.
     * @param shares amount of shares to burn from the user
     * @param withdrawAmount amount of underlying assets withdrawn by the user.
     */
    function burn(
        uint256 shares
    ) external override nonReentrant returns (uint256 withdrawAmount) {
        if (shares == 0) {
            revert VaultErrors.ZeroBurnAmount();
        }
        if (balanceOf(msg.sender) < shares) {
            revert VaultErrors.InsufficientUserBalance();
        }

        withdrawAmount = (getUnderlyingBalance() * shares) / totalSupply();
        IBlurPool _blurPool = state.blurPool;
        if (_blurPool.balanceOf(address(this)) < withdrawAmount) {
            revert VaultErrors.InsufficientVaultBalance();
        }
        _burn(msg.sender, shares);

        state.blurPool.withdraw(withdrawAmount);
        withdrawAmount -= (withdrawAmount * state.managerFee) / 10_000; // apply manager fee
        Address.sendValue(payable(msg.sender), withdrawAmount);

        emit Burned(msg.sender, shares, withdrawAmount);
    }

    /**
     * @dev Refinances an auction on Blur protocol using BlurPool tokens held by the vault.
     * Can only be called by the manager.
     * @param lien the lien to refinance.
     * @param lienId the id of the lien to be refinanced.
     * @param rate the new rate to refinance the lien at.
     */
    function refinanceAuction(
        Lien calldata lien,
        uint256 lienId,
        uint256 rate
    ) external override onlyManager {
        IBlurPool _blurPool = state.blurPool;
        uint256 debt = getCurrentDebtByLien(lien, lienId);
        if (debt > _blurPool.balanceOf(address(this))) {
            revert VaultErrors.InsufficientVaultBalance();
        }

        DataTypes.LienData memory newLienData = DataTypes.LienData({
            lienId: lienId,
            lien: Lien({
                lender: address(this),
                borrower: lien.borrower,
                collection: lien.collection,
                tokenId: lien.tokenId,
                amount: debt,
                startTime: block.timestamp,
                rate: rate,
                auctionStartBlock: 0,
                auctionDuration: lien.auctionDuration
            })
        });
        state.liens.push(newLienData);
        state.lienIdToIndex[lienId] = state.liens.length;
        uint256 blurPoolBalanceBefore = _blurPool.balanceOf(address(this));
        state.blend.refinanceAuction(lien, lienId, rate);
        if (_blurPool.balanceOf(address(this)) + debt < blurPoolBalanceBefore) {
            revert VaultErrors.ImbalancedVaultAsset();
        }

        if (state.blend.liens(lienId) != _hashLien(newLienData.lien)) {
            revert VaultErrors.RefinanceFailed();
        }
        emit Loaned(lienId, debt);
    }

    /**
     * @dev Starts auction for a lien. Can only be called by the manager.
     * @param lien lien to start the auction for.
     * @param lienId the lien id of the lien to be auctioned off.
     */
    function startAuction(
        Lien calldata lien,
        uint256 lienId
    ) external override onlyManager {
        uint256 lienArrayIdx = state.lienIdToIndex[lienId] - 1;
        if (
            _hashLien(state.liens[lienArrayIdx].lien) != _hashLien(lien) ||
            !_isLienValid(lien, lienId)
        ) {
            revert VaultErrors.InvalidLien(lien, lienId);
        }

        state.liens[lienArrayIdx].lien.auctionStartBlock = block.number;
        state.blend.startAuction(lien, lienId);
        emit AuctionStarted(address(lien.collection), lien.tokenId, lienId);
    }

    /**
     * @dev Seizes the NFT which has an auction expired against it. Can only be called by the manager.
     * @param lienPointers the list of liens from which the NFTs are to be seized.
     */
    function seize(
        LienPointer[] calldata lienPointers
    ) external override onlyManager {
        state.blend.seize(lienPointers);
        for (uint256 i = 0; i < lienPointers.length; i++) {
            emit NFTSeized(
                address(lienPointers[i].lien.collection),
                lienPointers[i].lien.tokenId,
                lienPointers[i].lienId
            );
        }
    }

    /**
     * @dev Cleans up the liens from liens array which are not active anymore.
     * Anyone can call it.
     */
    function cleanUpLiensArray() external override {
        IBlend _blend = state.blend;
        uint256 length = state.liens.length;
        for (uint256 i = 0; i < length; ) {
            DataTypes.LienData memory lienData = state.liens[i];
            if (_blend.liens(lienData.lienId) != _hashLien(lienData.lien)) {
                state.liens[i] = state.liens[length - 1];
                state.liens.pop();

                if (i != length - 1) {
                    state.lienIdToIndex[state.liens[i].lienId] = i + 1;
                }
                length--;
                continue;
            }
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev liquidates NFT and sells it off to the buyer through verifying an off-chain manager signed signature.
     * The buyer must pay the ETH amount specified as amount in the liquidate order data.
     * @param collection the collection address of the NFT.
     * @param tokenId the id of the NFT.
     * @param amount amount of ETH to be paid by the user.
     * @param recipient recipient of the NFT.
     * @param deadline the timestamp by which the signature is valid.
     * @param signature the manager signed signature.
     */
    function liquidateNFT(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata signature
    ) external payable override {
        if (amount == 0 || amount > msg.value) {
            revert VaultErrors.InvalidETHAmount(amount);
        }
        if (recipient == address(0x0)) {
            revert VaultErrors.InvalidRecipient(recipient);
        }
        if (block.timestamp > deadline) {
            revert VaultErrors.OutdatedOrder(deadline);
        }

        bytes32 hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    LIQUIDATE_ORDER_TYPEHASH,
                    collection,
                    tokenId,
                    amount,
                    recipient,
                    _useNonce(msg.sender),
                    deadline
                )
            )
        );

        if (ECDSA.recover(hash, signature) != manager()) {
            revert VaultErrors.InvalidSignature(signature);
        }
        state.blurPool.deposit{value: amount}();
        IERC721(collection).transferFrom(address(this), recipient, tokenId);

        if (amount > msg.value) {
            Address.sendValue(payable(msg.sender), amount - msg.value);
        }

        emit NFTLiquidated(collection, tokenId, amount, recipient);
    }

    /**
     * @dev Allows manager to collect their fees.
     * Can only be called by the manager.
     */
    function collectManagerFee() external onlyManager {
        Address.sendValue(payable(manager()), address(this).balance);
    }

    /**
     * @dev Allows manager to set their fee. Max manager fee is capped at 10%.
     * Can only be called by the manager.
     * @param managerFee managerFee percentage to set.
     */
    function setManagerFee(uint256 managerFee) external onlyManager {
        _setManagerFee(managerFee);
    }

    /**
     * @dev Callback called by the ERC721 collection when transferring token to the contract recipient
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev returns underlying balance of the vault. The underlying balance is the sum
     * of passive balance in the vault + all debt owned by the vault.
     */
    function getUnderlyingBalance() public view override returns (uint256) {
        return
            state.blurPool.balanceOf(address(this)) + getCurrentlyOwnedDebt();
    }

    /**
     * @dev returns currently owned debt by the vault.
     */
    function getCurrentlyOwnedDebt()
        public
        view
        override
        returns (uint256 ownedDebt)
    {
        IBlend _blend = state.blend;
        uint256 length = state.liens.length;
        for (uint256 i = 0; i < length; i++) {
            DataTypes.LienData memory lienData = state.liens[i];
            if (_blend.liens(lienData.lienId) == _hashLien(lienData.lien)) {
                ownedDebt += Helpers.computeCurrentDebt(
                    lienData.lien.amount,
                    lienData.lien.rate,
                    lienData.lien.startTime
                );
            }
        }
    }

    /**
     * @dev returns the current debt owed by a lien borrower.
     * @param lien The lien to get current debt for.
     * @param lienId The id of the lien for which the debt is calculated.
     * @return currentDebt The debt amount owed by the lien borrower.
     */
    function getCurrentDebtByLien(
        Lien calldata lien,
        uint256 lienId
    ) public view override returns (uint256 currentDebt) {
        if (!_isLienValid(lien, lienId)) {
            revert VaultErrors.InvalidLien(lien, lienId);
        }
        currentDebt = Helpers.computeCurrentDebt(
            lien.amount,
            lien.rate,
            lien.startTime
        );
    }

    /**
     * @dev Returns the current auction rate limit for a lien having a live auction.
     * @param lien The lien to calculate the current auction rate limit.
     * @param lienId The lien id to calculate the current auction rate limit.
     * @return rateLimit The current auction rate limit for a given lien.
     */
    function getRefinancingAuctionRate(
        Lien calldata lien,
        uint256 lienId
    ) public view override returns (uint256 rateLimit) {
        if (!_isLienValid(lien, lienId)) {
            revert VaultErrors.InvalidLien(lien, lienId);
        }
        rateLimit = Helpers.calcRefinancingAuctionRate(
            lien.auctionStartBlock,
            lien.auctionDuration,
            lien.rate
        );
    }

    /**
     * @dev Verifies that the lien is valid on the Blur contract.
     * @param lien The lien to check the validity for.
     * @param lienId The id of the lien to check validity for.
     * @return bool True if lien is active, false otherwise.
     */
    function _isLienValid(
        Lien calldata lien,
        uint256 lienId
    ) private view returns (bool) {
        return state.blend.liens(lienId) == _hashLien(lien);
    }

    /**
     * @dev hashes the lien struct passed to it and returns it.
     */
    function _hashLien(Lien memory lien) private pure returns (bytes32) {
        return keccak256(abi.encode(lien));
    }

    /**
     * @dev Sets manager fee percentage a new value.
     * Reverts if newManagerFee exceeds the MAX_MANAGER_FEE
     * @param _managerFee The manager fee percentage to set.
     */
    function _setManagerFee(uint256 _managerFee) private {
        if (_managerFee > MAX_MANAGER_FEE) {
            revert VaultErrors.InvalidManagerFee(_managerFee);
        }

        state.managerFee = _managerFee;
        emit ManagerFeeSet(_managerFee);
    }
}
