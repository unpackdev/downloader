// commit 4e7d762e04aa81475c87e0c4df5576bb983113e1
pragma solidity ^0.8.19;

import "BaseOwnable.sol";

interface ILybraVault {
    function burn(address onBehalfOf, uint256 amount) external;

    function withdraw(address onBehalfOf, uint256 amount) external;

    function getBorrowedOf(address user) external view returns (uint256);

    function depositedAsset(address user) external view returns (uint256);

    function getAssetPrice() external returns (uint256);
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);
}

interface IConfigurator {
    function getSafeCollateralRatio(address pool) external view returns (uint256);
}

contract LybraV2PartialWithdraw {
    bytes32 public constant NAME = "LybraV2PartialWithdraw";
    uint256 public constant VERSION = 1;

    address public constant STETH_VAULT = 0xa980d4c0C2E48d305b582AA439a3575e3de06f0E;
    address public constant RETH_VAULT = 0x090B2787D6798000710a8e821EC6111d254bb958;
    address public constant WSTETH_VAULT = 0x5e28B5858DA2C6fb4E449D69EEb5B82e271c45Ce;
    address public constant WBETH_VAULT = 0xB72dA4A9866B0993b9a7d842E5060716F74BF262;
    address public constant PEUSD = 0xD585aaafA2B58b1CD75092B51ade9Fa4Ce52F247;
    address public constant EUSD = 0xdf3ac4F479375802A821f7b7b46Cd7EB5E4262cC;
    address public constant LYBRA_CONFIGURATOR = 0xC8353594Eeedc5ce5a4544D3D9907b694c4690Ff;
    uint256 public constant MAXIMUM_BUFFER = 5 * 10 ** 18;

    function withdraw(address _vault, uint256 _buffer) external {
        require(
            _vault == STETH_VAULT || _vault == RETH_VAULT || _vault == WSTETH_VAULT || _vault == WBETH_VAULT,
            "LybraV2Withdraw: vault not supported"
        );

        require(_buffer <= MAXIMUM_BUFFER, "Exceed limit");

        if (_vault == address(STETH_VAULT)) {
            _handleRepayAndWithdraw(_vault, EUSD, _buffer);
        } else {
            _handleRepayAndWithdraw(_vault, PEUSD, _buffer);
        }
    }

    function _handleRepayAndWithdraw(address _vault, address _token, uint256 _buffer) internal {
        (uint256 borrowedTokenAmount, uint256 collateralAmount) = _getSafeBorrowAndCollateral(_vault, address(this));
        uint256 remainingToken = _getSafeBorrowTokenBalance(_token);
        uint256 repayAmount = remainingToken < borrowedTokenAmount ? remainingToken : borrowedTokenAmount;
        uint256 maxCollateralWithdraw = _getMaxCollateralWithdraw(
            _vault,
            borrowedTokenAmount,
            repayAmount,
            collateralAmount,
            _buffer
        );
        _burnAndRepayVault(_vault, repayAmount, maxCollateralWithdraw - 1); // incase rounding error
    }

    function _burnAndRepayVault(address _vault, uint256 borrowed, uint256 collateral) internal {
        if (borrowed > 0) {
            ILybraVault(_vault).burn(address(this), borrowed);
        }

        if (collateral > 1) {
            ILybraVault(_vault).withdraw(address(this), collateral);
        }
    }

    function _getMaxCollateralWithdraw(
        address _vault,
        uint256 _borrowed,
        uint256 _remainingBorrowedToken,
        uint256 _collateral,
        uint256 _buffer
    ) internal returns (uint256) {
        uint256 remainingBorrowedInLybra = _remainingBorrowedToken == _borrowed
            ? 0
            : _borrowed - _remainingBorrowedToken;
        if (remainingBorrowedInLybra == 0) {
            //@dev if repay all, return total collateral amount
            return _collateral;
        }
        uint256 safeCollateralRatio = IConfigurator(LYBRA_CONFIGURATOR).getSafeCollateralRatio(_vault);
        uint256 safeRatioWtihBuffer = safeCollateralRatio + _buffer;
        uint256 collateralPrice = ILybraVault(_vault).getAssetPrice();
        uint256 requireCollateralWithBuffer = (remainingBorrowedInLybra * safeRatioWtihBuffer) / collateralPrice / 100;
        uint256 maxCollateralWithdraw = requireCollateralWithBuffer > _collateral
            ? 0
            : _collateral - requireCollateralWithBuffer;
        return maxCollateralWithdraw;
    }

    function _getSafeBorrowAndCollateral(
        address _vault,
        address _safe
    ) internal view returns (uint256 borrowed, uint256 collateral) {
        borrowed = ILybraVault(_vault).getBorrowedOf(_safe);

        collateral = ILybraVault(_vault).depositedAsset(_safe);
    }

    function _getSafeBorrowTokenBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
}
