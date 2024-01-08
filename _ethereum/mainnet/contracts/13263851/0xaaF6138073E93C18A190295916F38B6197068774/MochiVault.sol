// SPDX-License-Identifier: (c) Mochi.Fi, 2021

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC721.sol";
import "./NFTTransfer.sol";
import "./IMochiNFT.sol";
import "./IMochiEngine.sol";
import "./IUSDM.sol";
import "./IMochiVault.sol";
import "./INFTXVaultFactory.sol";
import "./IMochiNFTVault.sol";

contract MochiNFTVault is Initializable, IMochiNFTVault {
    using Float for uint256;

    /// immutable variables
    IMochiEngine public immutable engine;
    IMochiNFT public immutable nft;
    INFTXVaultFactory public immutable nftxFactory;
    IERC721 public override asset;

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

    /// result
    uint256 public liquidated;

    mapping(uint256 => Detail) public override details;
    mapping(uint256 => uint256) public lastDeposit;

    uint256 public tokenIndex;

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

    constructor(address _engine, address _nftxFactory) {
        engine = IMochiEngine(_engine);
        nftxFactory = INFTXVaultFactory(_nftxFactory);
        nft = IMochiEngine(_engine).nft();
    }

    function initialize(address _asset) external override initializer {
        asset = IERC721(_asset);
        debtIndex = 1e18;
        lastAccrued = block.timestamp;
    }

    function setTokenIndex(uint256 i) external {
        require(msg.sender == engine.governance(), "!gov");
        tokenIndex = i;
    }

    function getToken() public view returns(address) {
        address[] memory vaults = nftxFactory.vaultsForAsset(address(asset));
        return vaults[tokenIndex];
    }

    function liveDebtIndex() public view override returns (uint256 index) {
        return
            engine.mochiProfile().calculateFeeIndex(
                getToken(),
                debtIndex,
                lastAccrued
            );
    }

    function _mintUsdm(address _to, uint256 _amount) internal {
        engine.minter().mint(_to, _amount);
    }

    function status(uint256 _id) public view override returns (Status) {
        return details[_id].status;
    }

    function currentDebt(uint256 _id) public view override returns (uint256) {
        require(details[_id].status != Status.Invalid, "invalid");
        uint256 newIndex = liveDebtIndex();
        return (details[_id].debt * newIndex) / details[_id].debtIndex;
    }

    function accrueDebt(uint256 _id) public {
        // global debt for vault
        // first, increase gloabal debt;
        uint256 currentIndex = liveDebtIndex();
        uint256 increased = (debts * currentIndex) / debtIndex - debts;
        debts += increased;
        claimable += int256(increased);
        // update global debtIndex
        debtIndex = currentIndex;
        lastAccrued = block.timestamp;
        // individual debt
        if (_id != type(uint256).max && details[_id].debtIndex < debtIndex) {
            require(details[_id].status != Status.Invalid, "invalid");
            if (details[_id].debt != 0) {
                uint256 increasedDebt = (details[_id].debt * debtIndex) /
                    details[_id].debtIndex -
                    details[_id].debt;
                uint256 discountedDebt = increasedDebt.multiply(
                    engine.discountProfile().discount(engine.nft().ownerOf(_id))
                );
                debts -= discountedDebt;
                claimable -= int256(discountedDebt);
                details[_id].debt += (increasedDebt - discountedDebt);
            }
            details[_id].debtIndex = debtIndex;
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
        details[id].debtIndex = liveDebtIndex();
        details[id].status = Status.Idle;
        details[id].referrer = _referrer;
    }

    /// anyone can deposit collateral to given id
    /// it will even allow depositing to liquidated vault so becareful when depositing
    function deposit(uint256 _id, uint256 _tokenId)
        public
        override
        updateDebt(_id)
    {
        // should it be able to deposit if invalid?
        require(engine.nft().asset(_id) == address(asset), "!asset");
        require(
            details[_id].status == Status.Idle ||
                details[_id].status == Status.Collaterized ||
                details[_id].status == Status.Active,
            "!depositable"
        );
        uint256 amount = 1e18 * 95 / 100;
        lastDeposit[_id] = block.timestamp;
        deposits += amount;
        details[_id].collateral += amount;
        if (details[_id].status == Status.Idle) {
            details[_id].status = Status.Collaterized;
        }
        NFTTransfer.receiveNFT(address(asset), _tokenId);
    }

    /// should only be able to withdraw if status is not liquidatable
    function withdraw(
        uint256 _id,
        uint256 _tokenId,
        bytes memory _data
    ) public override wait(_id) {
        require(engine.nft().ownerOf(_id) == msg.sender, "!approved");
        require(engine.nft().asset(_id) == address(asset), "!asset");
        // update prior to interaction
        float memory price = engine.cssr().update(address(asset), _data);
        uint256 amount = 1e18 * 95 / 100;
        require(
            !_liquidatable(
                details[_id].collateral - amount,
                price,
                details[_id].debt
            ),
            "!healthy"
        );
        float memory cf = engine.mochiProfile().maxCollateralFactor(
            getToken()
        );
        uint256 maxMinted = (details[_id].collateral - amount)
            .multiply(cf)
            .multiply(price);
        require(details[_id].debt <= maxMinted, ">cf");
        deposits -= amount;
        details[_id].collateral -= amount;
        if (details[_id].collateral == 0) {
            details[_id].status = Status.Idle;
        }
        NFTTransfer.sendNFT(address(asset), engine.nft().ownerOf(_id), _tokenId);
    }

    function borrow(
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public override updateDebt(_id) {
        require(engine.nft().ownerOf(_id) == msg.sender, "!approved");
        require(engine.nft().asset(_id) == address(asset), "!asset");
        uint256 increasingDebt = (_amount * 1005) / 1000;
        uint256 totalDebt = details[_id].debt + increasingDebt;
        require(
            engine.mochiProfile().creditCap(getToken()) >= debts + _amount,
            ">cap"
        );
        require(totalDebt >= engine.mochiProfile().minimumDebt(), "<minimum");
        // update prior to interaction
        float memory price = engine.cssr().update(getToken(), _data);
        float memory cf = engine.mochiProfile().maxCollateralFactor(
            getToken()
        );
        uint256 maxMinted = details[_id].collateral.multiply(cf).multiply(
            price
        );
        require(details[_id].debt + _amount <= maxMinted, ">cf");
        require(
            !_liquidatable(details[_id].collateral, price, totalDebt),
            "!healthy"
        );
        mintFeeToPool(increasingDebt - _amount, details[_id].referrer);
        // this will ensure debtIndex will not increase on further `updateDebt` triggers
        details[_id].debtIndex =
            (details[_id].debtIndex * (totalDebt)) /
            (details[_id].debt + _amount);
        details[_id].debt = totalDebt;
        details[_id].status = Status.Active;
        debts += _amount;
        _mintUsdm(msg.sender, _amount);
    }

    /// someone sends usdm to this address and repays the debt
    /// will payback the leftover usdm
    function repay(uint256 _id, uint256 _amount)
        public
        override
        updateDebt(_id)
    {
        if (_amount > details[_id].debt) {
            _amount = details[_id].debt;
        }
        require(_amount > 0, "zero");
        if (debts < _amount) {
            // safe gaurd to some underflows
            debts = 0;
        } else {
            debts -= _amount;
        }
        details[_id].debt -= _amount;
        if (details[_id].debt == 0) {
            details[_id].status = Status.Collaterized;
        }
        engine.usdm().transferFrom(msg.sender, address(this), _amount);
        engine.usdm().burn(_amount);
    }

    function liquidate(
        uint256 _id,
        uint256[] calldata _tokenIds,
        uint256 _usdm
    ) external override updateDebt(_id) {
        require(msg.sender == address(engine.liquidator()), "!liquidator");
        require(engine.nft().asset(_id) == address(asset), "!asset");
        float memory price = engine.cssr().getPrice(getToken());
        require(
            _liquidatable(details[_id].collateral, price, currentDebt(_id)),
            "healthy"
        );

        uint256 collateral = _tokenIds.length * 1e18 * 95 / 100;

        debts -= _usdm;

        details[_id].collateral -= collateral;
        details[_id].debt -= _usdm;

        for(uint256 i = 0; i<_tokenIds.length; i++){
            NFTTransfer.sendNFT(address(asset), msg.sender, _tokenIds[i]);
        }
    }

    /// @dev returns if status is liquidatable with given `_collateral` amount and `_debt` amount
    /// @notice should return false if _collateral * liquidationLimit < _debt
    function _liquidatable(
        uint256 _collateral,
        float memory _price,
        uint256 _debt
    ) internal view returns (bool) {
        float memory lf = engine.mochiProfile().liquidationFactor(
            getToken()
        );
        // when debt is lower than liquidation value, it can be liquidated
        return _collateral.multiply(lf) < _debt.divide(_price);
    }

    function liquidatable(uint256 _id) external view returns (bool) {
        float memory price = engine.cssr().getPrice(getToken());
        return _liquidatable(details[_id].collateral, price, currentDebt(_id));
    }

    function claim() external updateDebt(type(uint256).max) {
        require(claimable > 0, "!claimable");
        // reserving 25% to prevent potential risks
        uint256 toClaim = (uint256(claimable) * 75) / 100;
        mintFeeToPool(toClaim, address(0));
    }

    function mintFeeToPool(uint256 _amount, address _referrer) internal {
        claimable -= int256(_amount);
        if (address(0) != _referrer) {
            _mintUsdm(address(engine.referralFeePool()), _amount);
            engine.referralFeePool().addReward(_referrer);
        } else {
            _mintUsdm(address(engine.treasury()), _amount);
        }
    }
}
