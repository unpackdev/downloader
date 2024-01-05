// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Initializable.sol";
import "./ISolver.sol";

contract Solver is ISolver, Initializable {
    address public admin;
    address public pendingAdmin;

    mapping(address => bool) public transferGuardianPaused;
    mapping(address => bool) public depositGuardianPaused;
    mapping(address => bool) public withdrawGuardianPaused;

    mapping(address => bool) public convertUnsafeTransferContracts;
    mapping(address => bool) public rejectUnsafeTransferContracts;

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    function initialize() public initializer {
        admin = msg.sender;
    }

    function isSolver() external pure override returns (bool) {
        return true;
    }

    function _setTransferGuuardianPause(address product, bool enable)
        public
        onlyAdmin
    {
        transferGuardianPaused[product] = enable;
    }

    function _setDepositGuuardianPause(address product, bool enable)
        public
        onlyAdmin
    {
        depositGuardianPaused[product] = enable;
    }

    function _setWithdrawGuuardianPause(address product, bool enable)
        public
        onlyAdmin
    {
        withdrawGuardianPaused[product] = enable;
    }

    function _setConvertUnsafeTransferContracts(address product, bool enable)
        public
        onlyAdmin
    {
        convertUnsafeTransferContracts[product] = enable;
    }

    function _setRejectUnsafeTransferContracts(address product, bool enable)
        public
        onlyAdmin
    {
        rejectUnsafeTransferContracts[product] = enable;
    }

    function depositAllowed(
        address product,
        address depositor,
        uint64 term,
        uint256 depositAmount,
        uint64[] calldata maturities
    ) external override returns (uint256) {
        //reserve vars
        product;
        depositor;
        term;
        depositAmount;
        maturities;

        require(!depositGuardianPaused[product], "deposit is paused");

        return 0;
    }

    function depositVerify(
        address product,
        address depositor,
        uint256 depositAmount,
        uint256 tokenId,
        uint64 term,
        uint64[] calldata maturities
    ) external override returns (uint256) {
        product;
        depositor;
        depositAmount;
        tokenId;
        term;
        maturities;

        return 0;
    }

    function withdrawAllowed(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external override returns (uint256) {
        //reserve
        product;
        payee;
        withdrawAmount;
        tokenId;
        term;
        maturity;

        require(!withdrawGuardianPaused[product], "withdraw is paused");

        return 0;
    }

    function withdrawVerify(
        address product,
        address payee,
        uint256 withdrawAmount,
        uint256 tokenId,
        uint64 term,
        uint64 maturity
    ) external override returns (uint256) {
        //reserve
        product;
        payee;
        withdrawAmount;
        tokenId;
        term;
        maturity;

        return 0;
    }

    function transferFromAllowed(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        from;
        to;
        tokenId;
        amount;
        targetTokenId;

        require(!transferGuardianPaused[product], "transfer is paused");
        return 0;
    }

    function transferFromVerify(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        from;
        to;
        tokenId;
        targetTokenId;
        amount;

        return 0;
    }

    function mergeAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        owner;
        tokenId;
        targetTokenId;
        amount;
        return 0;
    }

    function mergeVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 targetTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        owner;
        tokenId;
        targetTokenId;
        amount;
        return 0;
    }

    function splitAllowed(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        owner;
        tokenId;
        newTokenId;
        amount;
        return 0;
    }

    function splitVerify(
        address product,
        address owner,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    ) external override returns (uint256) {
        //reserve vars
        product;
        owner;
        tokenId;
        newTokenId;
        amount;
        return 0;
    }

    function publishFixedPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 price
    ) external override returns (uint256) {
        //reserve vars
        icToken;
        tokenId;
        seller;
        currency;
        min;
        max;
        startTime;
        useAllowList;
        price;

        return 0;
    }

    function publishDecliningPriceAllowed(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 min,
        uint256 max,
        uint256 startTime,
        bool useAllowList,
        uint256 highest,
        uint256 lowest,
        uint256 duration,
        uint256 interval
    ) external override returns (uint256) {
        //reserve vars
        icToken;
        tokenId;
        seller;
        currency;
        min;
        max;
        startTime;
        useAllowList;
        highest;
        lowest;
        duration;
        interval;

        return 0;
    }

    function publishVerify(
        address icToken,
        uint256 tokenId,
        address seller,
        address currency,
        uint256 saleId,
        uint256 units
    ) external override {
        //reserve vars
        icToken;
        tokenId;
        seller;
        currency;
        saleId;
        units;
    }

    function buyAllowed(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address currency,
        uint256 buyAmount,
        uint256 buyUnits,
        uint256 price
    ) external override returns (uint256) {
        //reserve vars
        icToken;
        tokenId;
        saleId;
        buyer;
        currency;
        buyAmount;
        buyUnits;
        price;

        return 0;
    }

    function buyVerify(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address buyer,
        address seller,
        uint256 amount,
        uint256 units,
        uint256 price,
        uint256 fee
    ) external override {
        //reserve
        icToken;
        tokenId;
        saleId;
        buyer;
        seller;
        amount;
        units;
        price;
        fee;
    }

    function removeAllow(
        address icToken,
        uint256 tokenId,
        uint256 saleId,
        address seller
    ) external override returns (uint256) {
        //reserve vars
        icToken;
        tokenId;
        saleId;
        seller;

        return 0;
    }

    function needConvertUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) public view override returns (bool) {
        //reserve vars
        product;
        from;
        tokenId;
        units;
        return convertUnsafeTransferContracts[to];
    }

    function needRejectUnsafeTransfer(
        address product,
        address from,
        address to,
        uint256 tokenId,
        uint256 units
    ) public view override returns (bool) {
        //reserve vars
        product;
        from;
        tokenId;
        units;
        return rejectUnsafeTransferContracts[to];
    }

    function _setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "only admin");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function _acceptAdmin() public {
        require(
            msg.sender == pendingAdmin && msg.sender != address(0),
            "only pending admin"
        );

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}
