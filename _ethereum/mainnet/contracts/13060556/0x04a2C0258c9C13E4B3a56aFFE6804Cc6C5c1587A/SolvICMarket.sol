// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./VNFTTransferHelper.sol";
import "./ERC20TransferHelper.sol";
import "./IVNFT.sol";
import "./ISolver.sol";
import "./IUnderlyingContainer.sol";
import "./ISolvICMarket.sol";
import "./PriceManager.sol";
import "./SafeMathUpgradeable128.sol";

contract SolvICMarket is ISolvICMarket, PriceManager {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable128 for uint128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewSolver(ISolver oldSolver, ISolver newSolver);

    event AddMarket(
        address indexed icToken,
        uint64 precision,
        uint8 feePayType,
        uint8 feeType,
        uint128 feeAmount,
        uint16 feeRate
    );

    event RemoveMarket(address indexed icToken);

    event SetCurrency(address indexed currency, bool enable);

    event WithdrawFee(address icToken, uint256 reduceAmount);

    struct Sale {
        uint24 saleId;
        uint24 tokenId;
        uint32 startTime;
        address seller;
        PriceManager.PriceType priceType;
        uint128 total; //sale units
        uint128 units; //current units
        uint128 min; //min units
        uint128 max; //max units
        address icToken; //sale asset
        address currency; //pay currency
        bool useAllowList;
        bool isValid;
    }

    struct Market {
        bool isValid;
        uint64 precision;
        FeeType feeType;
        FeePayType feePayType;
        uint128 feeAmount;
        uint16 feeRate;
    }

    enum FeeType {
        BY_AMOUNT,
        FIXED
    }

    enum FeePayType {
        SELLER_PAY,
        BUYER_PAY
    }

    //saleId => struct Sale
    mapping(uint24 => Sale) public sales;

    //icToken => Market
    mapping(address => Market) public markets;

    mapping(address => bool) public currencies;

    //icToken => saleId
    mapping(address => EnumerableSetUpgradeable.UintSet) internal _icTokenSales;
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal _allowAddresses;

    ISolver public solver;
    uint24 public nextSaleId;
    address payable public pendingAdmin;
    uint24 public nextTradeId;
    address payable public admin;
    bool public initialized;
    uint16 internal constant PERCENTAGE_BASE = 10000;

    // managers with authorities to set allow addresses of a voucher market
    mapping(address => EnumerableSetUpgradeable.AddressSet) internal allowAddressManagers;

    // records of user purchased units from an order
    mapping(uint24 => mapping(address => uint128)) internal saleRecords;

    uint16 public repoFeeRate;

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyAllowAddressManager(address icToken_) {
        require(msg.sender == admin || allowAddressManagers[icToken_].contains(msg.sender), "only manager");
        _;
    }

    constructor() {}

    function initialize(ISolver solver_) public {
        require(initialized == false, "already initialized");
        admin = msg.sender;
        nextSaleId = 1;
        nextTradeId = 1;
        _setSolver(solver_);
        initialized = true;
    }

    function publishFixedPrice(
        address icToken_,
        uint24 tokenId_,
        address currency_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_,
        uint128 price_
    ) external virtual override returns (uint24 saleId) {
        address seller = msg.sender;

        uint256 err = solver.publishFixedPriceAllowed(
            icToken_,
            tokenId_,
            seller,
            currency_,
            min_,
            max_,
            startTime_,
            useAllowList_,
            price_
        );
        require(err == 0, "Solver: not allowed");

        PriceManager.PriceType priceType = PriceManager.PriceType.FIXED;
        saleId = _publish(
            seller,
            icToken_,
            tokenId_,
            currency_,
            priceType,
            min_,
            max_,
            startTime_,
            useAllowList_
        );
        PriceManager.setFixedPrice(saleId, price_);

        emit FixedPriceSet(
            icToken_,
            saleId,
            tokenId_,
            uint8(priceType),
            price_
        );
    }

    struct PublishDecliningPriceLocalVars {
        address icToken;
        uint24 tokenId;
        address currency;
        uint128 min;
        uint128 max;
        uint32 startTime;
        bool useAllowList;
        uint128 highest;
        uint128 lowest;
        uint32 duration;
        uint32 interval;
        address seller;
    }

    function publishDecliningPrice(
        address icToken_,
        uint24 tokenId_,
        address currency_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_,
        uint128 highest_,
        uint128 lowest_,
        uint32 duration_,
        uint32 interval_
    ) external virtual override returns (uint24 saleId) {
        PublishDecliningPriceLocalVars memory vars;
        vars.seller = msg.sender;
        vars.icToken = icToken_;
        vars.tokenId = tokenId_;
        vars.currency = currency_;
        vars.min = min_;
        vars.max = max_;
        vars.startTime = startTime_;
        vars.useAllowList = useAllowList_;
        vars.highest = highest_;
        vars.lowest = lowest_;
        vars.duration = duration_;
        vars.interval = interval_;

        require(vars.interval > 0, "interval cannot be 0");
        require(vars.lowest <= vars.highest, "lowest > highest");
        require(vars.duration > 0, "duration cannot be 0");

        uint256 err = solver.publishDecliningPriceAllowed(
            vars.icToken,
            vars.tokenId,
            vars.seller,
            vars.currency,
            vars.min,
            vars.max,
            vars.startTime,
            vars.useAllowList,
            vars.highest,
            vars.lowest,
            vars.duration,
            vars.interval
        );
        require(err == 0, "Solver: not allowed");

        PriceManager.PriceType priceType = PriceManager
        .PriceType
        .DECLIINING_BY_TIME;
        saleId = _publish(
            vars.seller,
            vars.icToken,
            vars.tokenId,
            vars.currency,
            priceType,
            vars.min,
            vars.max,
            vars.startTime,
            vars.useAllowList
        );

        PriceManager.setDecliningPrice(
            saleId,
            vars.startTime,
            vars.highest,
            vars.lowest,
            vars.duration,
            vars.interval
        );

        emit DecliningPriceSet(
            vars.icToken,
            saleId,
            vars.tokenId,
            vars.highest,
            vars.lowest,
            vars.duration,
            vars.interval
        );
    }

    function _publish(
        address seller_,
        address icToken_,
        uint24 tokenId_,
        address currency_,
        PriceManager.PriceType priceType_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        bool useAllowList_
    ) internal returns (uint24 saleId) {
        require(markets[icToken_].isValid, "unsupported icToken");
        require(currencies[currency_] || currency_ == IUnderlyingContainer(icToken_).underlying(), "unsupported currency");
        if (max_ > 0) {
            require(min_ <= max_, "min > max");
        }

        IVNFT vnft = IVNFT(icToken_);

        VNFTTransferHelper.doTransferIn(icToken_, seller_, tokenId_);

        saleId = _generateNextSaleId();
        uint256 units = vnft.unitsInToken(tokenId_);
        require(units <= uint128(-1), "exceeds uint128 max");
        sales[saleId] = Sale({
            saleId: saleId,
            seller: msg.sender,
            tokenId: tokenId_,
            total: uint128(units),
            units: uint128(units),
            startTime: startTime_,
            min: min_,
            max: max_,
            icToken: icToken_,
            currency: currency_,
            priceType: priceType_,
            useAllowList: useAllowList_,
            isValid: true
        });
        Sale storage sale = sales[saleId];
        _icTokenSales[icToken_].add(saleId);
        emit Publish(
            sale.icToken,
            sale.seller,
            sale.tokenId,
            saleId,
            uint8(sale.priceType),
            sale.units,
            sale.startTime,
            sale.currency,
            sale.min,
            sale.max,
            sale.useAllowList
        );
        solver.publishVerify(
            sale.icToken,
            sale.tokenId,
            sale.seller,
            sale.currency,
            sale.saleId,
            sale.units
        );

        return saleId;
    }

    function buyByAmount(uint24 saleId_, uint256 amount_)
        external
        payable
        virtual
        override
        returns (uint128 units_)
    {
        Sale storage sale = sales[saleId_];
        address buyer = msg.sender;
        uint128 fee = _getFee(sale.icToken, sale.currency, amount_);
        uint128 price = PriceManager.price(sale.priceType, sale.saleId);
        uint256 units256;
        if (markets[sale.icToken].feePayType == FeePayType.BUYER_PAY) {
            units256 = amount_
            .sub(fee, "fee exceeds amount")
            .mul(uint256(markets[sale.icToken].precision))
            .div(uint256(price));
        } else {
            units256 = amount_
            .mul(uint256(markets[sale.icToken].precision))
            .div(uint256(price));
        }
        require(units256 <= uint128(-1), "exceeds uint128 max");
        units_ = uint128(units256);

        uint256 err = solver.buyAllowed(
            sale.icToken,
            sale.tokenId,
            saleId_,
            buyer,
            sale.currency,
            amount_,
            units_,
            price
        );
        require(err == 0, "Solver: not allowed");

        _buy(buyer, sale, amount_, units_, price, fee);
        return units_;
    }

    function buyByUnits(uint24 saleId_, uint128 units_)
        external
        payable
        virtual
        override
        returns (uint256 amount_, uint128 fee_)
    {
        Sale storage sale = sales[saleId_];
        address buyer = msg.sender;
        uint128 price = PriceManager.price(sale.priceType, sale.saleId);

        amount_ = uint256(units_).mul(uint256(price)).div(
            uint256(markets[sale.icToken].precision)
        );

        if (
            sale.currency == EthAddressLib.ethAddress() &&
            sale.priceType == PriceType.DECLIINING_BY_TIME &&
            amount_ != msg.value
        ) {
            amount_ = msg.value;
            uint128 fee = _getFee(sale.icToken, sale.currency, amount_);
            uint256 units256;
            if (markets[sale.icToken].feePayType == FeePayType.BUYER_PAY) {
                units256 = amount_
                .sub(fee, "fee exceeds amount")
                .mul(uint256(markets[sale.icToken].precision))
                .div(uint256(price));
            } else {
                units256 = amount_
                .mul(uint256(markets[sale.icToken].precision))
                .div(uint256(price));
            }
            require(units256 <= uint128(-1), "exceeds uint128 max");
            units_ = uint128(units256);
        }

        fee_ = _getFee(sale.icToken, sale.currency, amount_);

        uint256 err = solver.buyAllowed(
            sale.icToken,
            sale.tokenId,
            saleId_,
            buyer,
            sale.currency,
            amount_,
            units_,
            price
        );
        require(err == 0, "Solver: not allowed");

        _buy(buyer, sale, amount_, units_, price, fee_);
        return (amount_, fee_);
    }

    struct BuyLocalVar {
        uint256 transferInAmount;
        uint256 transferOutAmount;
        FeePayType feePayType;
    }

    function _buy(
        address buyer_,
        Sale storage sale_,
        uint256 amount_,
        uint128 units_,
        uint128 price_,
        uint128 fee_
    ) internal {
        require(sale_.isValid, "invalid saleId");
        require(block.timestamp >= sale_.startTime, "not yet on sale");
        if (sale_.units >= sale_.min) {
            require(units_ >= sale_.min, "min units not met");
        }
        if (sale_.max > 0) {
            uint128 purchased = saleRecords[sale_.saleId][buyer_].add(units_);
            require(purchased <= sale_.max, "exceeds purchase limit");
            saleRecords[sale_.saleId][buyer_] = purchased;
        }

        if (sale_.useAllowList) {
            require(
                _allowAddresses[sale_.icToken].contains(buyer_),
                "not in allow list"
            );
        }

        sale_.units = sale_.units.sub(units_, "insufficient units for sale");
        BuyLocalVar memory vars;
        vars.feePayType = markets[sale_.icToken].feePayType;

        if (vars.feePayType == FeePayType.BUYER_PAY) {
            vars.transferInAmount = amount_.add(fee_);
            vars.transferOutAmount = amount_;
        } else if (vars.feePayType == FeePayType.SELLER_PAY) {
            vars.transferInAmount = amount_;
            vars.transferOutAmount = amount_.sub(fee_, "fee exceeds amount");
        } else {
            revert("unsupported feePayType");
        }

        ERC20TransferHelper.doTransferIn(
            sale_.currency,
            buyer_,
            vars.transferInAmount
        );
        if (units_ == IVNFT(sale_.icToken).unitsInToken(sale_.tokenId)) {
            VNFTTransferHelper.doTransferOut(
                sale_.icToken,
                buyer_,
                sale_.tokenId
            );
        } else {
            VNFTTransferHelper.doTransferOut(
                sale_.icToken,
                buyer_,
                sale_.tokenId,
                units_
            );
        }

        ERC20TransferHelper.doTransferOut(
            sale_.currency,
            payable(sale_.seller),
            vars.transferOutAmount
        );

        emit Traded(
            buyer_,
            sale_.saleId,
            sale_.icToken,
            sale_.tokenId,
            _generateNextTradeId(),
            uint32(block.timestamp),
            sale_.currency,
            uint8(sale_.priceType),
            price_,
            units_,
            amount_,
            uint8(vars.feePayType),
            fee_
        );

        solver.buyVerify(
            sale_.icToken,
            sale_.tokenId,
            sale_.saleId,
            buyer_,
            sale_.seller,
            amount_,
            units_,
            price_,
            fee_
        );

        if (sale_.units == 0) {
            emit Remove(
                sale_.icToken,
                sale_.seller,
                sale_.saleId,
                sale_.total,
                sale_.total - sale_.units
            );
            delete sales[sale_.saleId];
        }
    }

    function purchasedUnits(uint24 saleId_, address buyer_) external view returns(uint128) {
        return saleRecords[saleId_][buyer_];
    }

    function remove(uint24 saleId_) public virtual override {
        Sale memory sale = sales[saleId_];
        require(sale.isValid, "invalid sale");
        require(sale.seller == msg.sender, "only seller");

        uint256 err = solver.removeAllow(
            sale.icToken,
            sale.tokenId,
            sale.saleId,
            sale.seller
        );
        require(err == 0, "Solver: not allowed");

        VNFTTransferHelper.doTransferOut(
            sale.icToken,
            sale.seller,
            sale.tokenId
        );

        delete sales[saleId_];
        emit Remove(
            sale.icToken,
            sale.seller,
            sale.saleId,
            sale.total,
            sale.total - sale.units
        );
    }

    function _getFee(address icToken_, address currency_, uint256 amount)
        internal
        view
        returns (uint128)
    {
        if (currency_ == IUnderlyingContainer(icToken_).underlying()) {
            uint256 fee = amount.mul(uint256(repoFeeRate)).div(PERCENTAGE_BASE);
            require(fee <= uint128(-1), "Fee: exceeds uint128 max");
            return uint128(fee);
        }

        Market storage market = markets[icToken_];
        if (market.feeType == FeeType.FIXED) {
            return market.feeAmount;
        } else if (market.feeType == FeeType.BY_AMOUNT) {
            uint256 fee = amount.mul(uint256(market.feeRate)).div(
                uint256(PERCENTAGE_BASE)
            );
            require(fee <= uint128(-1), "Fee: exceeds uint128 max");
            return uint128(fee);
        } else {
            revert("unsupported feeType");
        }
    }

    function getPrice(uint24 saleId_)
        public
        view
        virtual
        override
        returns (uint128)
    {
        return PriceManager.price(sales[saleId_].priceType, saleId_);
    }

    function totalSalesOfICToken(address icToken_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _icTokenSales[icToken_].length();
    }

    function saleIdOfICTokenByIndex(address icToken_, uint256 index_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _icTokenSales[icToken_].at(index_);
    }

    function _generateNextSaleId() internal returns (uint24) {
        return nextSaleId++;
    }

    function _generateNextTradeId() internal returns (uint24) {
        return nextTradeId++;
    }

    function _addMarket(
        address icToken_,
        uint64 precision_,
        uint8 feePayType_,
        uint8 feeType_,
        uint128 feeAmount_,
        uint16 feeRate_
    ) public onlyAdmin {
        markets[icToken_].isValid = true;
        markets[icToken_].precision = precision_;
        markets[icToken_].feePayType = FeePayType(feePayType_);
        markets[icToken_].feeType = FeeType(feeType_);
        markets[icToken_].feeAmount = feeAmount_;
        markets[icToken_].feeRate = feeRate_;

        emit AddMarket(
            icToken_,
            precision_,
            feePayType_,
            feeType_,
            feeAmount_,
            feeRate_
        );
    }

    function _removeMarket(address icToken_) public onlyAdmin {
        delete markets[icToken_];
        emit RemoveMarket(icToken_);
    }

    function _setCurrency(address currency_, bool enable_) public onlyAdmin {
        currencies[currency_] = enable_;
        emit SetCurrency(currency_, enable_);
    }

    function _setRepoFeeRate(uint16 newRepoFeeRate_) external onlyAdmin {
        repoFeeRate = newRepoFeeRate_;
    }

    function _withdrawFee(address icToken_, uint256 reduceAmount_)
        public
        onlyAdmin
    {
        require(
            ERC20TransferHelper.getCashPrior(icToken_) >= reduceAmount_,
            "insufficient cash"
        );
        ERC20TransferHelper.doTransferOut(icToken_, admin, reduceAmount_);
        emit WithdrawFee(icToken_, reduceAmount_);
    }

    function _addAllowAddress(
        address icToken_, 
        address[] calldata addresses_,
        bool resetExisting_
    ) external onlyAllowAddressManager(icToken_) {
        require(markets[icToken_].isValid, "unsupported icToken");
        EnumerableSetUpgradeable.AddressSet storage set = _allowAddresses[icToken_];

        if (resetExisting_) {
            while (set.length() != 0) {
                set.remove(set.at(0));
            }
        }

        for (uint256 i = 0; i < addresses_.length; i++) {
            set.add(addresses_[i]);
        }
    }

    function _removeAllowAddress(
        address icToken_,
        address[] calldata addresses_
    ) external onlyAllowAddressManager(icToken_) {
        require(markets[icToken_].isValid, "unsupported icToken");
        EnumerableSetUpgradeable.AddressSet storage set = _allowAddresses[icToken_];
        for (uint256 i = 0; i < addresses_.length; i++) {
            set.remove(addresses_[i]);
        }
    }

    function isBuyerAllowed(address icToken_, address buyer_) external view returns (bool) {
        return _allowAddresses[icToken_].contains(buyer_);
    }

    function setAllowAddressManager(
        address icToken_, 
        address[] calldata managers_, 
        bool resetExisting_
    ) external onlyAdmin {
        require(markets[icToken_].isValid, "unsupported icToken");
        EnumerableSetUpgradeable.AddressSet storage set = allowAddressManagers[icToken_];
        if (resetExisting_) {
            while (set.length() != 0) {
                set.remove(set.at(0));
            }
        }

        for (uint256 i = 0; i < managers_.length; i++) {
            set.add(managers_[i]);
        }
    }

    function allowAddressManager(address icToken_, uint256 index_) external view returns(address) {
        return allowAddressManagers[icToken_].at(index_);
    }

    function _setSolver(ISolver newSolver_) public virtual onlyAdmin {
        ISolver oldSolver = solver;
        require(newSolver_.isSolver(), "invalid solver");
        solver = newSolver_;

        emit NewSolver(oldSolver, newSolver_);
    }

    function _setPendingAdmin(address payable newPendingAdmin) public {
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
