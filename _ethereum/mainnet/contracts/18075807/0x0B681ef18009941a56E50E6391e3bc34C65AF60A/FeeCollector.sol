// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

import "./PercentageMath.sol";
import "./IWETH.sol";
import "./IFeeCollector.sol";
import "./ILendPoolAddressesProvider.sol";
import "./ILendPool.sol";
import "./IBToken.sol";

contract FeeCollector is IFeeCollector, Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IBToken;
    using PercentageMath for uint256;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // deprecated
    IWETH public WETH;
    // deprecated
    IERC20Upgradeable public BWETH;
    // deprecated
    uint256 public treasuryPercentage;

    address public treasury;
    address public bendCollector;
    ILendPoolAddressesProvider public bendAddressesProvider;
    address public feeDistributor;
    EnumerableSetUpgradeable.AddressSet private _bTokens;
    EnumerableMapUpgradeable.AddressToUintMap private _treasuryPercentages;
    mapping(address => uint256) public treasuryTotalTransferred;

    function initialize(
        IWETH _weth,
        IERC20Upgradeable _bweth,
        address _treasury,
        address _bendCollector,
        ILendPoolAddressesProvider _bendAddressesProvider
    ) external initializer {
        __Ownable_init();
        WETH = _weth;
        BWETH = _bweth;
        treasury = _treasury;
        bendCollector = _bendCollector;
        bendAddressesProvider = _bendAddressesProvider;
        WETH.approve(_bendAddressesProvider.getLendPool(), type(uint256).max);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(
            _treasury != address(0),
            "FeeCollector: treasury can't be null"
        );
        treasury = _treasury;
    }

    function setBendCollector(address _bendCollector) external onlyOwner {
        require(
            _bendCollector != address(0),
            "FeeCollector: bendCollector can't be null"
        );
        bendCollector = _bendCollector;
    }

    function setFeeDistributor(address _feeDistributor) external onlyOwner {
        require(
            _feeDistributor != address(0),
            "FeeCollector: feeDistributor can't be null"
        );
        feeDistributor = _feeDistributor;
    }

    function setTreasuryPercentage(
        address token_,
        uint256 treasuryPercentage_
    ) external onlyOwner {
        require(token_ != address(0), "FeeCollector: token can't be null");
        require(
            treasuryPercentage_ <= PercentageMath.PERCENTAGE_FACTOR,
            "FeeCollector: treasury percentage overflow"
        );
        _treasuryPercentages.set(token_, treasuryPercentage_);
    }

    function getTreasuryPercentage(
        address token_
    ) external view returns (uint256) {
        return _treasuryPercentages.get(token_);
    }

    function addBToken(address bToken_) external onlyOwner {
        require(bToken_ != address(0), "FeeCollector: bToken can't be null");
        _bTokens.add(bToken_);
    }

    function removeBToken(address bToken_) external onlyOwner {
        require(bToken_ != address(0), "FeeCollector: bToken can't be null");
        _bTokens.remove(bToken_);
    }

    function setTreasuryTotalTransferred(
        address token_,
        uint256 totalTransferred_
    ) external onlyOwner {
        require(token_ != address(0), "FeeCollector: token can't be null");
        treasuryTotalTransferred[token_] = totalTransferred_;
    }

    function getTreasuryTotalTransferred(address token_)
        external
        view
        returns (uint256)
    {
        return treasuryTotalTransferred[token_];
    }

    function collect() external override {
        for (uint256 i = 0; i < _bTokens.length(); i++) {
            _collectBToken(IBToken(_bTokens.at(i)));
        }

        for (uint256 i = 0; i < _treasuryPercentages.length(); i++) {
            (address token_, uint256 percentage_) = _treasuryPercentages.at(i);
            _distributeToken(IERC20Upgradeable(token_), percentage_);
        }
    }

    function _collectBToken(IBToken bToken_) internal {
        uint256 amount = bToken_.balanceOf(bendCollector);
        if (amount > 0) {
            bToken_.safeTransferFrom(bendCollector, address(this), amount);
            amount = bToken_.balanceOf(address(this));
            ILendPool(bendAddressesProvider.getLendPool()).withdraw(
                bToken_.UNDERLYING_ASSET_ADDRESS(),
                amount,
                address(this)
            );
        }
    }

    function _distributeToken(
        IERC20Upgradeable token_,
        uint256 treasuryPercentage_
    ) internal {
        require(
            feeDistributor != address(0),
            "FeeCollector: feeDistributor can't be null"
        );
        require(treasury != address(0), "FeeCollector: treasury can't be null");

        uint256 _toDistribute = token_.balanceOf(address(this));
        if (_toDistribute == 0) {
            return;
        }

        uint256 _toTreasury = _toDistribute.percentMul(treasuryPercentage_);
        if (_toTreasury > 0) {
            token_.safeTransfer(treasury, _toTreasury);
            treasuryTotalTransferred[address(token_)] += _toTreasury;
        }

        uint256 _toFeeDistributor = _toDistribute - _toTreasury;
        if (_toFeeDistributor > 0) {
            token_.safeTransfer(feeDistributor, _toFeeDistributor);
        }
    }
}
