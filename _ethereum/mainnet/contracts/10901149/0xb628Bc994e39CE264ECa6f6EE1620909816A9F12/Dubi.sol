// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./Purpose.sol";

contract Dubi is ERC20 {
    Purpose private immutable _prps;

    constructor(
        uint256 initialSupply,
        address optIn,
        address purpose,
        address hodl,
        address externalAddress1,
        address externalAddress2,
        address externalAddress3
    )
        public
        ERC20(
            "Decentralized Universal Basic Income",
            "DUBI",
            optIn,
            hodl,
            externalAddress1,
            externalAddress2,
            externalAddress3
        )
    {
        _mintInitialSupply(msg.sender, initialSupply);

        _prps = Purpose(purpose);
    }

    function hodlMint(address to, uint256 amount) public {
        require(msg.sender == _hodlAddress, "DUBI-2");
        _mint(to, amount);
    }

    function purposeMint(address to, uint256 amount) public {
        require(msg.sender == address(_prps), "DUBI-3");
        _mint(to, amount);
    }

    function _callerIsDeployTimeKnownContract()
        internal
        override
        view
        returns (bool)
    {
        if (msg.sender == address(_prps)) {
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
        require(_callerIsDeployTimeKnownContract(), "DUBI-1");
        _burnFuel(from, fuel);
    }

    function _burnFuel(address from, TokenFuel memory fuel) private {
        require(fuel.amount <= MAX_BOOSTER_FUEL, "DUBI-5");
        require(from != address(0) && from != msg.sender, "DUBI-6");

        if (fuel.tokenAlias == TOKEN_FUEL_ALIAS_DUBI) {
            // Burn fuel from DUBI
            UnpackedData memory unpacked = _unpackPackedData(_packedData[from]);
            require(unpacked.balance >= fuel.amount, "DUBI-7");
            unpacked.balance -= fuel.amount;
            _packedData[from] = _packUnpackedData(unpacked);
            return;
        }

        revert("DUBI-8");
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

        if (fuel.dubi > 0) {
            require(fuel.dubi <= MAX_BOOSTER_FUEL, "DUBI-5");

            // From uses his own DUBI to fuel the boost
            require(unpacked.balance >= fuelBurn.amount, "DUBI-7");
            unpacked.balance -= fuel.dubi;

            fuelBurn.amount = fuel.dubi;
            fuelBurn.fuelType = FuelType.DUBI;

            return fuelBurn;
        }

        // If the fuel is PRPS, then we have to reach out to the PRPS contract.
        if (fuel.unlockedPrps > 0) {
            // Reverts if the requested amount cannot be burned
            _prps.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_UNLOCKED_PRPS,
                    amount: fuel.unlockedPrps
                })
            );

            fuelBurn.amount = fuel.unlockedPrps;
            fuelBurn.fuelType = FuelType.UNLOCKED_PRPS;
            return fuelBurn;
        }

        if (fuel.lockedPrps > 0) {
            // Reverts if the requested amount cannot be burned
            _prps.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_LOCKED_PRPS,
                    amount: fuel.lockedPrps
                })
            );

            fuelBurn.amount = fuel.lockedPrps;
            fuelBurn.fuelType = FuelType.LOCKED_PRPS;
            return fuelBurn;
        }

        // No fuel at all
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

        // If the fuel is DUBI, then we can remove it directly
        if (fuel.dubi > 0) {
            require(fuel.dubi <= MAX_BOOSTER_FUEL, "DUBI-5");

            require(unpacked.balance >= fuel.dubi, "DUBI-7");
            unpacked.balance -= fuel.dubi;

            fuelBurn.amount = fuel.dubi;
            fuelBurn.fuelType = FuelType.DUBI;

            return fuelBurn;
        }

        // If the fuel is PRPS, then we have to reach out to the PRPS contract.
        if (fuel.unlockedPrps > 0) {
            // Reverts if the requested amount cannot be burned
            _prps.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_UNLOCKED_PRPS,
                    amount: fuel.unlockedPrps
                })
            );

            fuelBurn.amount = fuel.unlockedPrps;
            fuelBurn.fuelType = FuelType.UNLOCKED_PRPS;

            return fuelBurn;
        }

        if (fuel.lockedPrps > 0) {
            // Reverts if the requested amount cannot be burned
            _prps.burnFuel(
                from,
                TokenFuel({
                    tokenAlias: TOKEN_FUEL_ALIAS_LOCKED_PRPS,
                    amount: fuel.lockedPrps
                })
            );

            // No direct fuel, but we still return a indirect fuel so that it can be added
            // to the burn event.
            fuelBurn.amount = fuel.lockedPrps;
            fuelBurn.fuelType = FuelType.LOCKED_PRPS;
            return fuelBurn;
        }

        // DUBI has no intrinsic fuel
        if (fuel.intrinsicFuel > 0) {
            revert("DUBI-8");
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
        hashers[1] = address(_prps);
        hashers[2] = _hodlAddress;
        hashers[3] = _externalAddress1;
        hashers[4] = _externalAddress2;

        return hashers;
    }
}
