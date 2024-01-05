// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Fund.sol";
import "./HourlyBondSubscriptionLending.sol";
import "./BondLending.sol";
import "./IncentivizedHolder.sol";

// TODO activate bonds for lending

/// @title Manage lending for a variety of bond issuers
contract Lending is
    RoleAware,
    HourlyBondSubscriptionLending,
    BondLending,
    IncentivizedHolder
{
    /// @dev IDs for all bonds held by an address
    mapping(address => uint256[]) public bondIds;

    /// mapping issuers to tokens
    /// (in crossmargin, the issuers are tokens  themselves)
    mapping(address => address) public issuerTokens;

    /// In case of shortfall, adjust debt
    mapping(address => uint256) public haircuts;

    /// map of available issuers
    mapping(address => bool) public activeIssuers;

    constructor(address _roles) RoleAware(_roles) {
        uint256 APR = 899;
        maxHourlyYieldFP = (FP32 * APR) / 100 / (24 * 365);

        uint256 aprChangePerMil = 3;
        yieldChangePerSecondFP = (FP32 * aprChangePerMil) / 1000;
    }

    /// Make a issuer available for protocol
    function activateIssuer(address issuer) external {
        activateIssuer(issuer, issuer);
    }

    /// Make issuer != token available for protocol (isol. margin)
    function activateIssuer(address issuer, address token)
        public
        onlyOwnerExecActivator
    {
        activeIssuers[issuer] = true;
        issuerTokens[issuer] = token;
    }

    /// Remove a issuer from trading availability
    function deactivateIssuer(address issuer) external onlyOwnerExecActivator {
        activeIssuers[issuer] = false;
    }

    /// Set lending cap
    function setLendingCap(address issuer, uint256 cap)
        external
        onlyOwnerExecActivator
    {
        lendingMeta[issuer].lendingCap = cap;
    }

    /// Set lending buffer
    function setLendingBuffer(address issuer, uint256 buffer)
        external
        onlyOwnerExecActivator
    {
        lendingMeta[issuer].lendingBuffer = buffer;
    }

    /// Set withdrawal window
    function setWithdrawalWindow(uint256 window) external onlyOwnerExec {
        withdrawalWindow = window;
    }

    /// Set hourly yield APR for issuer
    function setHourlyYieldAPR(address issuer, uint256 aprPercent)
        external
        onlyOwnerExecActivator
    {
        HourlyBondMetadata storage bondMeta = hourlyBondMetadata[issuer];

        if (bondMeta.yieldAccumulator.accumulatorFP == 0) {
            uint256 yieldFP = FP32 + (FP32 * aprPercent) / 100 / (24 * 365);
            bondMeta.yieldAccumulator = YieldAccumulator({
                accumulatorFP: FP32,
                lastUpdated: block.timestamp,
                hourlyYieldFP: yieldFP
            });
            bondMeta.buyingSpeed = 1;
            bondMeta.withdrawingSpeed = 1;
            bondMeta.lastBought = block.timestamp;
            bondMeta.lastWithdrawn = block.timestamp;
        } else {
            YieldAccumulator storage yA =
                getUpdatedHourlyYield(issuer, bondMeta);
            yA.hourlyYieldFP = (FP32 * (100 + aprPercent)) / 100 / (24 * 365);
        }
    }

    /// Set maximum hourly yield in floating point
    function setMaxHourlyYieldFP(uint256 maxYieldFP) external onlyOwnerExec {
        maxHourlyYieldFP = maxYieldFP;
    }

    /// Set yield change per second in floating point
    function setYieldChangePerSecondFP(uint256 changePerSecondFP)
        external
        onlyOwnerExec
    {
        yieldChangePerSecondFP = changePerSecondFP;
    }

    /// Set runtime yields in floating point
    function setRuntimeYieldsFP(address issuer, uint256[] memory yieldsFP)
        external
        onlyOwnerExec
    {
        BondBucketMetadata[] storage bondMetas = bondBucketMetadata[issuer];
        for (uint256 i; bondMetas.length > i; i++) {
            bondMetas[i].runtimeYieldFP = yieldsFP[i];
        }
    }

    /// Set miniumum runtime
    function setMinRuntime(uint256 runtime) external onlyOwnerExec {
        require(runtime > 1 hours, "Min runtime > 1 hour");
        require(maxRuntime > runtime, "Runtime too long");
        minRuntime = runtime;
    }

    /// Set maximum runtime
    function setMaxRuntime(uint256 runtime) external onlyOwnerExec {
        require(runtime > minRuntime, "Max > min runtime");
        maxRuntime = runtime;
    }

    /// Set runtime weights in floating point
    function setRuntimeWeights(address issuer, uint256[] memory weights)
        external
        onlyOwnerExecActivator
    {
        BondBucketMetadata[] storage bondMetas = bondBucketMetadata[issuer];

        if (bondMetas.length == 0) {
            // we are initializing

            uint256 hourlyYieldFP = (110 * FP32) / 100 / (24 * 365);
            uint256 bucketSize = diffMaxMinRuntime / weights.length;

            for (uint256 i; weights.length > i; i++) {
                uint256 runtime = minRuntime + bucketSize * i;
                bondMetas.push(
                    BondBucketMetadata({
                        runtimeYieldFP: (hourlyYieldFP * runtime) / (1 hours),
                        lastBought: block.timestamp,
                        lastWithdrawn: block.timestamp,
                        yieldLastUpdated: block.timestamp,
                        buyingSpeed: 1,
                        withdrawingSpeed: 1,
                        runtimeWeight: weights[i],
                        totalLending: 0
                    })
                );
            }
        } else {
            require(weights.length == bondMetas.length, "Weights don't match");
            for (uint256 i; weights.length > i; i++) {
                bondMetas[i].runtimeWeight = weights[i];
            }
        }
    }

    /// @dev how much interest has accrued to a borrowed balance over time
    function applyBorrowInterest(
        uint256 balance,
        address issuer,
        uint256 yieldQuotientFP
    ) external returns (uint256 balanceWithInterest, uint256 accumulatorFP) {
        require(isBorrower(msg.sender), "Not approved call");

        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        updateBorrowYieldAccu(yA);
        accumulatorFP = yA.accumulatorFP;

        balanceWithInterest = applyInterest(
            balance,
            accumulatorFP,
            yieldQuotientFP
        );

        uint256 deltaAmount = balanceWithInterest - balance;
        LendingMetadata storage meta = lendingMeta[issuer];
        meta.totalBorrowed += deltaAmount;
    }

    /// @dev view function to get balance with borrowing interest applied
    function viewWithBorrowInterest(
        uint256 balance,
        address issuer,
        uint256 yieldQuotientFP
    ) external view returns (uint256) {
        uint256 accumulatorFP =
            viewCumulativeYieldFP(
                borrowYieldAccumulators[issuer],
                block.timestamp
            );
        return applyInterest(balance, accumulatorFP, yieldQuotientFP);
    }

    /// @dev gets called by router to register if a trader borrows issuers
    function registerBorrow(address issuer, uint256 amount) external {
        require(isBorrower(msg.sender), "Not approved borrower");
        require(activeIssuers[issuer], "Not approved issuer");

        LendingMetadata storage meta = lendingMeta[issuer];
        meta.totalBorrowed += amount;
        require(
            meta.totalLending >= meta.totalBorrowed,
            "Insufficient lending"
        );
    }

    /// @dev gets called by router if loan is extinguished
    function payOff(address issuer, uint256 amount) external {
        require(isBorrower(msg.sender), "Not approved borrower");
        lendingMeta[issuer].totalBorrowed -= amount;
    }

    /// @dev get the borrow yield for a specific issuer/token
    function viewAccumulatedBorrowingYieldFP(address issuer)
        external
        view
        returns (uint256)
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        return viewCumulativeYieldFP(yA, block.timestamp);
    }

    function viewAPRPer10k(YieldAccumulator storage yA)
        internal
        view
        returns (uint256)
    {
        uint256 hourlyYieldFP = yA.hourlyYieldFP;

        uint256 aprFP =
            ((hourlyYieldFP * 10_000 - FP32 * 10_000) * 365 days) / (1 hours);

        return aprFP / FP32;
    }

    /// @dev get current borrowing interest per 10k for a token / issuer
    function viewBorrowAPRPer10k(address issuer)
        external
        view
        returns (uint256)
    {
        return viewAPRPer10k(borrowYieldAccumulators[issuer]);
    }

    /// @dev get current lending APR per 10k for a token / issuer
    function viewHourlyBondAPRPer10k(address issuer)
        external
        view
        returns (uint256)
    {
        return viewAPRPer10k(hourlyBondMetadata[issuer].yieldAccumulator);
    }

    /// @dev In a liquidity crunch make a fallback bond until liquidity is good again
    function _makeFallbackBond(
        address issuer,
        address holder,
        uint256 amount
    ) internal override {
        _makeHourlyBond(issuer, holder, amount);
    }

    /// @dev withdraw an hour bond
    function withdrawHourlyBond(address issuer, uint256 amount) external {
        HourlyBond storage bond = hourlyBondAccounts[issuer][msg.sender];
        // apply all interest
        updateHourlyBondAmount(issuer, bond);
        super._withdrawHourlyBond(issuer, bond, amount);

        if (bond.amount == 0) {
            delete hourlyBondAccounts[issuer][msg.sender];
        }

        disburse(issuer, msg.sender, amount);

        withdrawClaim(msg.sender, issuer, amount);
    }

    /// Shut down hourly bond account for `issuer`
    function closeHourlyBondAccount(address issuer) external {
        HourlyBond storage bond = hourlyBondAccounts[issuer][msg.sender];
        // apply all interest
        updateHourlyBondAmount(issuer, bond);

        uint256 amount = bond.amount;
        super._withdrawHourlyBond(issuer, bond, amount);

        disburse(issuer, msg.sender, amount);

        delete hourlyBondAccounts[issuer][msg.sender];

        withdrawClaim(msg.sender, issuer, amount);
    }

    /// @dev buy hourly bond subscription
    function buyHourlyBondSubscription(address issuer, uint256 amount)
        external
    {
        require(activeIssuers[issuer], "Not approved issuer");

        LendingMetadata storage meta = lendingMeta[issuer];
        if (lendingTarget(meta) >= meta.totalLending + amount) {
            collectToken(issuer, msg.sender, amount);

            super._makeHourlyBond(issuer, msg.sender, amount);

            stakeClaim(msg.sender, issuer, amount);
        }
    }

    /// @dev buy fixed term bond that does not renew
    function buyBond(
        address issuer,
        uint256 runtime,
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256 bondIndex) {
        require(activeIssuers[issuer], "Not approved issuer");

        LendingMetadata storage meta = lendingMeta[issuer];
        if (
            lendingTarget(meta) >= meta.totalLending + amount &&
            maxRuntime >= runtime &&
            runtime >= minRuntime
        ) {
            bondIndex = super._makeBond(
                msg.sender,
                issuer,
                runtime,
                amount,
                minReturn
            );
            if (bondIndex > 0) {
                bondIds[msg.sender].push(bondIndex);

                collectToken(issuer, msg.sender, amount);
                stakeClaim(msg.sender, issuer, amount);
            }
        }
    }

    /// @dev send back funds of bond after maturity
    function withdrawBond(uint256 bondId) external {
        Bond storage bond = bonds[bondId];
        require(msg.sender == bond.holder, "Not bond holder");
        require(
            block.timestamp > bond.maturityTimestamp,
            "bond is still immature"
        );
        // in case of a shortfall, governance can step in to provide
        // additonal compensation beyond the usual incentive which
        // gets withdrawn here
        withdrawClaim(msg.sender, bond.issuer, bond.originalPrice);

        uint256 withdrawAmount = super._withdrawBond(bondId, bond);
        disburse(bond.issuer, msg.sender, withdrawAmount);
    }

    function initBorrowYieldAccumulator(address issuer)
        external
        onlyOwnerExecActivator
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        require(yA.accumulatorFP == 0, "don't re-initialize");

        yA.accumulatorFP = FP32;
        yA.lastUpdated = block.timestamp;
        yA.hourlyYieldFP = FP32 + FP32 / (365 * 24);
    }

    function setBorrowingFactorPercent(uint256 borrowingFactor)
        external
        onlyOwnerExec
    {
        borrowingFactorPercent = borrowingFactor;
    }

    function issuanceBalance(address issuer)
        internal
        view
        override
        returns (uint256)
    {
        address token = issuerTokens[issuer];
        if (token == issuer) {
            // cross margin
            return IERC20(token).balanceOf(fund());
        } else {
            return lendingMeta[issuer].totalLending - haircuts[issuer];
        }
    }

    function disburse(
        address issuer,
        address recipient,
        uint256 amount
    ) internal {
        uint256 haircutAmount = haircuts[issuer];
        if (haircutAmount > 0 && amount > 0) {
            uint256 totalLending = lendingMeta[issuer].totalLending;
            uint256 adjustment =
                (amount * min(totalLending, haircutAmount)) / totalLending;
            amount = amount - adjustment;
            haircuts[issuer] -= adjustment;
        }

        address token = issuerTokens[issuer];
        Fund(fund()).withdraw(token, recipient, amount);
    }

    function collectToken(
        address issuer,
        address source,
        uint256 amount
    ) internal {
        Fund(fund()).depositFor(source, issuer, amount);
    }

    function haircut(uint256 amount) external {
        haircuts[msg.sender] += amount;
    }
}
