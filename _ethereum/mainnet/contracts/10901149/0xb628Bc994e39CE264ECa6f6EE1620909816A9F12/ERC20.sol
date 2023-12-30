// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC1820Registry.sol";
import "./IBoostableERC20.sol";
import "./BoostableERC20.sol";

/**
 * @dev This is a heavily modified fork of @openzeppelin/contracts/token/ERC20/ERC20.sol (3.1.0)
 */
abstract contract ERC20 is IERC20, IBoostableERC20, BoostableERC20, Ownable {
    using SafeMath for uint256;

    // NOTE: In contrary to the Transfer event, the Burned event always
    // emits the amount including the burned fuel if any.
    // The amount is stored in the lower 96 bits of `amountAndFuel`,
    // followed by 3 bits to encode the type of fuel used and finally
    // another 96 bits for the fuel amount.
    //
    // 0         96        99                 195             256
    //   amount    fuelType      fuelAmount         padding
    //
    event Burned(uint256 amountAndFuel, bytes data);

    enum FuelType {NONE, UNLOCKED_PRPS, LOCKED_PRPS, DUBI, AUTO_MINTED_DUBI}

    struct FuelBurn {
        FuelType fuelType;
        uint96 amount;
    }

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address internal immutable _hodlAddress;

    address internal immutable _externalAddress1;
    address internal immutable _externalAddress2;
    address internal immutable _externalAddress3;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
    );

    // Mapping of address to packed data.
    // For efficiency reasons the token balance is a packed uint96 alongside
    // other data. The packed data has the following layout:
    //
    //   MSB                      uint256                      LSB
    //      uint64 nonce | uint96 hodlBalance | uint96 balance
    //
    // balance: the balance of a token holder that can be transferred freely
    // hodlBalance: the balance of a token holder that is hodled
    // nonce: a sequential number used for booster replay protection
    //
    // Only PRPS utilizes `hodlBalance`. For DUBI it is always 0.
    //
    mapping(address => uint256) internal _packedData;

    struct UnpackedData {
        uint96 balance;
        uint96 hodlBalance;
        uint64 nonce;
    }

    function _unpackPackedData(uint256 packedData)
        internal
        pure
        returns (UnpackedData memory)
    {
        UnpackedData memory unpacked;

        // 1) Read balance from the first 96 bits
        unpacked.balance = uint96(packedData);

        // 2) Read hodlBalance from the next 96 bits
        unpacked.hodlBalance = uint96(packedData >> 96);

        // 3) Read nonce from the next 64 bits
        unpacked.nonce = uint64(packedData >> (96 + 96));

        return unpacked;
    }

    function _packUnpackedData(UnpackedData memory unpacked)
        internal
        pure
        returns (uint256)
    {
        uint256 packedData;

        // 1) Write balance to the first 96 bits
        packedData |= unpacked.balance;

        // 2) Write hodlBalance to the the next 96 bits
        packedData |= uint256(unpacked.hodlBalance) << 96;

        // 3) Write nonce to the next 64 bits
        packedData |= uint256(unpacked.nonce) << (96 + 96);

        return packedData;
    }

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    //---------------------------------------------------------------
    // Pending state for non-boosted operations while opted-in
    //---------------------------------------------------------------
    uint8 internal constant OP_TYPE_SEND = BOOST_TAG_SEND;
    uint8 internal constant OP_TYPE_BURN = BOOST_TAG_BURN;

    struct PendingTransfer {
        // NOTE: For efficiency reasons balances are stored in a uint96 which is sufficient
        // since we only use 18 decimals.
        //
        // Two amounts are associated with a pending transfer, to allow deriving contracts
        // to store extra information.
        //
        // E.g. PRPS makes use of this by encoding the pending locked PRPS in the
        // `occupiedAmount` field.
        //
        address spender;
        uint96 transferAmount;
        address to;
        uint96 occupiedAmount;
        bytes data;
    }

    // A mapping of hash(user, opId) to pending transfers. Pending burns are also considered regular transfers.
    mapping(bytes32 => PendingTransfer) private _pendingTransfers;

    //---------------------------------------------------------------

    constructor(
        string memory name,
        string memory symbol,
        address optIn,
        address hodl,
        address externalAddress1,
        address externalAddress2,
        address externalAddress3
    ) public Ownable() BoostableERC20(optIn) {
        _name = name;
        _symbol = symbol;

        _hodlAddress = hodl;
        _externalAddress1 = externalAddress1;
        _externalAddress2 = externalAddress2;
        _externalAddress3 = externalAddress3;

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("BoostableERC20Token"),
            address(this)
        );
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            keccak256("ERC20Token"),
            address(this)
        );
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals.
     */
    function decimals() public pure returns (uint8) {
        return 18;
    }

    /**
     * @dev Returns the current nonce of `account`
     */
    function getNonce(address account) external override view returns (uint64) {
        UnpackedData memory unpacked = _unpackPackedData(_packedData[account]);
        return unpacked.nonce;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply()
        external
        override(IBoostableERC20, IERC20)
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder)
        public
        override(IBoostableERC20, IERC20)
        view
        returns (uint256)
    {
        // Return the balance of the holder that is not hodled (i.e. first 96 bits of the packeData)
        return uint96(_packedData[tokenHolder]);
    }

    /**
     * @dev Returns the unpacked data struct of `tokenHolder`
     */
    function unpackedDataOf(address tokenHolder)
        public
        view
        returns (UnpackedData memory)
    {
        return _unpackPackedData(_packedData[tokenHolder]);
    }

    /**
     * @dev Mints `amount` new tokens for `to`.
     *
     * To make things more efficient, the total supply is optionally packed into the passed
     * amount where the first 96 bits are used for the actual amount and the following 96 bits
     * for the total supply.
     *
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mintInitialSupply(address to, uint256 amount) internal {
        // _mint does not update the totalSupply by default, unless the second 96 bits
        // passed are non-zero - in which case the non-zero value becomes the new total supply.
        // So in order to get the correct initial supply, we have to mirror the lower 96 bits
        // to the following 96 bits.
        amount = amount | (amount << 96);
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20-1");

        // The actual amount to mint (=lower 96 bits)
        uint96 amountToMint = uint96(amount);

        // The new total supply, which may be 0 in which case no update is performed.
        uint96 updatedTotalSupply = uint96(amount >> 96);

        // Update state variables
        if (updatedTotalSupply > 0) {
            _totalSupply = updatedTotalSupply;
        }

        // Update packed data and check for uint96 overflow
        UnpackedData memory unpacked = _unpackPackedData(_packedData[to]);
        uint96 updatedBalance = unpacked.balance + amountToMint;

        // The overflow check also takes the hodlBalance into account
        require(
            updatedBalance + unpacked.hodlBalance >= unpacked.balance,
            "ERC20-2"
        );

        unpacked.balance = updatedBalance;
        _packedData[to] = _packUnpackedData(unpacked);

        emit Transfer(address(0), to, amountToMint);
    }

    /**
     * @dev Transfer `amount` from msg.sender to `recipient`
     */
    function transfer(address recipient, uint256 amount)
        public
        override(IBoostableERC20, IERC20)
        returns (bool)
    {
        _assertSenderRecipient(msg.sender, recipient);

        // Never create a pending transfer if msg.sender is a deploy-time known contract
        if (!_callerIsDeployTimeKnownContract()) {
            // Create pending transfer if sender is opted-in and the permaboost is active
            address from = msg.sender;
            IOptIn.OptInStatus memory optInStatus = getOptInStatus(from);
            if (optInStatus.isOptedIn && optInStatus.permaBoostActive) {
                _createPendingTransfer({
                    opType: OP_TYPE_SEND,
                    spender: msg.sender,
                    from: msg.sender,
                    to: recipient,
                    amount: amount,
                    data: "",
                    optInStatus: optInStatus
                });

                return true;
            }
        }

        _move({from: msg.sender, to: recipient, amount: amount});

        return true;
    }

    /**
     * @dev Burns `amount` of msg.sender.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes memory data) public {
        // Create pending burn if sender is opted-in and the permaboost is active
        IOptIn.OptInStatus memory optInStatus = getOptInStatus(msg.sender);
        if (optInStatus.isOptedIn && optInStatus.permaBoostActive) {
            _createPendingTransfer({
                opType: OP_TYPE_BURN,
                spender: msg.sender,
                from: msg.sender,
                to: address(0),
                amount: amount,
                data: data,
                optInStatus: optInStatus
            });

            return;
        }

        _burn({
            from: msg.sender,
            amount: amount,
            data: data,
            incrementNonce: false
        });
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`.
     *
     * Can only be used by deploy-time known contracts.
     *
     * IBoostableERC20 extension
     */
    function boostedTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data
    ) public override returns (bool) {
        _assertSenderRecipient(sender, recipient);

        IOptIn.OptInStatus memory optInStatus = getOptInStatus(sender);

        // Only transfer if `sender` is a deploy-time known contract, otherwise
        // revert.
        require(
            _isDeployTimeKnownContractAndCanTransfer(
                sender,
                recipient,
                amount,
                optInStatus,
                data
            ),
            "ERC20-17"
        );

        _move({from: sender, to: recipient, amount: amount});
        return true;
    }

    function _isDeployTimeKnownContractAndCanTransfer(
        address sender,
        address recipient,
        uint256 amount,
        IOptIn.OptInStatus memory optInStatus,
        bytes memory data
    ) private view returns (bool) {
        // If the caller not a deploy-time known contract, the transfer is not allowed
        if (!_callerIsDeployTimeKnownContract()) {
            return false;
        }

        if (msg.sender != _externalAddress3) {
            return true;
        }

        // _externalAddress3 passes a flag via `data` that indicates whether it is a boosted transaction
        // or not.
        uint8 isBoostedBits;
        assembly {
            // Load flag using a 1-byte offset, because `mload` always reads
            // 32-bytes at once and the first 32 bytes of `data` contain it's length.
            isBoostedBits := mload(add(data, 0x01))
        }

        // Reading into a 'bool' directly doesn't work for some reason
        if (isBoostedBits & 1 == 1) {
            return true;
        }

        //  If the latter, then _externalAddress3 can only transfer the funds if either:
        // - the permaboost is not active
        // - `sender` is not opted-in to begin with
        //
        // If `sender` is opted-in and the permaboost is active, _externalAddress3 cannot
        // take funds, except when boosted. Here the booster trusts _externalAddress3, since it already
        // verifies that `sender` provided a valid signature.
        //
        // This is special to _externalAddress3, other deploy-time known contracts do not make use of `data`.
        if (optInStatus.permaBoostActive && optInStatus.isOptedIn) {
            return false;
        }

        return true;
    }

    /**
     * @dev Verify the booster payload against the nonce that is stored in the packed data of an account.
     * The increment happens outside of this function, when the balance is updated.
     */
    function _verifyNonce(BoosterPayload memory payload, uint64 currentNonce)
        internal
        pure
    {
        require(currentNonce == payload.nonce - 1, "ERC20-5");
    }

    //---------------------------------------------------------------
    // Boosted functions
    //---------------------------------------------------------------

    /**
     * @dev Perform multiple `boostedSend` calls in a single transaction.
     *
     * NOTE: Booster extension
     */
    function boostedSendBatch(
        BoostedSend[] memory sends,
        Signature[] memory signatures
    ) external {
        require(
            sends.length > 0 && sends.length == signatures.length,
            "ERC20-6"
        );

        for (uint256 i = 0; i < sends.length; i++) {
            boostedSend(sends[i], signatures[i]);
        }
    }

    /**
     * @dev Perform multiple `boostedBurn` calls in a single transaction.
     *
     * NOTE: Booster extension
     */
    function boostedBurnBatch(
        BoostedBurn[] memory burns,
        Signature[] memory signatures
    ) external {
        require(
            burns.length > 0 && burns.length == signatures.length,
            "ERC20-6"
        );

        for (uint256 i = 0; i < burns.length; i++) {
            boostedBurn(burns[i], signatures[i]);
        }
    }

    /**
     * @dev Send `amount` tokens from `sender` to recipient`.
     * The `sender` must be opted-in and the `msg.sender` must be a trusted booster.
     *
     * NOTE: Booster extension
     */
    function boostedSend(BoostedSend memory send, Signature memory signature)
        public
    {
        address from = send.sender;
        address to = send.recipient;

        UnpackedData memory unpackedFrom = _unpackPackedData(_packedData[from]);
        UnpackedData memory unpackedTo = _unpackPackedData(_packedData[to]);

        // We verify the nonce separately, since it's stored next to the balance
        _verifyNonce(send.boosterPayload, unpackedFrom.nonce);

        _verifyBoostWithoutNonce(
            send.sender,
            hashBoostedSend(send, msg.sender),
            send.boosterPayload,
            signature
        );

        FuelBurn memory fuelBurn = _burnBoostedSendFuel(
            from,
            send.fuel,
            unpackedFrom
        );

        _moveUnpacked({
            from: send.sender,
            unpackedFrom: unpackedFrom,
            to: send.recipient,
            unpackedTo: unpackedTo,
            amount: send.amount,
            fuelBurn: fuelBurn,
            incrementNonce: true
        });
    }

    /**
     * @dev Burn the fuel of a `boostedSend`. Returns a `FuelBurn` struct containing information about the burn.
     */
    function _burnBoostedSendFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal virtual returns (FuelBurn memory);

    /**
     * @dev Burn `amount` tokens from `account`.
     * The `account` must be opted-in and the `msg.sender` must be a trusted booster.
     *
     * NOTE: Booster extension
     */
    function boostedBurn(
        BoostedBurn memory message,
        // A signature, that is compared against the function payload and only accepted if signed by 'sender'
        Signature memory signature
    ) public {
        address from = message.account;
        UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);

        // We verify the nonce separately, since it's stored next to the balance
        _verifyNonce(message.boosterPayload, unpacked.nonce);

        _verifyBoostWithoutNonce(
            message.account,
            hashBoostedBurn(message, msg.sender),
            message.boosterPayload,
            signature
        );

        FuelBurn memory fuelBurn = _burnBoostedBurnFuel(
            from,
            message.fuel,
            unpacked
        );

        _burnUnpacked({
            from: message.account,
            unpacked: unpacked,
            amount: message.amount,
            data: message.data,
            incrementNonce: true,
            fuelBurn: fuelBurn
        });
    }

    /**
     * @dev Burn the fuel of a `boostedSend`. Returns a `FuelBurn` struct containing information about the burn.
     */
    function _burnBoostedBurnFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal virtual returns (FuelBurn memory);

    function burnFuel(address from, TokenFuel memory fuel)
        external
        virtual
        override
    {}

    //---------------------------------------------------------------

    /**
     * @dev Get the allowance of `spender` for `holder`
     */
    function allowance(address holder, address spender)
        public
        override(IBoostableERC20, IERC20)
        view
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    /**
     * @dev Increase the allowance of `spender` by `value` for msg.sender
     */
    function approve(address spender, uint256 value)
        public
        override(IBoostableERC20, IERC20)
        returns (bool)
    {
        address holder = msg.sender;
        _assertSenderRecipient(holder, spender);
        _approve(holder, spender, value);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _assertSenderRecipient(msg.sender, spender);
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _assertSenderRecipient(msg.sender, spender);
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "ERC20-18")
        );
        return true;
    }

    /**
     * @dev Transfer `amount` from `holder` to `recipient`.
     *
     * `msg.sender` requires an allowance >= `amount` of `holder`.
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public override(IBoostableERC20, IERC20) returns (bool) {
        _assertSenderRecipient(holder, recipient);

        address spender = msg.sender;

        // Create pending transfer if the token holder is opted-in and the permaboost is active
        IOptIn.OptInStatus memory optInStatus = getOptInStatus(holder);
        if (optInStatus.isOptedIn && optInStatus.permaBoostActive) {
            // Ignore allowances if holder is opted-in
            require(holder == spender, "ERC20-7");

            _createPendingTransfer({
                opType: OP_TYPE_SEND,
                spender: spender,
                from: holder,
                to: recipient,
                amount: amount,
                data: "",
                optInStatus: optInStatus
            });

            return true;
        }

        // Not opted-in, but we still need to check approval of the given spender

        _approve(
            holder,
            spender,
            _allowances[holder][spender].sub(amount, "ERC20-4")
        );

        _move({from: holder, to: recipient, amount: amount});

        return true;
    }

    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param incrementNonce whether to increment the nonce or not - only true for boosted burns
     */
    function _burn(
        address from,
        uint256 amount,
        bytes memory data,
        bool incrementNonce
    ) internal virtual {
        require(from != address(0), "ERC20-8");

        UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);

        // Empty fuel burn
        FuelBurn memory fuelBurn;

        _burnUnpacked({
            from: from,
            unpacked: unpacked,
            amount: amount,
            data: data,
            incrementNonce: incrementNonce,
            fuelBurn: fuelBurn
        });
    }

    function _burnUnpacked(
        address from,
        UnpackedData memory unpacked,
        uint256 amount,
        bytes memory data,
        bool incrementNonce,
        FuelBurn memory fuelBurn
    ) internal {
        // _beforeBurn allows deriving contracts to run additional logic and affect the amount
        // that is actually getting burned. E.g. when burning PRPS, a portion of it might be taken
        // from the `hodlBalance`. Thus the returned `burnAmount` overrides `amount` and will be
        // subtracted from the actual `balance`.

        uint96 actualBurnAmount = _beforeBurn({
            from: from,
            unpacked: unpacked,
            transferAmount: uint96(amount),
            occupiedAmount: 0,
            createdAt: uint32(block.timestamp),
            fuelBurn: fuelBurn,
            finalizing: false
        });

        // Update to new balance

        if (incrementNonce) {
            // The nonce uses 64 bits, so a overflow is pretty much impossible
            // via increments of 1.
            unpacked.nonce++;
        }

        if (actualBurnAmount > 0) {
            require(unpacked.balance >= actualBurnAmount, "ERC20-9");
            unpacked.balance -= actualBurnAmount;
        }

        // Update packed data by writing to storage
        _packedData[from] = _packUnpackedData(unpacked);

        // Total supply can be updated in batches elsewhere, shaving off another >5k gas.
        // _totalSupply = _totalSupply.sub(amount);

        // The `Burned` event is emitted with the total amount that got burned.
        // Furthermore, the fuel used is encoded in the upper bits.
        uint256 amountAndFuel;

        // Set first 96 bits to amount
        amountAndFuel |= uint96(amount);

        // Set next 3 bits to fuel type
        uint8 fuelType = uint8(fuelBurn.fuelType);
        amountAndFuel |= uint256(fuelType) << 96;

        // Set next 96 bits to fuel amount
        amountAndFuel |= uint256(fuelBurn.amount) << (96 + 3);

        emit Burned(amountAndFuel, data);

        // We emit a transfer event with the actual burn amount excluding burned `hodlBalance`.
        emit Transfer(from, address(0), actualBurnAmount);
    }

    /**
     * @dev Allow deriving contracts to prepare a burn. By default it behaves like an identity function
     * and just returns the amount passed in.
     */
    function _beforeBurn(
        address from,
        UnpackedData memory unpacked,
        uint96 transferAmount,
        uint96 occupiedAmount,
        uint32 createdAt,
        FuelBurn memory fuelBurn,
        bool finalizing
    ) internal virtual returns (uint96) {
        return transferAmount;
    }

    function _move(
        address from,
        address to,
        uint256 amount
    ) internal {
        UnpackedData memory unpackedFrom = _unpackPackedData(_packedData[from]);
        UnpackedData memory unpackedTo = _unpackPackedData(_packedData[to]);

        // Empty fuel burn
        FuelBurn memory fuelBurn;

        _moveUnpacked({
            from: from,
            unpackedFrom: unpackedFrom,
            to: to,
            unpackedTo: unpackedTo,
            amount: amount,
            incrementNonce: false,
            fuelBurn: fuelBurn
        });
    }

    function _moveUnpacked(
        address from,
        UnpackedData memory unpackedFrom,
        address to,
        UnpackedData memory unpackedTo,
        uint256 amount,
        bool incrementNonce,
        FuelBurn memory fuelBurn
    ) internal {
        require(from != to, "ERC20-19");

        // Increment nonce of sender if it's a boosted send
        if (incrementNonce) {
            // The nonce uses 64 bits, so a overflow is pretty much impossible
            // via increments of 1.
            unpackedFrom.nonce++;
        }

        // Check if sender has enough tokens
        uint96 transferAmount = uint96(amount);
        require(unpackedFrom.balance >= transferAmount, "ERC20-10");

        // Subtract transfer amount from sender balance
        unpackedFrom.balance -= transferAmount;

        // Check that recipient balance doesn't overflow
        uint96 updatedRecipientBalance = unpackedTo.balance + transferAmount;
        require(updatedRecipientBalance >= unpackedTo.balance, "ERC20-12");
        unpackedTo.balance = updatedRecipientBalance;

        _packedData[from] = _packUnpackedData(unpackedFrom);
        _packedData[to] = _packUnpackedData(unpackedTo);

        // The transfer amount does not include any used fuel
        emit Transfer(from, to, transferAmount);
    }

    /**
     * @dev See {ERC20-_approve}.
     */
    function _approve(
        address holder,
        address spender,
        uint256 value
    ) internal {
        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    function _assertSenderRecipient(address sender, address recipient)
        private
        pure
    {
        require(sender != address(0) && recipient != address(0), "ERC20-13");
    }

    /**
     * @dev Checks whether msg.sender is a deploy-time known contract or not.
     */
    function _callerIsDeployTimeKnownContract()
        internal
        virtual
        view
        returns (bool)
    {
        if (msg.sender == _hodlAddress) {
            return true;
        }

        if (msg.sender == _externalAddress1) {
            return true;
        }

        if (msg.sender == _externalAddress2) {
            return true;
        }

        if (msg.sender == _externalAddress3) {
            return true;
        }

        return false;
    }

    //---------------------------------------------------------------
    // Pending ops
    //---------------------------------------------------------------

    /**
     * @dev Create a pending transfer
     */
    function _createPendingTransfer(
        uint8 opType,
        address spender,
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        IOptIn.OptInStatus memory optInStatus
    ) private {
        OpHandle memory opHandle = _createNewOpHandle(
            optInStatus,
            from,
            opType
        );

        PendingTransfer memory pendingTransfer = _createPendingTransferInternal(
            opHandle,
            spender,
            from,
            to,
            amount,
            data
        );

        _pendingTransfers[_getOpKey(from, opHandle.opId)] = pendingTransfer;

        // Emit PendingOp event
        emit PendingOp(from, opHandle.opId, opHandle.opType);
    }

    /**
     * @dev Create a pending transfer by moving the funds of `spender` to this contract.
     * Deriving contracts may override this function.
     */
    function _createPendingTransferInternal(
        OpHandle memory opHandle,
        address spender,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (PendingTransfer memory) {
        // Move funds into this contract

        // Reverts if `from` has less than `amount` tokens.
        _move({from: from, to: address(this), amount: amount});

        // Create op
        PendingTransfer memory pendingTransfer = PendingTransfer({
            transferAmount: uint96(amount),
            spender: spender,
            occupiedAmount: 0,
            to: to,
            data: data
        });

        return pendingTransfer;
    }

    /**
     * @dev Finalize a pending op
     */
    function finalizePendingOp(address user, OpHandle memory opHandle) public {
        uint8 opType = opHandle.opType;

        // Assert that the caller (msg.sender) is allowed to finalize the given op
        uint32 createdAt = uint32(_assertCanFinalize(user, opHandle));

        // Reverts if opId doesn't exist
        PendingTransfer storage pendingTransfer = _safeGetPendingTransfer(
            user,
            opHandle.opId
        );

        // Cleanup
        // NOTE: We do not delete the pending transfer struct, because it only makes it
        // more expensive since we already hit the gas refund limit.
        //
        // delete _pendingTransfers[_getOpKey(user, opHandle.opId)];
        //
        // The difference is ~13k gas.
        //
        // Deleting the op handle is enough to invalidate an opId forever:
        _deleteOpHandle(user, opHandle);

        // Call op type specific finalize
        if (opType == OP_TYPE_SEND) {
            _finalizeTransferOp(pendingTransfer, user, createdAt);
        } else if (opType == OP_TYPE_BURN) {
            _finalizePendingBurn(pendingTransfer, user, createdAt);
        } else {
            revert("ERC20-15");
        }

        // Emit event
        emit FinalizedOp(user, opHandle.opId, opType);
    }

    /**
     * @dev Finalize a pending transfer
     */
    function _finalizeTransferOp(
        PendingTransfer storage pendingTransfer,
        address from,
        uint32 createdAt
    ) private {
        address to = pendingTransfer.to;

        uint96 transferAmount = pendingTransfer.transferAmount;

        address _this = address(this);
        UnpackedData memory unpackedThis = _unpackPackedData(
            _packedData[_this]
        );
        UnpackedData memory unpackedTo = _unpackPackedData(_packedData[to]);

        // Check that sender balance does not overflow
        require(unpackedThis.balance >= transferAmount, "ERC20-2");
        unpackedThis.balance -= transferAmount;

        // Check that recipient doesn't overflow
        uint96 updatedBalanceRecipient = unpackedTo.balance + transferAmount;
        require(updatedBalanceRecipient >= unpackedTo.balance, "ERC20-2");

        unpackedTo.balance = updatedBalanceRecipient;

        _packedData[_this] = _packUnpackedData(unpackedThis);
        _packedData[to] = _packUnpackedData(unpackedTo);

        // Transfer event is emitted with original sender
        emit Transfer(from, to, transferAmount);
    }

    /**
     * @dev Finalize a pending burn
     */
    function _finalizePendingBurn(
        PendingTransfer storage pendingTransfer,
        address from,
        uint32 createdAt
    ) private {
        uint96 transferAmount = pendingTransfer.transferAmount;

        // We pass the packedData of `from` to `_beforeBurn`, because it PRPS needs to update
        // the `hodlBalance` which is NOT on the contract's own packedData.
        UnpackedData memory unpackedFrom = _unpackPackedData(_packedData[from]);

        // Empty fuel burn
        FuelBurn memory fuelBurn;

        uint96 burnAmountExcludingLockedPrps = _beforeBurn({
            from: from,
            unpacked: unpackedFrom,
            transferAmount: transferAmount,
            occupiedAmount: pendingTransfer.occupiedAmount,
            createdAt: createdAt,
            fuelBurn: fuelBurn,
            finalizing: true
        });

        // Update to new balance
        // NOTE: We change the balance of this contract, because that's where
        // the pending PRPS went to.
        address _this = address(this);
        UnpackedData memory unpackedOfContract = _unpackPackedData(
            _packedData[_this]
        );
        require(
            unpackedOfContract.balance >= burnAmountExcludingLockedPrps,
            "ERC20-2"
        );

        unpackedOfContract.balance -= burnAmountExcludingLockedPrps;
        _packedData[_this] = _packUnpackedData(unpackedOfContract);
        _packedData[from] = _packUnpackedData(unpackedFrom);

        // Furthermore, total supply can be updated elsewhere, shaving off another >5k gas.
        // _totalSupply = _totalSupply.sub(amount);

        // Emit events using the same `transferAmount` instead of what `_beforeBurn`
        // returned which is only used for updating the balance correctly.
        emit Burned(transferAmount, pendingTransfer.data);
        emit Transfer(from, address(0), transferAmount);
    }

    /**
     * @dev Revert a pending operation.
     *
     * Only the opted-in booster can revert a transaction if it provides a signed and still valid booster message
     * from the original sender.
     */
    function revertPendingOp(
        address user,
        OpHandle memory opHandle,
        bytes memory boosterMessage,
        Signature memory signature
    ) public {
        // Prepare revert, including permission check and prevents reentrancy for same opHandle.
        _prepareOpRevert({
            user: user,
            opHandle: opHandle,
            boosterMessage: boosterMessage,
            signature: signature
        });

        // Now perform the actual revert of the pending op
        _revertPendingOp(user, opHandle.opType, opHandle.opId);
    }

    /**
     * @dev Revert a pending transfer
     */
    function _revertPendingOp(
        address user,
        uint8 opType,
        uint64 opId
    ) private {
        PendingTransfer storage pendingTransfer = _safeGetPendingTransfer(
            user,
            opId
        );

        uint96 transferAmount = pendingTransfer.transferAmount;
        uint96 occupiedAmount = pendingTransfer.occupiedAmount;

        // Move funds from this contract back to the original sender. Transfers and burns
        // are reverted the same way. We only transfer back the `transferAmount` - that is the amount
        // that actually got moved into this contract. The occupied amount is released during `onRevertPendingOp`
        // by the deriving contract.
        _move({from: address(this), to: user, amount: transferAmount});

        // Call hook to allow deriving contracts to perform additional cleanup
        _onRevertPendingOp(user, opType, opId, transferAmount, occupiedAmount);

        // NOTE: we do not clean up the ops mapping, because we already hit the
        // gas refund limit.
        // delete _pendingTransfers[_getOpKey(user, opHandle.opId)];

        // Emit event
        emit RevertedOp(user, opId, opType);
    }

    /**
     * @dev Hook that is called during revert of a pending transfer.
     * Allows deriving contracts to perform additional cleanup.
     */
    function _onRevertPendingOp(
        address user,
        uint8 opType,
        uint64 opId,
        uint96 transferAmount,
        uint96 occupiedAmount
    ) internal virtual {}

    /**
     * @dev Safely get a pending transfer. Reverts if it doesn't exist.
     */
    function _safeGetPendingTransfer(address user, uint64 opId)
        private
        view
        returns (PendingTransfer storage)
    {
        PendingTransfer storage pendingTransfer = _pendingTransfers[_getOpKey(
            user,
            opId
        )];

        require(pendingTransfer.spender != address(0), "ERC20-16");

        return pendingTransfer;
    }
}
