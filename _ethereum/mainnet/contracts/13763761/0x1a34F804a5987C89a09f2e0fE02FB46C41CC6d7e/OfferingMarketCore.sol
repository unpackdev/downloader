// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./Constants.sol";
import "./AdminControl.sol";
import "./SafeMathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeMathUpgradeable128.sol";
import "./VNFTTransferHelper.sol";
import "./ERC20TransferHelper.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ISolver.sol";
import "./PriceManager.sol";

abstract contract OfferingMarketCore is
    PriceManager,
    AdminControl,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable128 for uint128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event AddMarket(
        address indexed voucher,
        Constants.VoucherType voucherType,
        address asset,
        uint8 decimals,
        uint16 feeRate,
        bool onlyManangerOffer
    );

    event RemoveMarket(address indexed voucher);

    event Offer(
        address indexed voucher,
        address indexed issuer,
        Offering offering
    );

    event Remove(
        address indexed issuer,
        uint24 indexed offeringId,
        address voucher,
        uint128 total,
        uint128 sold
    );

    event FixedPriceSet(
        address indexed voucher,
        uint24 indexed offeringId,
        uint8 priceType,
        uint128 lastPrice
    );

    event DecliningPriceSet(
        address indexed voucher,
        uint24 indexed offeringId,
        uint128 highest,
        uint128 lowest,
        uint32 duration,
        uint32 interval
    );

    event Traded(
        address indexed buyer,
        uint24 indexed offeringId,
        address indexed voucher,
        uint256 voucherId,
        uint24 tradeId,
        uint32 tradeTime,
        address currency,
        uint8 priceType,
        uint128 price,
        uint128 tradedUnits,
        uint256 tradedAmount,
        uint128 fee
    );

    event SetCurrency(address indexed currency, bool enable);

    event WithdrawFee(address voucher, uint256 reduceAmount);

    event NewSolver(ISolver oldSolver, ISolver newSolver);

    struct Market {
        Constants.VoucherType voucherType;
        address voucherPool;
        address asset;
        uint8 decimals;
        uint16 feeRate;
        bool onlyManangerOffer;
        bool isValid;
    }

    struct Offering {
        uint24 offeringId;
        uint32 startTime;
        uint32 endTime;
        PriceManager.PriceType priceType;
        uint128 totalUnits;
        uint128 units;
        uint128 min;
        uint128 max;
        address voucher;
        address currency;
        address issuer;
        bool useAllowList;
        bool isValid;
    }

    //key: offeringId
    mapping(uint24 => Offering) public offerings;

    //key: voucher
    mapping(address => Market) public markets;

    EnumerableSetUpgradeable.AddressSet internal _currencies;
    EnumerableSetUpgradeable.AddressSet internal _vouchers;

    //voucher => offeringId
    mapping(address => EnumerableSetUpgradeable.UintSet)
        internal _voucherOfferings;

    mapping(address => EnumerableSetUpgradeable.AddressSet)
        internal _allowAddresses;

    // managers with authorities to set allow addresses of a voucher market and offer offering
    mapping(address => EnumerableSetUpgradeable.AddressSet)
        internal _voucherManagers;

    // records of user purchased units from an order
    mapping(uint24 => mapping(address => uint128)) internal _tradeRecords;

    ISolver public solver;
    uint24 public nextOfferingId;
    uint24 public nextTradeId;

    modifier onlyVoucherManager(address voucher_) {
        require(
            msg.sender == admin ||
                _voucherManagers[voucher_].contains(msg.sender),
            "only manager"
        );
        _;
    }

    function _mintVoucher(uint24 oferingId, uint128 units)
        internal
        virtual
        returns (uint256 voucherId);

    function _refund(uint24 offeringId, uint128 units) internal virtual;

    function isSupportVoucherType(Constants.VoucherType voucherType)
        public
        virtual
        returns (bool);

    function initialize(ISolver solver_) external initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AdminControl.__AdminControl_init(msg.sender);
        nextOfferingId = 1;
        nextTradeId = 1;
        setSolver(solver_);
    }

    function _offer(
        address voucher_,
        address currency_,
        uint128 units_,
        uint128 min_,
        uint128 max_,
        uint32 startTime_,
        uint32 endTime_,
        bool useAllowList_,
        PriceManager.PriceType priceType_,
        bytes memory priceData_
    ) internal nonReentrant returns (uint24 offeringId) {
        require(
            voucher_ != address(0) && currency_ != address(0),
            "address cannot be 0"
        );
        Market memory market = markets[voucher_];
        require(market.isValid, "unsupported voucher");
        require(_currencies.contains(currency_), "unsupported currency");
        require(endTime_ > startTime_, "endTime less than startTime");

        if (market.onlyManangerOffer) {
            require(
                _voucherManagers[voucher_].contains(msg.sender),
                "only manager"
            );
        }

        if (max_ > 0) {
            require(min_ <= max_, "min > max");
        }

        uint256 err = solver.operationAllowed(
            "Offer",
            abi.encode(
                voucher_,
                msg.sender,
                currency_,
                units_,
                min_,
                max_,
                startTime_,
                endTime_,
                useAllowList_,
                priceType_,
                priceData_
            )
        );
        require(err == 0, "solver not allowed");

        offeringId = _generateNextofferingId();

        offerings[offeringId] = Offering({
            offeringId: offeringId,
            startTime: startTime_,
            endTime: endTime_,
            priceType: priceType_,
            totalUnits: units_,
            units: units_,
            min: min_,
            max: max_,
            currency: currency_,
            issuer: msg.sender,
            voucher: voucher_,
            useAllowList: useAllowList_,
            isValid: true
        });

        Offering memory offering = offerings[offeringId];

        _setPrice(offering, priceType_, priceData_);

        solver.operationVerify(
            "Offer",
            abi.encode(offering.voucher, offering.offeringId)
        );
        emit Offer(offering.voucher, offering.issuer, offering);

        return offeringId;
    }

    function _setPrice(
        Offering memory offering_,
        PriceManager.PriceType priceType_,
        bytes memory priceData_
    ) internal {
        if (priceType_ == PriceManager.PriceType.FIXED) {
            uint128 price = abi.decode(priceData_, (uint128));
            PriceManager.setFixedPrice(offering_.offeringId, price);

            emit FixedPriceSet(
                offering_.voucher,
                offering_.offeringId,
                uint8(priceType_),
                price
            );
        } else {
            (
                uint128 highest,
                uint128 lowest,
                uint32 duration,
                uint32 interval
            ) = abi.decode(priceData_, (uint128, uint128, uint32, uint32));
            PriceManager.setDecliningPrice(
                offering_.offeringId,
                offering_.startTime,
                highest,
                lowest,
                duration,
                interval
            );

            emit DecliningPriceSet(
                offering_.voucher,
                offering_.offeringId,
                highest,
                lowest,
                duration,
                interval
            );
        }
    }

    function buy(uint24 offeringId_, uint128 units_)
        external
        payable
        virtual
        nonReentrant
        returns (uint256 amount_, uint128 fee_)
    {
        address buyer = msg.sender;
        uint128 price = getPrice(offeringId_);
        Offering storage offering = offerings[offeringId_];
        require(offering.isValid, "invalid offering");

        Market memory market = markets[offering.voucher];
        require(market.isValid, "invalid market");
        amount_ = uint256(units_).mul(uint256(price)).div(
            uint256(10**market.decimals)
        );

        if (
            offering.currency == Constants.ETH_ADDRESS &&
            offering.priceType == PriceType.DECLIINING_BY_TIME &&
            amount_ != msg.value
        ) {
            amount_ = msg.value;
            uint256 units256 = amount_.mul(uint256(10**market.decimals)).div(
                uint256(price)
            );
            require(units256 <= uint128(-1), "exceeds uint128 max");
            units_ = uint128(units256);
        }

        fee_ = _getFee(offering.voucher, amount_);

        uint256 err = solver.operationAllowed(
            "Buy",
            abi.encode(
                offering.voucher,
                offeringId_,
                buyer,
                amount_,
                units_,
                price
            )
        );
        require(err == 0, "Solver: not allowed");

        BuyParameter memory buyParameter = BuyParameter({
            buyer: buyer,
            amount: amount_,
            units: units_,
            price: price,
            fee: fee_
        });
        _buy(offering, buyParameter);
        return (amount_, fee_);
    }

    struct BuyLocalVar {
        uint256 transferInAmount;
        uint256 transferOutAmount;
    }

    struct BuyParameter {
        address buyer;
        uint256 amount;
        uint128 units;
        uint128 price;
        uint128 fee;
    }

    function _buy(Offering storage offering_, BuyParameter memory parameter_)
        internal
    {
        require(offering_.isValid, "offering invalid");
        require(offering_.units > 0, "sold out");
        require(
            block.timestamp >= offering_.startTime &&
                block.timestamp <= offering_.endTime,
            "not offering time"
        );
        if (offering_.useAllowList) {
            require(
                _allowAddresses[offering_.voucher].contains(parameter_.buyer),
                "not in allow list"
            );
        }
        if (offering_.units >= offering_.min) {
            require(parameter_.units >= offering_.min, "min amount not met");
        }
        if (offering_.max > 0) {
            uint128 purchased = _tradeRecords[offering_.offeringId][
                parameter_.buyer
            ].add(parameter_.units);
            require(purchased <= offering_.max, "exceeds purchase limit");
            _tradeRecords[offering_.offeringId][parameter_.buyer] = purchased;
        }

        offering_.units = offering_.units.sub(
            parameter_.units,
            "insufficient units for sale"
        );
        BuyLocalVar memory vars;

        vars.transferInAmount = parameter_.amount;
        vars.transferOutAmount = parameter_.amount.sub(
            parameter_.fee,
            "fee exceeds amount"
        );

        uint256 voucherId = _transferAsset(
            offering_,
            parameter_.buyer,
            vars.transferInAmount,
            parameter_.units,
            vars.transferOutAmount
        );

        solver.operationVerify(
            "Buy",
            abi.encode(
                offering_.offeringId,
                parameter_.buyer,
                parameter_.amount,
                parameter_.units,
                parameter_.fee
            )
        );

        emit Traded(
            parameter_.buyer,
            offering_.offeringId,
            offering_.voucher,
            voucherId,
            _generateNextTradeId(),
            uint32(block.timestamp),
            offering_.currency,
            uint8(offering_.priceType),
            parameter_.price,
            parameter_.units,
            parameter_.amount,
            parameter_.fee
        );
    }

    function _transferAsset(
        Offering memory offering_,
        address buyer_,
        uint256 transferInAmount_,
        uint128 transferOutUnits_,
        uint256 transferOutAmount_
    ) internal returns (uint256 voucherId) {
        ERC20TransferHelper.doTransferIn(
            offering_.currency,
            buyer_,
            transferInAmount_
        );

        voucherId = _mintVoucher(offering_.offeringId, transferOutUnits_);

        VNFTTransferHelper.doTransferOut(offering_.voucher, buyer_, voucherId);

        ERC20TransferHelper.doTransferOut(
            offering_.currency,
            payable(offering_.issuer),
            transferOutAmount_
        );
    }

    function purchasedUnits(uint24 offeringId_, address buyer_)
        external
        view
        returns (uint128)
    {
        return _tradeRecords[offeringId_][buyer_];
    }

    function remove(uint24 offeringId_) external virtual nonReentrant {
        Offering memory offering = offerings[offeringId_];
        require(offering.isValid, "invalid offering");
        require(offering.issuer == msg.sender, "only issuer");
        require(
            block.timestamp < offering.startTime ||
                block.timestamp > offering.endTime,
            "offering processing"
        );

        uint256 err = solver.operationAllowed(
            "Remove",
            abi.encode(offering.voucher, offering.offeringId, offering.issuer)
        );
        require(err == 0, "Solver: not allowed");

        _refund(offeringId_, offering.units);

        emit Remove(
            offering.issuer,
            offering.offeringId,
            offering.voucher,
            offering.totalUnits,
            offering.totalUnits - offering.units
        );
        delete offerings[offeringId_];
    }

    function _getFee(address voucher_, uint256 amount)
        internal
        view
        returns (uint128)
    {
        Market storage market = markets[voucher_];

        uint256 fee = amount.mul(uint256(market.feeRate)).div(
            uint256(Constants.FULL_PERCENTAGE)
        );
        require(fee <= uint128(-1), "Fee: exceeds uint128 max");
        return uint128(fee);
    }

    function getPrice(uint24 offeringId_)
        public
        view
        virtual
        returns (uint128)
    {
        return
            PriceManager.price(offerings[offeringId_].priceType, offeringId_);
    }

    function totalOfferingsOfvoucher(address voucher_)
        external
        view
        virtual
        returns (uint256)
    {
        return _voucherOfferings[voucher_].length();
    }

    function offeringIdOfvoucherByIndex(address voucher_, uint256 index_)
        external
        view
        virtual
        returns (uint256)
    {
        return _voucherOfferings[voucher_].at(index_);
    }

    function _generateNextofferingId() internal returns (uint24) {
        return nextOfferingId++;
    }

    function _generateNextTradeId() internal returns (uint24) {
        return nextTradeId++;
    }

    function addMarket(
        address voucher_,
        address voucherPool_,
        Constants.VoucherType voucherType_,
        address asset_,
        uint8 decimals_,
        uint16 feeRate_,
        bool onlyManangerOffer_
    ) external onlyAdmin {
        if (_vouchers.contains(voucher_)) {
            revert("already added");
        }
        require(isSupportVoucherType(voucherType_), "unsupported voucher type");
        require(feeRate_ <= Constants.FULL_PERCENTAGE, "invalid fee rate");
        markets[voucher_].voucherPool = voucherPool_;
        markets[voucher_].isValid = true;
        markets[voucher_].decimals = decimals_;
        markets[voucher_].feeRate = feeRate_;
        markets[voucher_].voucherType = voucherType_;
        markets[voucher_].asset = asset_;
        markets[voucher_].onlyManangerOffer = onlyManangerOffer_;

        _vouchers.add(voucher_);

        emit AddMarket(
            voucher_,
            voucherType_,
            asset_,
            decimals_,
            feeRate_,
            onlyManangerOffer_
        );
    }

    function removeMarket(address voucher_) external onlyAdmin {
        _vouchers.remove(voucher_);
        delete markets[voucher_];
        emit RemoveMarket(voucher_);
    }

    function setCurrency(address currency_, bool enable_) external onlyAdmin {
        if (enable_) {
            _currencies.add(currency_);
        } else {
            _currencies.remove(currency_);
        }
        emit SetCurrency(currency_, enable_);
    }

    function withdrawFee(address currency_, uint256 reduceAmount_)
        external
        onlyAdmin
    {
        ERC20TransferHelper.doTransferOut(
            currency_,
            payable(admin),
            reduceAmount_
        );
        emit WithdrawFee(currency_, reduceAmount_);
    }

    function addAllowAddress(
        address voucher_,
        address[] calldata addresses_,
        bool resetExisting_
    ) external onlyVoucherManager(voucher_) {
        require(markets[voucher_].isValid, "unsupported voucher");
        EnumerableSetUpgradeable.AddressSet storage set = _allowAddresses[
            voucher_
        ];

        if (resetExisting_) {
            while (set.length() != 0) {
                set.remove(set.at(0));
            }
        }

        for (uint256 i = 0; i < addresses_.length; i++) {
            set.add(addresses_[i]);
        }
    }

    function removeAllowAddress(address voucher_, address[] calldata addresses_)
        external
        onlyVoucherManager(voucher_)
    {
        require(markets[voucher_].isValid, "unsupported voucher");
        EnumerableSetUpgradeable.AddressSet storage set = _allowAddresses[
            voucher_
        ];
        for (uint256 i = 0; i < addresses_.length; i++) {
            set.remove(addresses_[i]);
        }
    }

    function isBuyerAllowed(address voucher_, address buyer_)
        external
        view
        returns (bool)
    {
        return _allowAddresses[voucher_].contains(buyer_);
    }

    function setVoucherManager(
        address voucher_,
        address[] calldata managers_,
        bool resetExisting_
    ) external onlyAdmin {
        require(markets[voucher_].isValid, "unsupported voucher");
        EnumerableSetUpgradeable.AddressSet storage set = _voucherManagers[
            voucher_
        ];
        if (resetExisting_) {
            while (set.length() != 0) {
                set.remove(set.at(0));
            }
        }

        for (uint256 i = 0; i < managers_.length; i++) {
            set.add(managers_[i]);
        }
    }

    function voucherManagers(address voucher_)
        external
        view
        returns (address[] memory managers_)
    {
        managers_ = new address[](_voucherManagers[voucher_].length());
        for (uint256 i = 0; i < _voucherManagers[voucher_].length(); i++) {
            managers_[i] = _voucherManagers[voucher_].at(i);
        }
    }

    function setSolver(ISolver newSolver_) public virtual onlyAdmin {
        ISolver oldSolver = solver;
        require(newSolver_.isSolver(), "invalid solver");
        solver = newSolver_;

        emit NewSolver(oldSolver, newSolver_);
    }
}
