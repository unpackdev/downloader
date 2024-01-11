// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

// Inheritance
import "./IRentable.sol";
import "./IRentableAdminEvents.sol";
import "./IRentableHooks.sol";
import "./IORentableHooks.sol";
import "./IWRentableHooks.sol";
import "./BaseSecurityInitializable.sol";
import "./RentableStorageV1.sol";
import "./ReentrancyGuardUpgradeable.sol";

// Libraries
import "./SafeERC20Upgradeable.sol";
import "./Address.sol";

// References
import "./IERC721Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721ReadOnlyProxy.sol";
import "./IERC721ExistExtension.sol";
import "./ICollectionLibrary.sol";

import "./IWalletFactory.sol";
import "./SimpleWallet.sol";
import "./RentableTypes.sol";

/// @title Rentable main contract
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
/// @notice Main entry point to interact with Rentable protocol
contract Rentable is
    IRentable,
    IRentableAdminEvents,
    IORentableHooks,
    IWRentableHooks,
    BaseSecurityInitializable,
    ReentrancyGuardUpgradeable,
    RentableStorageV1
{
    /* ========== LIBRARIES ========== */

    using Address for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== MODIFIERS ========== */

    /// @dev Prevents calling a function from anyone except the owner
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    modifier onlyOTokenOwner(address tokenAddress, uint256 tokenId) {
        _getExistingORentableCheckOwnership(tokenAddress, tokenId, msg.sender);
        _;
    }

    /// @dev Prevents calling a function from anyone except respective OToken
    /// @param tokenAddress wrapped token address
    modifier onlyOToken(address tokenAddress) {
        require(
            msg.sender == _orentables[tokenAddress],
            "Only proper ORentables allowed"
        );
        _;
    }

    /// @dev Prevents calling a function from anyone except respective WToken
    /// @param tokenAddress wrapped token address
    modifier onlyWToken(address tokenAddress) {
        require(
            msg.sender == _wrentables[tokenAddress],
            "Only proper WRentables allowed"
        );
        _;
    }

    /// @dev Prevents calling a function from anyone except respective OToken or WToken
    /// @param tokenAddress wrapped token address
    modifier onlyOTokenOrWToken(address tokenAddress) {
        require(
            msg.sender == _orentables[tokenAddress] ||
                msg.sender == _wrentables[tokenAddress],
            "Only w/o tokens are authorized"
        );
        _;
    }

    /// @dev Prevents calling a library when not set for the respective wrapped token
    /// @param tokenAddress wrapped token address
    // slither-disable-next-line incorrect-modifier
    modifier skipIfLibraryNotSet(address tokenAddress) {
        if (_libraries[tokenAddress] != address(0)) {
            _;
        }
    }

    /* ========== CONSTRUCTOR ========== */

    /// @dev Instatiate Rentable
    /// @param governance address for governance role
    /// @param operator address for operator role
    constructor(address governance, address operator) {
        _initialize(governance, operator);
    }

    /* ---------- INITIALIZER ---------- */

    /// @dev Initialize Rentable (to be used with proxies)
    /// @param governance address for governance role
    /// @param operator address for operator role
    function initialize(address governance, address operator) external {
        _initialize(governance, operator);
    }

    /// @dev For internal usage in the initializer external method
    /// @param governance address for governance role
    /// @param operator address for operator role
    function _initialize(address governance, address operator)
        internal
        initializer
    {
        __BaseSecurityInitializable_init(governance, operator);
        __ReentrancyGuard_init();
    }

    /* ========== SETTERS ========== */

    /// @dev Associate the event hooks library to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @param libraryAddress library address
    function setLibrary(address tokenAddress, address libraryAddress)
        external
        onlyGovernance
    {
        address previousValue = _libraries[tokenAddress];

        _libraries[tokenAddress] = libraryAddress;

        emit LibraryChanged(tokenAddress, previousValue, libraryAddress);
    }

    /// @dev Associate the otoken to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @param oRentable otoken address
    function setORentable(address tokenAddress, address oRentable)
        external
        onlyGovernance
    {
        address previousValue = _orentables[tokenAddress];

        _orentables[tokenAddress] = oRentable;

        emit ORentableChanged(tokenAddress, previousValue, oRentable);
    }

    /// @dev Associate the otoken to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @param wRentable otoken address
    function setWRentable(address tokenAddress, address wRentable)
        external
        onlyGovernance
    {
        address previousValue = _wrentables[tokenAddress];

        _wrentables[tokenAddress] = wRentable;

        emit WRentableChanged(tokenAddress, previousValue, wRentable);
    }

    /// @dev Set wallet factory
    /// @param walletFactory wallet factory address
    function setWalletFactory(address walletFactory) external onlyGovernance {
        require(walletFactory != address(0), "Wallet Factory cannot be 0");

        address previousWalletFactory = walletFactory;

        _walletFactory = walletFactory;

        emit WalletFactoryChanged(previousWalletFactory, walletFactory);
    }

    /// @dev Set fee (percentage)
    /// @param newFee fee in 1e4 units (e.g. 100% = 10000)
    function setFee(uint16 newFee) external onlyGovernance {
        require(newFee <= BASE_FEE, "Fee greater than max value");

        uint16 previousFee = _fee;

        _fee = newFee;

        emit FeeChanged(previousFee, newFee);
    }

    /// @dev Set fee collector address
    /// @param newFeeCollector fee collector address
    function setFeeCollector(address payable newFeeCollector)
        external
        onlyGovernance
    {
        require(newFeeCollector != address(0), "FeeCollector cannot be null");

        address previousFeeCollector = _feeCollector;

        _feeCollector = newFeeCollector;

        emit FeeCollectorChanged(previousFeeCollector, newFeeCollector);
    }

    /// @dev Enable payment token (ERC20)
    /// @param paymentToken payment token address
    function enablePaymentToken(address paymentToken) external onlyGovernance {
        uint8 previousStatus = _paymentTokenAllowlist[paymentToken];

        _paymentTokenAllowlist[paymentToken] = ERC20_TOKEN;

        emit PaymentTokenAllowListChanged(
            paymentToken,
            previousStatus,
            ERC20_TOKEN
        );
    }

    /// @dev Enable payment token (ERC1155)
    /// @param paymentToken payment token address
    function enable1155PaymentToken(address paymentToken)
        external
        onlyGovernance
    {
        uint8 previousStatus = _paymentTokenAllowlist[paymentToken];

        _paymentTokenAllowlist[paymentToken] = ERC1155_TOKEN;

        emit PaymentTokenAllowListChanged(
            paymentToken,
            previousStatus,
            ERC1155_TOKEN
        );
    }

    /// @dev Disable payment token (ERC1155)
    /// @param paymentToken payment token address
    function disablePaymentToken(address paymentToken) external onlyGovernance {
        uint8 previousStatus = _paymentTokenAllowlist[paymentToken];

        _paymentTokenAllowlist[paymentToken] = NOT_ALLOWED_TOKEN;

        emit PaymentTokenAllowListChanged(
            paymentToken,
            previousStatus,
            NOT_ALLOWED_TOKEN
        );
    }

    /// @dev Toggle o/w token to call on-behalf a selector on the wrapped token
    /// @param caller o/w token address
    /// @param selector selector bytes on the target wrapped token
    /// @param enabled true to enable, false to disable
    function enableProxyCall(
        address caller,
        bytes4 selector,
        bool enabled
    ) external onlyGovernance {
        bool previousStatus = _proxyAllowList[caller][selector];

        _proxyAllowList[caller][selector] = enabled;

        emit ProxyCallAllowListChanged(
            caller,
            selector,
            previousStatus,
            enabled
        );
    }

    /* ========== VIEWS ========== */

    /* ---------- Internal ---------- */

    /// @dev Get and check (reverting) otoken exist for a specific token
    /// @param tokenAddress wrapped token address
    /// @return oRentable otoken instance
    function _getExistingORentable(address tokenAddress)
        internal
        view
        returns (address oRentable)
    {
        oRentable = _orentables[tokenAddress];
        require(oRentable != address(0), "Token currently not supported");
    }

    /// @dev Get and check (reverting) otoken user ownership
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user user to verify ownership
    /// @return oRentable otoken instance
    function _getExistingORentableCheckOwnership(
        address tokenAddress,
        uint256 tokenId,
        address user
    ) internal view returns (address oRentable) {
        oRentable = _getExistingORentable(tokenAddress);

        require(
            IERC721Upgradeable(oRentable).ownerOf(tokenId) == user,
            "The token must be yours"
        );
    }

    /// @dev Show rental validity
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @return true if is expired, false otw
    function _isExpired(address tokenAddress, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        // slither-disable-next-line timestamp
        return block.timestamp >= (_expiresAt[tokenAddress][tokenId]);
    }

    /* ---------- Public ---------- */

    /// @notice Get library address for the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @return library address
    function getLibrary(address tokenAddress) external view returns (address) {
        return _libraries[tokenAddress];
    }

    /// @notice Get OToken address associated to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @return OToken address
    function getORentable(address tokenAddress)
        external
        view
        returns (address)
    {
        return _orentables[tokenAddress];
    }

    /// @notice Get WToken address associated to the specific wrapped token
    /// @param tokenAddress wrapped token address
    /// @return WToken address
    function getWRentable(address tokenAddress)
        external
        view
        returns (address)
    {
        return _wrentables[tokenAddress];
    }

    /// @notice Get wallet factory address
    /// @return wallet factory address
    function getWalletFactory() external view returns (address) {
        return _walletFactory;
    }

    /// @notice Show current protocol fee
    /// @return protocol fee in 1e4 units, e.g. 100 = 1%
    function getFee() external view returns (uint16) {
        return _fee;
    }

    /// @notice Get protocol fee collector
    /// @return protocol fee collector address
    function getFeeCollector() external view returns (address payable) {
        return _feeCollector;
    }

    /// @notice Show a token is enabled as payment token
    /// @param paymentTokenAddress payment token address
    /// @return status, see RentableStorageV1 for values
    function getPaymentTokenAllowlist(address paymentTokenAddress)
        external
        view
        returns (uint8)
    {
        return _paymentTokenAllowlist[paymentTokenAddress];
    }

    /// @notice Show O/W Token can invoke selector on respective wrapped token
    /// @param caller O/W Token address
    /// @param selector function selector to invoke
    /// @return a bool representing enabled or not
    function isEnabledProxyCall(address caller, bytes4 selector)
        external
        view
        returns (bool)
    {
        return _proxyAllowList[caller][selector];
    }

    /// @inheritdoc IRentable
    function userWallet(address user)
        external
        view
        override
        returns (address payable)
    {
        return _wallets[user];
    }

    /// @inheritdoc IRentable
    function rentalConditions(address tokenAddress, uint256 tokenId)
        external
        view
        override
        returns (RentableTypes.RentalConditions memory)
    {
        return _rentalConditions[tokenAddress][tokenId];
    }

    /// @inheritdoc IRentable
    function expiresAt(address tokenAddress, uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return _expiresAt[tokenAddress][tokenId];
    }

    /// @inheritdoc IRentable
    function isExpired(address tokenAddress, uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isExpired(tokenAddress, tokenId);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Internal ---------- */

    /// @dev Create user wallet address
    /// @param user user address
    /// @return wallet address
    function _createWalletForUser(address user)
        internal
        returns (address payable wallet)
    {
        // slither-disable-next-line reentrancy-benign
        wallet = IWalletFactory(_walletFactory).createWallet(
            address(this),
            user
        );

        require(
            wallet != address(0),
            "Wallet Factory is not returning a valid wallet address"
        );

        _wallets[user] = wallet;

        // slither-disable-next-line reentrancy-events
        emit WalletCreated(user, wallet);

        return wallet;
    }

    /// @dev Get user wallet address (create if not exist)
    /// @param user user address
    /// @return wallet address
    function _getOrCreateWalletForUser(address user)
        internal
        returns (address payable wallet)
    {
        wallet = _wallets[user];

        if (wallet == address(0)) {
            wallet = _createWalletForUser(user);
        }

        return wallet;
    }

    /// @dev Deposit only a wrapped token and mint respective OToken
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param to user to mint
    function _deposit(
        address tokenAddress,
        uint256 tokenId,
        address to
    ) internal {
        address oRentable = _getExistingORentable(tokenAddress);

        require(
            IERC721Upgradeable(tokenAddress).ownerOf(tokenId) == address(this),
            "Token not deposited"
        );

        IERC721ReadOnlyProxy(oRentable).mint(to, tokenId);

        _postDeposit(tokenAddress, tokenId, to);

        emit Deposit(to, tokenAddress, tokenId);
    }

    /// @dev Deposit and list a wrapped token
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param to user to mint
    /// @param rc rental conditions see RentableTypes.RentalConditions
    function _depositAndList(
        address tokenAddress,
        uint256 tokenId,
        address to,
        RentableTypes.RentalConditions memory rc
    ) internal {
        _deposit(tokenAddress, tokenId, to);

        _createOrUpdateRentalConditions(to, tokenAddress, tokenId, rc);
    }

    /// @dev Set rental conditions for a wrapped token
    /// @param user who is changing the conditions
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param rc rental conditions see RentableTypes.RentalConditions
    function _createOrUpdateRentalConditions(
        address user,
        address tokenAddress,
        uint256 tokenId,
        RentableTypes.RentalConditions memory rc
    ) internal {
        require(
            _paymentTokenAllowlist[rc.paymentTokenAddress] != NOT_ALLOWED_TOKEN,
            "Not supported payment token"
        );

        require(
            rc.minTimeDuration <= rc.maxTimeDuration,
            "Minimum duration cannot be greater than maximum"
        );

        _rentalConditions[tokenAddress][tokenId] = rc;

        _postList(
            tokenAddress,
            tokenId,
            user,
            rc.minTimeDuration,
            rc.maxTimeDuration,
            rc.pricePerSecond
        );

        emit UpdateRentalConditions(
            tokenAddress,
            tokenId,
            rc.paymentTokenAddress,
            rc.paymentTokenId,
            rc.minTimeDuration,
            rc.maxTimeDuration,
            rc.pricePerSecond,
            rc.privateRenter
        );
    }

    /// @dev Cancel rental conditions for a wrapped token
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    function _deleteRentalConditions(address tokenAddress, uint256 tokenId)
        internal
    {
        // save gas instead of dropping all the structure
        (_rentalConditions[tokenAddress][tokenId]).maxTimeDuration = 0;
    }

    /// @dev Expire explicitely rental and update data structures for a specific wrapped token
    /// @param currentUserHolder (optional) current user holder address
    /// @param oTokenOwner (optional) otoken owner address
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param skipExistCheck assume or not wtoken id exists (gas optimization)
    /// @return currentlyRented true if rental is not expired
    // slither-disable-next-line calls-loop
    function _expireRental(
        address currentUserHolder,
        address oTokenOwner,
        address tokenAddress,
        uint256 tokenId,
        bool skipExistCheck
    ) internal returns (bool currentlyRented) {
        if (
            skipExistCheck ||
            IERC721ExistExtension(_wrentables[tokenAddress]).exists(tokenId)
        ) {
            if (_isExpired(tokenAddress, tokenId)) {
                address currentRentee = oTokenOwner == address(0)
                    ? IERC721Upgradeable(_orentables[tokenAddress]).ownerOf(
                        tokenId
                    )
                    : oTokenOwner;

                // recover asset from renter smart wallet to rentable contracts
                address wRentable = _wrentables[tokenAddress];
                // cannot be 0x0 because transferFrom avoid it
                address renter = currentUserHolder == address(0)
                    ? IERC721ExistExtension(wRentable).ownerOf(tokenId, true)
                    : currentUserHolder;
                address payable renterWallet = _wallets[renter];
                // slither-disable-next-line unused-return
                SimpleWallet(renterWallet).execute(
                    tokenAddress,
                    0,
                    abi.encodeWithSelector(
                        IERC721Upgradeable.transferFrom.selector, // we don't want to trigger onERC721Receiver
                        renterWallet,
                        address(this),
                        tokenId
                    ),
                    false
                );

                // burn
                IERC721ReadOnlyProxy(_wrentables[tokenAddress]).burn(tokenId);

                // post
                _postExpireRental(tokenAddress, tokenId, currentRentee);
                emit RentEnds(tokenAddress, tokenId);
            } else {
                currentlyRented = true;
            }
        }

        return currentlyRented;
    }

    /// @dev Execute custom logic after deposit via wrapped token library
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user depositor
    function _postDeposit(
        address tokenAddress,
        uint256 tokenId,
        address user
    ) internal skipIfLibraryNotSet(tokenAddress) {
        // slither-disable-next-line unused-return
        _libraries[tokenAddress].functionDelegateCall(
            abi.encodeWithSelector(
                ICollectionLibrary.postDeposit.selector,
                tokenAddress,
                tokenId,
                user
            ),
            ""
        );
    }

    /// @dev Execute custom logic after listing via wrapped token library
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param user lister
    /// @param maxTimeDuration max duration allowed for the rental
    /// @param pricePerSecond price per second in payment token units
    function _postList(
        address tokenAddress,
        uint256 tokenId,
        address user,
        uint256 minTimeDuration,
        uint256 maxTimeDuration,
        uint256 pricePerSecond
    ) internal skipIfLibraryNotSet(tokenAddress) {
        // slither-disable-next-line unused-return
        _libraries[tokenAddress].functionDelegateCall(
            abi.encodeWithSelector(
                ICollectionLibrary.postList.selector,
                tokenAddress,
                tokenId,
                user,
                minTimeDuration,
                maxTimeDuration,
                pricePerSecond
            ),
            ""
        );
    }

    /// @dev Execute custom logic after rent via wrapped token library
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param duration rental duration
    /// @param from rentee
    /// @param to renter
    /// @param toWallet receiver wallet
    function _postRent(
        address tokenAddress,
        uint256 tokenId,
        uint256 duration,
        address from,
        address to,
        address toWallet
    ) internal skipIfLibraryNotSet(tokenAddress) {
        // slither-disable-next-line unused-return
        _libraries[tokenAddress].functionDelegateCall(
            abi.encodeWithSelector(
                ICollectionLibrary.postRent.selector,
                tokenAddress,
                tokenId,
                duration,
                from,
                to,
                toWallet
            ),
            ""
        );
    }

    /// @dev Execute custom logic after rent expires via wrapped token library
    /// @param tokenAddress wrapped token address
    /// @param tokenId wrapped token id
    /// @param from rentee
    // slither-disable-next-line calls-loop
    function _postExpireRental(
        address tokenAddress,
        uint256 tokenId,
        address from
    ) internal skipIfLibraryNotSet(tokenAddress) {
        // slither-disable-next-line unused-return
        _libraries[tokenAddress].functionDelegateCall(
            abi.encodeWithSelector(
                ICollectionLibrary.postExpireRental.selector,
                tokenAddress,
                tokenId,
                from
            ),
            ""
        );
    }

    /* ---------- Public ---------- */

    /// @inheritdoc IRentable
    function createWalletForUser(address user)
        external
        override
        returns (address payable wallet)
    {
        require(
            user != address(0),
            "Cannot create a smart wallet for the void"
        );

        require(_wallets[user] == address(0), "Wallet already existing");

        return _createWalletForUser(user);
    }

    /// @inheritdoc IRentable
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override whenNotPaused nonReentrant returns (bytes4) {
        if (data.length == 0) {
            _deposit(msg.sender, tokenId, from);
        } else {
            _depositAndList(
                msg.sender,
                tokenId,
                from,
                abi.decode(data, (RentableTypes.RentalConditions))
            );
        }

        return this.onERC721Received.selector;
    }

    /// @inheritdoc IRentable
    function withdraw(address tokenAddress, uint256 tokenId)
        external
        override
        whenNotPaused
        nonReentrant
    {
        address user = msg.sender;
        address oRentable = _getExistingORentableCheckOwnership(
            tokenAddress,
            tokenId,
            user
        );

        require(
            !_expireRental(address(0), user, tokenAddress, tokenId, false),
            "Current rent still pending"
        );

        _deleteRentalConditions(tokenAddress, tokenId);

        IERC721ReadOnlyProxy(oRentable).burn(tokenId);

        IERC721Upgradeable(tokenAddress).safeTransferFrom(
            address(this),
            user,
            tokenId
        );

        emit Withdraw(tokenAddress, tokenId);
    }

    /// @inheritdoc IRentable
    function createOrUpdateRentalConditions(
        address tokenAddress,
        uint256 tokenId,
        RentableTypes.RentalConditions calldata rc
    ) external override whenNotPaused onlyOTokenOwner(tokenAddress, tokenId) {
        _createOrUpdateRentalConditions(msg.sender, tokenAddress, tokenId, rc);
    }

    /// @inheritdoc IRentable
    function deleteRentalConditions(address tokenAddress, uint256 tokenId)
        external
        override
        whenNotPaused
        onlyOTokenOwner(tokenAddress, tokenId)
    {
        _deleteRentalConditions(tokenAddress, tokenId);
    }

    /// @inheritdoc IRentable
    function rent(
        address tokenAddress,
        uint256 tokenId,
        uint256 duration
    ) external payable override whenNotPaused nonReentrant {
        // 1. check token is deposited and available for rental
        address oRentable = _getExistingORentable(tokenAddress);
        address payable rentee = payable(
            IERC721Upgradeable(oRentable).ownerOf(tokenId)
        );

        RentableTypes.RentalConditions memory rcs = _rentalConditions[
            tokenAddress
        ][tokenId];
        require(rcs.maxTimeDuration > 0, "Not available");

        require(
            !_expireRental(address(0), rentee, tokenAddress, tokenId, false),
            "Current rent still pending"
        );

        // 2. validate renter offer with rentee conditions
        require(duration > 0, "Duration cannot be zero");

        require(
            duration >= rcs.minTimeDuration,
            "Duration lower than conditions"
        );

        require(
            duration <= rcs.maxTimeDuration,
            "Duration greater than conditions"
        );

        require(
            rcs.privateRenter == address(0) || rcs.privateRenter == msg.sender,
            "Rental reserved for another user"
        );

        // 3. mint wtoken
        uint256 eta = block.timestamp + duration;
        _expiresAt[tokenAddress][tokenId] = eta;
        IERC721ReadOnlyProxy(_wrentables[tokenAddress]).mint(
            msg.sender,
            tokenId
        );

        // 4. transfer token to the renter smart wallet
        address renterWallet = _getOrCreateWalletForUser(msg.sender);
        IERC721Upgradeable(tokenAddress).safeTransferFrom(
            address(this),
            renterWallet,
            tokenId,
            ""
        );

        // 5. fees distribution
        // gross due amount
        uint256 paymentQty = rcs.pricePerSecond * duration;
        // protocol and rentee fees calc
        uint256 feesForFeeCollector = (paymentQty * _fee) / BASE_FEE;
        uint256 feesForRentee = paymentQty - feesForFeeCollector;

        if (rcs.paymentTokenAddress == address(0)) {
            require(msg.value >= paymentQty, "Not enough funds");
            if (feesForFeeCollector > 0) {
                Address.sendValue(_feeCollector, feesForFeeCollector);
            }

            Address.sendValue(rentee, feesForRentee);

            // refund eventual remaining
            if (msg.value > paymentQty) {
                Address.sendValue(payable(msg.sender), msg.value - paymentQty);
            }
        } else if (
            _paymentTokenAllowlist[rcs.paymentTokenAddress] == ERC20_TOKEN
        ) {
            if (feesForFeeCollector > 0) {
                IERC20Upgradeable(rcs.paymentTokenAddress).safeTransferFrom(
                    msg.sender,
                    _feeCollector,
                    feesForFeeCollector
                );
            }

            IERC20Upgradeable(rcs.paymentTokenAddress).safeTransferFrom(
                msg.sender,
                rentee,
                feesForRentee
            );
        } else {
            if (feesForFeeCollector > 0) {
                IERC1155Upgradeable(rcs.paymentTokenAddress).safeTransferFrom(
                    msg.sender,
                    _feeCollector,
                    rcs.paymentTokenId,
                    feesForFeeCollector,
                    ""
                );
            }

            IERC1155Upgradeable(rcs.paymentTokenAddress).safeTransferFrom(
                msg.sender,
                rentee,
                rcs.paymentTokenId,
                feesForRentee,
                ""
            );
        }

        // 6. after rent custom logic
        _postRent(
            tokenAddress,
            tokenId,
            duration,
            rentee,
            msg.sender,
            renterWallet
        );

        emit Rent(
            rentee,
            msg.sender,
            tokenAddress,
            tokenId,
            rcs.paymentTokenAddress,
            rcs.paymentTokenId,
            eta
        );
    }

    /// @inheritdoc IRentable
    function expireRental(address tokenAddress, uint256 tokenId)
        external
        override
        whenNotPaused
        returns (bool currentlyRented)
    {
        return
            _expireRental(address(0), address(0), tokenAddress, tokenId, false);
    }

    /// @notice Batch expireRental
    /// @param tokenAddresses array of wrapped token addresses
    /// @param tokenIds array of wrapped token id
    function expireRentals(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds
    ) external whenNotPaused {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            _expireRental(
                address(0),
                address(0),
                tokenAddresses[i],
                tokenIds[i],
                false
            );
        }
    }

    /* ---------- Public Permissioned ---------- */

    /// @inheritdoc IORentableHooks
    function afterOTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external override whenNotPaused onlyOToken(tokenAddress) {
        bool rented = _expireRental(
            address(0),
            from,
            tokenAddress,
            tokenId,
            false
        );

        address lib = _libraries[tokenAddress];
        if (lib != address(0)) {
            address wRentable = _wrentables[tokenAddress];
            address currentRenterWallet = IERC721ExistExtension(wRentable)
                .exists(tokenId)
                ? _wallets[IERC721Upgradeable(wRentable).ownerOf(tokenId)]
                : address(0);
            // slither-disable-next-line unused-return
            lib.functionDelegateCall(
                abi.encodeWithSelector(
                    ICollectionLibrary.postOTokenTransfer.selector,
                    tokenAddress,
                    tokenId,
                    from,
                    to,
                    currentRenterWallet,
                    rented
                ),
                ""
            );
        }
    }

    /// @inheritdoc IWRentableHooks
    function afterWTokenTransfer(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId
    ) external override whenNotPaused onlyWToken(tokenAddress) {
        // we need to pass from as current holder in the expire func
        // otw in the case is expired, wewould try to fetch from the recipient wallet
        // which doesn't hold it
        // could be better to check for expire in a preWTokenTransfer

        bool currentlyRented = _expireRental(
            from,
            address(0),
            tokenAddress,
            tokenId,
            true
        );

        if (currentlyRented) {
            // move to the recipient smart wallet
            address payable fromWallet = _wallets[from];
            // slither-disable-next-line unused-return
            SimpleWallet(fromWallet).execute(
                tokenAddress,
                0,
                abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256)",
                    fromWallet,
                    _getOrCreateWalletForUser(to),
                    tokenId
                ),
                false
            );

            // execute lib code
            address lib = _libraries[tokenAddress];
            if (lib != address(0)) {
                // slither-disable-next-line unused-return
                lib.functionDelegateCall(
                    abi.encodeWithSelector(
                        ICollectionLibrary.postWTokenTransfer.selector,
                        tokenAddress,
                        tokenId,
                        from,
                        to,
                        _wallets[to]
                    ),
                    ""
                );
            }
        }
    }

    /// @inheritdoc IRentableHooks
    function proxyCall(
        address to,
        bytes4 selector,
        bytes memory data
    )
        external
        payable
        override
        whenNotPaused
        onlyOTokenOrWToken(to) // this implicitly checks `to` is the associated wrapped token
        returns (bytes memory)
    {
        require(
            _proxyAllowList[msg.sender][selector],
            "Proxy call unauthorized"
        );

        return
            to.functionCallWithValue(
                bytes.concat(selector, data),
                msg.value,
                ""
            );
    }
}
