// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./SafeCast.sol";
import "./CheapERC20.sol";
import "./IERC3156FlashLender.sol";
import "./IMochiVault.sol";
import "./IMochiEngine.sol";
import "./IUSDM.sol";

contract MochiVault is Initializable, IMochiVault {
    using Float for uint256;
    using CheapERC20 for IERC20;

    /// immutable variables
    IMochiEngine public immutable engine;
    address public immutable pauser;
    IERC20 public override asset;

    /// for accruing debt
    uint256 public debtIndex;
    uint256 public lastAccrued;

    /// storage variables
    uint256 public override deposits;
    uint256 public override debts;
    int256 public override claimable;

    ///Mochi waits until the stability fees hit 1% and then starts calculating debt after that.
    ///E.g. If the stability fees are 10% for a year
    ///Mochi will wait 36.5 days (the time period required for the pre-minted 1%)

    mapping(uint256 => Detail) public override details;
    mapping(uint256 => uint256) public lastDeposit;

    // mutex for reentrancy gaurd
    bool public mutex;

    // boolean for pausing the vault
    bool public paused;

    modifier updateDebt(uint256 _id) {
        accrueDebt(_id);
        _;
    }

    modifier wait(uint256 _id) {
        require(
            lastDeposit[_id] + engine.mochiProfile().delay() <= block.timestamp,
            "!wait"
        );
        accrueDebt(_id);
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    modifier reentrancyGuard() {
        require(!mutex, "!reentrant");
        mutex = true;
        _;
        mutex = false;
    }

    // Adding the initializer modifier to the constructor ensures that noone
    // can call initialize on the implementation contract.
    constructor(address _engine, address _pauser) initializer {
        require(_engine != address(0), "engine cannot be zero address");
        engine = IMochiEngine(_engine);
        pauser = _pauser;
    }

    function initialize(address _asset) external override initializer {
        asset = IERC20(_asset);
        debtIndex = 1e18;
        lastAccrued = block.timestamp;
    }

    function pause() external override {
        require(msg.sender == pauser, "!pauser");
        paused = true;
        emit Pause();
    }

    function unpause() external override {
        require(msg.sender == pauser, "!pauser");
        paused = false;
        emit Unpause();
    }

    function liveDebtIndex() public view override returns (uint256 index) {
        return
            engine.mochiProfile().calculateFeeIndex(
                address(asset),
                debtIndex,
                lastAccrued
            );
    }

    function status(uint256 _id) external view override returns (Status) {
        return details[_id].status;
    }

    function currentDebt(uint256 _id) external view override returns (uint256) {
        Detail memory detail = details[_id];
        return _currentDebt(detail);
    }

    function _currentDebt(Detail memory _detail)
        internal
        view
        returns (uint256)
    {
        require(_detail.status != Status.Invalid, "invalid");
        uint256 newIndex = liveDebtIndex();
        return (_detail.debt * newIndex) / _detail.debtIndex;
    }

    function accrueDebt(uint256 _id) public {
        // global debt for vault
        // first, increase gloabal debt;
        uint256 currentIndex = liveDebtIndex();
        uint256 increased = (debts * currentIndex) / debtIndex - debts;
        debts += increased;
        claimable += SafeCast.toInt256(increased);
        // update global debtIndex
        debtIndex = currentIndex;
        lastAccrued = block.timestamp;
        // individual debt
        Detail memory detail = details[_id];
        if (_id != type(uint256).max && detail.debtIndex < debtIndex) {
            require(detail.status != Status.Invalid, "invalid");
            if (detail.debt != 0) {
                uint256 increasedDebt = (detail.debt * debtIndex) /
                    detail.debtIndex -
                    detail.debt;
                uint256 discountedDebt = increasedDebt.multiply(
                    engine.discountProfile().discount(engine.nft().ownerOf(_id))
                );
                debts -= discountedDebt;
                claimable -= SafeCast.toInt256(discountedDebt);
                detail.debt += (increasedDebt - discountedDebt);
            }
            detail.debtIndex = debtIndex;
            details[_id] = detail;
        }
    }

    function increase(
        uint256 _id,
        uint256 _deposits,
        uint256 _borrows,
        address _referrer,
        bytes memory _data
    ) external {
        if (_id == type(uint256).max) {
            // mint if _id is -1
            _id = mint(msg.sender, _referrer);
        }
        if (_deposits > 0) {
            deposit(_id, _deposits);
        }
        if (_borrows > 0) {
            borrow(_id, _borrows, _data);
        }
    }

    function decrease(
        uint256 _id,
        uint256 _withdraws,
        uint256 _repays,
        bytes memory _data
    ) external {
        if (_repays > 0) {
            repay(_id, _repays);
        }
        if (_withdraws > 0) {
            withdraw(_id, _withdraws, _data);
        }
    }

    function mint(address _recipient, address _referrer)
        public
        returns (uint256 id)
    {
        id = engine.nft().mint(address(asset), _recipient);
        details[id] = Detail({
            status:Status.Idle,
            collateral:0,
            debt:0,
            debtIndex:liveDebtIndex(),
            referrer:_referrer
        });
    }

    /// anyone can deposit collateral to given id
    /// it will even allow depositing to liquidated vault so becareful when depositing
    function deposit(uint256 _id, uint256 _amount)
        public
        override
        updateDebt(_id)
        reentrancyGuard
    {
        require(_amount > 0, "amount 0");
        require(engine.nft().asset(_id) == address(asset), "!asset");
        Detail memory detail = details[_id];
        require(
            detail.status == Status.Idle ||
                detail.status == Status.Collateralized ||
                detail.status == Status.Active,
            "!depositable"
        );
        lastDeposit[_id] = block.timestamp;
        deposits += _amount;
        detail.collateral += _amount;
        if (detail.status == Status.Idle) {
            detail.status = Status.Collateralized;
        }
        details[_id] = detail;
        asset.cheapTransferFrom(msg.sender, address(this), _amount);
    }

    /// should only be able to withdraw if status is not liquidatable
    function withdraw(
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )   public
        override
        wait(_id)
        reentrancyGuard 
        whenNotPaused
    {
        IMochiNFT nft = engine.nft();
        require(nft.ownerOf(_id) == msg.sender, "!approved");
        require(nft.asset(_id) == address(asset), "!asset");
        // update prior to interaction
        float memory price = engine.cssr().update(address(asset), _data);
        Detail memory detail = details[_id];
        require(
            !_liquidatable(detail.collateral - _amount, price, detail.debt),
            "!healthy"
        );
        float memory cf = engine.mochiProfile().maxCollateralFactor(
            address(asset)
        );
        uint256 maxMinted = (detail.collateral - _amount).multiply(cf).multiply(
            price
        );
        require(detail.debt <= maxMinted, ">cf");
        deposits -= _amount;
        detail.collateral -= _amount;
        if (detail.collateral == 0) {
            detail.status = Status.Idle;
        }
        details[_id] = detail;
        asset.cheapTransfer(msg.sender, _amount);
    }

    function borrow(
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    )   public
        override
        updateDebt(_id)
        whenNotPaused
    {
        IMochiNFT nft = engine.nft();
        IMochiProfile mochiProfile = engine.mochiProfile();
        Detail memory detail = details[_id];
        // update prior to interaction
        float memory price = engine.cssr().update(address(asset), _data);
        float memory cf = mochiProfile.maxCollateralFactor(
            address(asset)
        );
        uint256 maxMinted = detail.collateral.multiply(cf).multiply(
            price
        );
        require(nft.ownerOf(_id) == msg.sender, "!approved");
        require(nft.asset(_id) == address(asset), "!asset");
        if(detail.debt + _amount > maxMinted) {
            _amount = maxMinted - detail.debt;
        }
        uint256 cap = mochiProfile.creditCap(address(asset));
        if(cap < debts + _amount) {
            _amount = cap - debts;
        }
        uint256 increasingDebt = (_amount * 1005) / 1000;
        uint256 totalDebt = detail.debt + increasingDebt;
        require(detail.debt + _amount >= mochiProfile.minimumDebt(), "<minimum");
        require(
            !_liquidatable(detail.collateral, price, totalDebt),
            "!healthy"
        );
        mintFeeToPool(increasingDebt - _amount, detail.referrer);
        detail.debt = totalDebt;
        detail.status = Status.Active;
        debts += increasingDebt;
        details[_id] = detail;
        engine.minter().mint(msg.sender, _amount);
    }

    /// someone sends usdm to this address and repays the debt
    /// will payback the leftover usdm
    function repay(uint256 _id, uint256 _amount)
        public
        override
        updateDebt(_id)
    {
        Detail memory detail = details[_id];
        if (_amount > detail.debt) {
            _amount = detail.debt;
        }
        require(_amount > 0, "zero");
        if (debts < _amount) {
            // safe gaurd to some underflows
            debts = 0;
        } else {
            debts -= _amount;
        }
        detail.debt -= _amount;
        if (detail.debt == 0) {
            detail.status = Status.Collateralized;
        }
        details[_id] = detail;
        IUSDM usdm = engine.usdm();
        usdm.transferFrom(msg.sender, address(this), _amount);
        usdm.burn(_amount);
    }

    function liquidate(
        uint256 _id,
        uint256 _collateral,
        uint256 _usdm,
        bytes calldata _data
    ) external override updateDebt(_id) reentrancyGuard {
        Detail storage detail = details[_id];
        require(msg.sender == address(engine.liquidator()), "!liquidator");
        require(engine.nft().asset(_id) == address(asset), "!asset");
        float memory price = engine.cssr().update(address(asset), _data);
        require(
            _liquidatable(detail.collateral, price, _currentDebt(detail)),
            "healthy"
        );

        debts -= _usdm;

        detail.collateral -= _collateral;
        detail.debt -= _usdm;
        asset.cheapTransfer(msg.sender, _collateral);
    }

    /// @dev returns if status is liquidatable with given `_collateral` amount and `_debt` amount
    /// @notice should return false if _collateral * liquidationLimit < _debt
    function _liquidatable(
        uint256 _collateral,
        float memory _price,
        uint256 _debt
    ) internal view returns (bool) {
        float memory lf = engine.mochiProfile().liquidationFactor(
            address(asset)
        );
        // when debt is lower than liquidation value, it can be liquidated
        return _collateral.multiply(lf) < _debt.divide(_price);
    }

    function liquidatable(uint256 _id) external view returns (bool) {
        float memory price = engine.cssr().getPrice(address(asset));
        Detail memory detail = details[_id];
        return _liquidatable(detail.collateral, price, _currentDebt(detail));
    }

    function claim() external updateDebt(type(uint256).max) {
        require(claimable > 0, "!claimable");
        // reserving 25% to prevent potential risks
        uint256 toClaim = (SafeCast.toUint256(claimable) * 75) / 100;
        mintFeeToPool(toClaim, address(0));
    }

    /**
     *@dev
     */
    function mintFeeToPool(uint256 _amount, address _referrer) internal {
        claimable -= SafeCast.toInt256(_amount);
        if (address(0) != _referrer) {
            engine.minter().mint(address(engine.referralFeePool()), _amount);
            engine.referralFeePool().addReward(_referrer);
        } else {
            engine.minter().mint(address(engine.treasury()), _amount);
        }
    }
}
