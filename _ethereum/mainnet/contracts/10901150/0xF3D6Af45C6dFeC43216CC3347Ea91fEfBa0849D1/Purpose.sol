// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./Dubi.sol";
import "./IHodl.sol";
import "./MintMath.sol";

contract Purpose is ERC20 {
    // The DUBI contract, required for auto-minting DUBI on burn.
    Dubi private immutable _dubi;

    // The HODL contract, required for burning locked PRPS.
    IHodl private immutable _hodl;

    modifier onlyHodl() {
        require(msg.sender == _hodlAddress, "PRPS-1");
        _;
    }

    constructor(
        uint256 initialSupply,
        address optIn,
        address dubi,
        address hodl,
        address externalAddress1,
        address externalAddress2,
        address externalAddress3
    )
        public
        ERC20(
            "Purpose",
            "PRPS",
            optIn,
            hodl,
            externalAddress1,
            externalAddress2,
            externalAddress3
        )
    {
        _dubi = Dubi(dubi);
        _hodl = IHodl(hodl);

        _mintInitialSupply(msg.sender, initialSupply);
    }

    /**
     * @dev Returns the address of the {HODL} contract used for burning locked PRPS.
     */
    function hodl() external view returns (address) {
        return address(_hodl);
    }

    /**
     * @dev Returns the hodl balance of the given `tokenHolder`
     */
    function hodlBalanceOf(address tokenHolder) public view returns (uint256) {
        // The hodl balance follows after the first 96 bits in the packed data.
        return uint96(_packedData[tokenHolder] >> 96);
    }

    /**
     * @dev Transfer `amount` PRPS from `from` to the Hodl contract.
     *
     * This can only be called by the Hodl contract.
     */
    function hodlTransfer(address from, uint96 amount) external onlyHodl {
        _move(from, address(_hodl), amount);
    }

    /**
     * @dev Increase the hodl balance of `account` by `hodlAmount`. This is
     * only used as part of the migration.
     */
    function migrateHodlBalance(address account, uint96 hodlAmount)
        external
        onlyHodl
    {
        UnpackedData memory unpacked = _unpackPackedData(_packedData[account]);

        unpacked.hodlBalance += hodlAmount;
        _packedData[account] = _packUnpackedData(unpacked);
    }

    /**
     * @dev Increase the hodl balance of `to` by moving `amount` PRPS from `from`'s balance.
     *
     * This can only be called by the Hodl contract.
     */
    function increaseHodlBalance(
        address from,
        address to,
        uint96 amount
    ) external onlyHodl {
        UnpackedData memory unpackedDataFrom = _unpackPackedData(
            _packedData[from]
        );
        UnpackedData memory unpackedDataTo;

        // We only need to unpack twice if from != to
        if (from != to) {
            unpackedDataTo = _unpackPackedData(_packedData[to]);
        } else {
            unpackedDataTo = unpackedDataFrom;
        }

        // `from` must have enough balance
        require(unpackedDataFrom.balance >= amount, "PRPS-3");

        // Subtract balance from `from`
        unpackedDataFrom.balance -= amount;
        // Add to `hodlBalance` from `to`
        unpackedDataTo.hodlBalance += amount;

        // We only need to pack twice if from != to
        if (from != to) {
            _packedData[to] = _packUnpackedData(unpackedDataTo);
        }

        _packedData[from] = _packUnpackedData(unpackedDataFrom);
    }

    /**
     * @dev Decrease the hodl balance of `from` by `hodlAmount` and increase
     * the regular balance by `refundAmount.
     *
     * `refundAmount` might be less than `hodlAmount`.
     *
     * E.g. when burning fuel in locked PRPS
     *
     * This can only be called by the Hodl contract.
     */
    function decreaseHodlBalance(
        address from,
        uint96 hodlAmount,
        uint96 refundAmount
    ) external onlyHodl {
        require(hodlAmount >= refundAmount, "PRPS-4");

        UnpackedData memory unpackedDataFrom = _unpackPackedData(
            _packedData[from]
        );

        // `from` must have enough balance
        require(unpackedDataFrom.hodlBalance >= hodlAmount, "PRPS-5");

        // Subtract amount from hodl balance
        unpackedDataFrom.hodlBalance -= hodlAmount;

        if (refundAmount > 0) {
            // Add amount to balance
            unpackedDataFrom.balance += refundAmount;
        }

        // Write to storage
        _packedData[from] = _packUnpackedData(unpackedDataFrom);
    }

    /**
     * @dev Revert the hodl balance change caused by `from` on `to`.
     *
     * E.g. when reverting a pending hodl.
     *
     * This can only be called by the Hodl contract.
     */
    function revertHodlBalance(
        address from,
        address to,
        uint96 amount
    ) external onlyHodl {
        UnpackedData memory unpackedDataFrom = _unpackPackedData(
            _packedData[from]
        );
        UnpackedData memory unpackedDataTo;

        // We only need to unpack twice if from != to
        if (from != to) {
            unpackedDataTo = _unpackPackedData(_packedData[to]);
        } else {
            unpackedDataTo = unpackedDataFrom;
        }

        // `to` must have enough hodl balance
        require(unpackedDataTo.hodlBalance >= amount, "PRPS-5");

        // Subtract hodl balance from `to`
        unpackedDataTo.hodlBalance -= amount;
        // Add to `balance` from `from`
        unpackedDataFrom.balance += amount;

        // We only need to pack twice if from != to
        if (from != to) {
            _packedData[to] = _packUnpackedData(unpackedDataTo);
        }

        _packedData[from] = _packUnpackedData(unpackedDataFrom);
    }

    /**
     * @dev Mint DUBI when burning PRPS
     * @param from address token holder address
     * @param transferAmount amount of tokens to burn
     * @param occupiedAmount amount of tokens that are occupied
     * @param createdAt equal to block.timestamp if not finalizing a pending op, otherwise
     * it corresponds to op.createdAt
     * @param finalizing boolean indicating whether this is a finalizing transaction or not. Changes
     * how the `amount` is interpreted.
     *
     * When burning PRPS, we first try to burn unlocked PRPS.
     * If burning an amount that exceeds the unlocked PRPS of `from`, we attempt to burn the
     * difference from locked PRPS.
     *
     * If the desired `amount` cannot be filled by taking locked and unlocked PRPS into account,
     * this function reverts.
     *
     * Burning locked PRPS means reducing the `hodlBalance` while burning unlocked PRPS means reducing
     * the regular `balance`.
     *
     * This function returns the actual unlocked PRPS that needs to be removed from `balance`.
     *
     */
    function _beforeBurn(
        address from,
        UnpackedData memory unpacked,
        uint96 transferAmount,
        uint96 occupiedAmount,
        uint32 createdAt,
        FuelBurn memory fuelBurn,
        bool finalizing
    ) internal override returns (uint96) {
        uint96 totalDubiToMint;
        uint96 lockedPrpsToBurn;
        uint96 burnableUnlockedPrps;

        // Depending on whether this is a finalizing burn or not,
        // the amount of locked/unlocked PRPS is determined differently.
        if (finalizing) {
            // For a finalizing burn, we use the occupied amount, since we already know how much
            // locked PRPS we are going to burn. This amount represents the `pendingLockedPrps`
            // on the hodl items.
            lockedPrpsToBurn = occupiedAmount;

            // Since `transferAmount` is the total amount of PRPS getting burned, we need to subtract
            // the `occupiedAmount` to get the actual amount of unlocked PRPS.

            // Sanity check
            assert(transferAmount >= occupiedAmount);
            transferAmount -= occupiedAmount;

            // Set the unlocked PRPS to burn to the updated `transferAmount`
            burnableUnlockedPrps = transferAmount;
        } else {
            // For a direct burn, we start off with the full amounts, since we don't know the exact
            // amounts initially.

            lockedPrpsToBurn = transferAmount;
            burnableUnlockedPrps = unpacked.balance;
        }

        // 1) Try to burn unlocked PRPS
        if (burnableUnlockedPrps > 0) {
            // Nice, we can burn unlocked PRPS

            // Catch underflow i.e. don't burn more than we need to
            if (burnableUnlockedPrps > transferAmount) {
                burnableUnlockedPrps = transferAmount;
            }

            // Calculate DUBI to mint based on unlocked PRPS we can burn
            totalDubiToMint = MintMath.calculateDubiToMintMax(
                burnableUnlockedPrps
            );

            // Subtract the amount of burned unlocked PRPS from the locked PRPS we
            // need to burn if this is NOT a finalizing burn, because in that case we
            // already have the exact amount locked PRPS we want to burn.
            if (!finalizing) {
                lockedPrpsToBurn -= burnableUnlockedPrps;
            }
        }

        // 2) Burn locked PRPS if there's not enough unlocked PRPS

        // Burn an additional amount of locked PRPS equal to the fuel if any
        if (fuelBurn.fuelType == FuelType.LOCKED_PRPS) {
            // The `burnFromLockedPrps` call will fail, if not enough PRPS can be burned.
            lockedPrpsToBurn += fuelBurn.amount;
        }

        if (lockedPrpsToBurn > 0) {
            uint96 dubiToMintFromLockedPrps = _burnFromLockedPrps({
                from: from,
                unpacked: unpacked,
                lockedPrpsToBurn: lockedPrpsToBurn,
                createdAt: createdAt,
                finalizing: finalizing
            });

            // We check 'greater than or equal' because it's possible to mint 0 new DUBI
            // e.g. when called right after a hodl where not enough time passed to generate new DUBI.
            uint96 dubiToMint = totalDubiToMint + dubiToMintFromLockedPrps;
            require(dubiToMint >= totalDubiToMint, "PRPS-6");

            totalDubiToMint = dubiToMint;
        } else {
            // Sanity check for finalizes that don't touch locked PRPS
            assert(occupiedAmount == 0);
        }

        // Burn minted DUBI equal to the fuel if any
        if (fuelBurn.fuelType == FuelType.AUTO_MINTED_DUBI) {
            require(totalDubiToMint >= fuelBurn.amount, "PRPS-7");
            totalDubiToMint -= fuelBurn.amount;
        }

        // Mint DUBI taking differences between burned locked/unlocked into account
        if (totalDubiToMint > 0) {
            _dubi.purposeMint(from, totalDubiToMint);
        }

        return burnableUnlockedPrps;
    }

    function _burnFromLockedPrps(
        address from,
        UnpackedData memory unpacked,
        uint96 lockedPrpsToBurn,
        uint32 createdAt,
        bool finalizing
    ) private returns (uint96) {
        // Reverts if the exact amount needed cannot be burned
        uint96 dubiToMintFromLockedPrps = _hodl.burnLockedPrps({
            from: from,
            amount: lockedPrpsToBurn,
            dubiMintTimestamp: createdAt,
            burnPendingLockedPrps: finalizing
        });

        require(unpacked.hodlBalance >= lockedPrpsToBurn, "PRPS-8");

        unpacked.hodlBalance -= lockedPrpsToBurn;

        return dubiToMintFromLockedPrps;
    }

    function _callerIsDeployTimeKnownContract()
        internal
        override
        view
        returns (bool)
    {
        if (msg.sender == address(_dubi)) {
            return true;
        }

        return super._callerIsDeployTimeKnownContract();
    }

    //---------------------------------------------------------------
    // Fuel
    //---------------------------------------------------------------

    /**
     * @dev Burns `fuel` from `from`. Can only be called by one of the deploy-time known contracts.
     */
    function burnFuel(address from, TokenFuel memory fuel) public override {
        require(_callerIsDeployTimeKnownContract(), "PRPS-2");
        _burnFuel(from, fuel);
    }

    function _burnFuel(address from, TokenFuel memory fuel) private {
        require(fuel.amount <= MAX_BOOSTER_FUEL, "PRPS-10");
        require(from != address(0) && from != msg.sender, "PRPS-11");

        if (fuel.tokenAlias == TOKEN_FUEL_ALIAS_UNLOCKED_PRPS) {
            // Burn fuel from unlocked PRPS
            UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);
            require(unpacked.balance >= fuel.amount, "PRPS-7");
            unpacked.balance -= fuel.amount;
            _packedData[from] = _packUnpackedData(unpacked);
            return;
        }

        if (fuel.tokenAlias == TOKEN_FUEL_ALIAS_LOCKED_PRPS) {
            // Burn fuel from locked PRPS
            UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);
            require(unpacked.hodlBalance >= fuel.amount, "PRPS-7");
            unpacked.hodlBalance -= fuel.amount;

            // We pass a mint timestamp, but that doesn't mean that DUBI is minted.
            // The returned DUBI that should be minted is ignored.
            // Reverts if not enough locked PRPS can be burned.
            _hodl.burnLockedPrps({
                from: from,
                amount: fuel.amount,
                dubiMintTimestamp: uint32(block.timestamp),
                burnPendingLockedPrps: false
            });

            _packedData[from] = _packUnpackedData(unpacked);
            return;
        }

        revert("PRPS-12");
    }

    /**
     *@dev Burn the fuel of a `boostedSend`
     */
    function _burnBoostedSendFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal override returns (FuelBurn memory) {
        FuelBurn memory fuelBurn;

        if (fuel.unlockedPrps > 0) {
            require(fuel.unlockedPrps <= MAX_BOOSTER_FUEL, "PRPS-10");

            require(unpacked.balance >= fuel.unlockedPrps, "PRPS-7");
            unpacked.balance -= fuel.unlockedPrps;

            fuelBurn.amount = fuel.unlockedPrps;
            fuelBurn.fuelType = FuelType.UNLOCKED_PRPS;
            return fuelBurn;
        }

        if (fuel.lockedPrps > 0) {
            require(fuel.lockedPrps <= MAX_BOOSTER_FUEL, "PRPS-10");

            // We pass a mint timestamp, but that doesn't mean that DUBI is minted.
            // The returned DUBI that should be minted is ignored.
            // Reverts if not enough locked PRPS can be burned.
            _hodl.burnLockedPrps({
                from: from,
                amount: fuel.lockedPrps,
                dubiMintTimestamp: uint32(block.timestamp),
                burnPendingLockedPrps: false
            });

            require(unpacked.hodlBalance >= fuel.lockedPrps, "PRPS-7");
            unpacked.hodlBalance -= fuel.lockedPrps;

            fuelBurn.amount = fuel.lockedPrps;
            fuelBurn.fuelType = FuelType.LOCKED_PRPS;
            return fuelBurn;
        }

        // If the fuel is DUBI, then we have to reach out to the DUBI contract.
        if (fuel.dubi > 0) {
            // Reverts if the requested amount cannot be burned
            _dubi.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_DUBI,
                    amount: fuel.dubi
                })
            );

            fuelBurn.amount = fuel.dubi;
            fuelBurn.fuelType = FuelType.DUBI;
            return fuelBurn;
        }

        return fuelBurn;
    }

    /**
     *@dev Burn the fuel of a `boostedBurn`
     */
    function _burnBoostedBurnFuel(
        address from,
        BoosterFuel memory fuel,
        UnpackedData memory unpacked
    ) internal override returns (FuelBurn memory) {
        FuelBurn memory fuelBurn;

        if (fuel.unlockedPrps > 0) {
            require(fuel.unlockedPrps <= MAX_BOOSTER_FUEL, "PRPS-10");

            require(unpacked.balance >= fuel.unlockedPrps, "PRPS-7");
            unpacked.balance -= fuel.unlockedPrps;

            fuelBurn.amount = fuel.unlockedPrps;
            fuelBurn.fuelType = FuelType.UNLOCKED_PRPS;
            return fuelBurn;
        }

        if (fuel.lockedPrps > 0) {
            require(fuel.lockedPrps <= MAX_BOOSTER_FUEL, "PRPS-10");

            require(unpacked.hodlBalance >= fuel.lockedPrps, "PRPS-7");
            // Fuel is taken from hodl balance in _beforeBurn
            // unpacked.hodlBalance -= fuel.lockedPrps;

            fuelBurn.amount = fuel.lockedPrps;
            fuelBurn.fuelType = FuelType.LOCKED_PRPS;

            return fuelBurn;
        }

        if (fuel.intrinsicFuel > 0) {
            require(fuel.intrinsicFuel <= MAX_BOOSTER_FUEL, "PRPS-10");

            fuelBurn.amount = fuel.intrinsicFuel;
            fuelBurn.fuelType = FuelType.AUTO_MINTED_DUBI;

            return fuelBurn;
        }

        // If the fuel is DUBI, then we have to reach out to the DUBI contract.
        if (fuel.dubi > 0) {
            // Reverts if the requested amount cannot be burned
            _dubi.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_DUBI,
                    amount: fuel.dubi
                })
            );

            fuelBurn.amount = fuel.dubi;
            fuelBurn.fuelType = FuelType.DUBI;
            return fuelBurn;
        }

        // No fuel at all
        return fuelBurn;
    }

    //---------------------------------------------------------------
    // Pending ops
    //---------------------------------------------------------------

    function _getHasherContracts()
        internal
        override
        returns (address[] memory)
    {
        address[] memory hashers = new address[](5);
        hashers[0] = address(this);
        hashers[1] = address(_dubi);
        hashers[2] = _hodlAddress;
        hashers[3] = _externalAddress1;
        hashers[4] = _externalAddress2;

        return hashers;
    }

    /**
     * @dev Create a pending transfer by moving the funds of `spender` to this contract.
     * Special behavior applies to pending burns to account for locked PRPS.
     */
    function _createPendingTransferInternal(
        OpHandle memory opHandle,
        address spender,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal override returns (PendingTransfer memory) {
        if (opHandle.opType != OP_TYPE_BURN) {
            return
                // Nothing special to do for non-burns so just call parent implementation
                super._createPendingTransferInternal(
                    opHandle,
                    spender,
                    from,
                    to,
                    amount,
                    data
                );
        }

        // When burning, we first use unlocked PRPS and match the remaining amount with locked PRPS from the Hodl contract.

        // Sanity check
        assert(amount < 2**96);
        uint96 transferAmount = uint96(amount);
        uint96 lockedPrpsAmount = transferAmount;

        UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);
        // First try to move as much unlocked PRPS as possible to the PRPS address
        uint96 unlockedPrpsToMove = transferAmount;
        if (unlockedPrpsToMove > unpacked.balance) {
            unlockedPrpsToMove = unpacked.balance;
        }

        // Update the locked PRPS we have to use
        lockedPrpsAmount -= unlockedPrpsToMove;

        if (unlockedPrpsToMove > 0) {
            _move({from: from, to: address(this), amount: unlockedPrpsToMove});
        }

        // If we still need locked PRPS, call into the Hodl contract.
        // This will also take pending hodls into account, if `from` has
        // some.
        if (lockedPrpsAmount > 0) {
            // Reverts if not the exact amount can be set to pending
            _hodl.setLockedPrpsToPending(from, lockedPrpsAmount);
        }

        // Create pending transfer
        return
            PendingTransfer({
                spender: spender,
                transferAmount: transferAmount,
                to: to,
                occupiedAmount: lockedPrpsAmount,
                data: data
            });
    }

    /**
     * @dev Hook that is called during revert of a pending op.
     * Reverts any changes to locked PRPS when 'opType' is burn.
     */
    function _onRevertPendingOp(
        address user,
        uint8 opType,
        uint64 opId,
        uint96 transferAmount,
        uint96 occupiedAmount
    ) internal override {
        if (opType != OP_TYPE_BURN) {
            return;
        }

        // Extract the pending locked PRPS from the amount.
        if (occupiedAmount > 0) {
            _hodl.revertLockedPrpsSetToPending(user, occupiedAmount);
        }
    }

    //---------------------------------------------------------------
    // Shared pending ops for Hodl
    //---------------------------------------------------------------

    /**
     * @dev Creates a new opHandle with the given type for `user`. Hodl and Prps share the same
     * opCounter to enforce a consistent order in which pending ops are finalized/reverted
     * across contracts. This function can only be called by Hodl.
     */
    function createNewOpHandleShared(
        IOptIn.OptInStatus memory optInStatus,
        address user,
        uint8 opType
    ) public onlyHodl returns (OpHandle memory) {
        return _createNewOpHandle(optInStatus, user, opType);
    }

    /**
     * @dev Delete the op handle with the given `opId` from `user`. Hodl and Prps share the same
     * opCounter to enforce a consistent order in which pending ops are finalized/reverted
     * across contracts. This function can only be called by Hodl.
     */
    function deleteOpHandleShared(address user, OpHandle memory opHandle)
        public
        onlyHodl
        returns (bool)
    {
        _deleteOpHandle(user, opHandle);
        return true;
    }

    /**
     * @dev Get the next op id for `user`. Hodl and Prps share the same
     * opCounter to enforce a consistent order in which pending ops are finalized/reverted
     * across contracts. This function can only be called by Hodl.
     */
    function assertFinalizeFIFOShared(address user, uint64 opId)
        public
        onlyHodl
        returns (bool)
    {
        _assertFinalizeFIFO(user, opId);
        return true;
    }

    /**
     * @dev Get the next op id for `user`. Hodl and Prps share the same
     * opCounter to enforce a consistent order in which pending ops are finalized/reverted
     * across contracts. This function can only be called by Hodl.
     */
    function assertRevertLIFOShared(address user, uint64 opId)
        public
        onlyHodl
        returns (bool)
    {
        _assertRevertLIFO(user, opId);
        return true;
    }
}
