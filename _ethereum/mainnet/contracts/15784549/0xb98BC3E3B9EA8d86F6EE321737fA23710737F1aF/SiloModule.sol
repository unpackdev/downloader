// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./draft-IERC20Permit.sol";
import "./SafeERC20.sol";

interface ISiloRepositoryLike {
    function isSilo(address) external view returns(bool);
}

interface ISiloLike {
    struct AssetStorage {
        /// @dev Token that represents a share in totalDeposits of Silo
        IERC20 collateralToken;
        /// @dev Token that represents a share in collateralOnlyDeposits of Silo
        IERC20 collateralOnlyToken;
        /// @dev Token that represents a share in totalBorrowAmount of Silo
        IERC20 debtToken;
        /// @dev COLLATERAL: Amount of asset token that has been deposited to Silo with interest earned by depositors.
        /// It also includes token amount that has been borrowed.
        uint256 totalDeposits;
        /// @dev COLLATERAL ONLY: Amount of asset token that has been deposited to Silo that can be ONLY used
        /// as collateral. These deposits do NOT earn interest and CANNOT be borrowed.
        uint256 collateralOnlyDeposits;
        /// @dev DEBT: Amount of asset token that has been borrowed with accrued interest.
        uint256 totalBorrowAmount;
    }

    function assetStorage(address _asset) external view returns (AssetStorage memory);

    function deposit(address _asset, uint256 _amount, bool _collateralOnly)
        external
        returns (uint256 collateralAmount, uint256 collateralShare);

    function withdraw(address _asset, uint256 _amount, bool _collateralOnly)
        external
        returns (uint256 withdrawnAmount, uint256 withdrawnShare);
}

/**
 * @title SiloModule
 */
contract SiloModule is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    error SiloDoesNotExist();
    error NotEnoughBalance();
    error IncorrectCollateralAmount();

    event SiloModuleDeposit(ISiloLike silo, uint256 xaiAmount);
    event SiloModuleWithdraw(ISiloLike silo, uint256 xaiAmount);

    IERC20 immutable xai;

    ISiloRepositoryLike immutable repository;

    mapping(ISiloLike => uint256) public deposited;

    constructor(IERC20 _xai, ISiloRepositoryLike _repository) {
        xai = _xai;
        repository = _repository;
    }

    modifier validSilo(ISiloLike _silo) {
        if (!repository.isSilo(address(_silo))) {
            revert SiloDoesNotExist();
        }

        _;
    }

    /**
     * @dev Deposits an amount of XAI into the provided Silo.
     * Xai has to be sent to this contract before calling this function.
     *
     * @param _silo Address of the silo where XAI will be deposited.
     * @param _xaiAmount Amount of XAI to deposit.
     */
    function deposit(ISiloLike _silo, uint256 _xaiAmount) external validSilo(_silo) onlyOwner {
        if (xai.balanceOf(address(this)) < _xaiAmount) {
            revert NotEnoughBalance();
        }

        deposited[_silo] += _xaiAmount;

        xai.approve(address(_silo), _xaiAmount);

        (uint256 collateralAmount,) = _silo.deposit(address(xai), _xaiAmount, false);

        if (collateralAmount != _xaiAmount) {
            revert IncorrectCollateralAmount();
        }

        emit SiloModuleDeposit(_silo, collateralAmount);
    }

    /**
     * @dev Withdraws from deposited xaiAmount from a Silo.
     *
     * @param _silo Address of the silo to withdraw from.
     * @param _xaiAmount Amount of XAI to withdraw.
     */
    function withdrawFromDeposits(ISiloLike _silo, uint256 _xaiAmount) external validSilo(_silo) onlyOwner {
        deposited[_silo] -= _xaiAmount; 

        (uint256 withdrawnAmount,) = _silo.withdraw(address(xai), _xaiAmount, false);

        emit SiloModuleWithdraw(_silo, withdrawnAmount);
    }

    /**
     * @dev Withdraws the available revenue from a Silo.
     *
     * @param _silo Address of the silo to withdraw from.
     */
    function withdrawRevenue(ISiloLike _silo) external validSilo(_silo) onlyOwner {
        uint256 available = availableXai(_silo);
        uint256 revenue = available - deposited[_silo];

        (uint256 withdrawnAmount,) = _silo.withdraw(address(xai), revenue, false);

        emit SiloModuleWithdraw(_silo, withdrawnAmount);
    }

    /**
     * @dev Withdraws everything from the silo.
     *
     * @param _silo Address of the silo to withdraw from.
     */
    function withdrawAll(ISiloLike _silo) external validSilo(_silo) onlyOwner {
        deposited[_silo] = 0;

        (uint256 withdrawnAmount,) = _silo.withdraw(address(xai), type(uint256).max, false);

        emit SiloModuleWithdraw(_silo, withdrawnAmount);
    }

    /**
     * @dev Transfers the specified amount of XAI to a recipient.
     *
     * @param _to Recipient.
     * @param _xaiAmount Amount of XAI to transfer.
     */
    function transfer(address _to, uint256 _xaiAmount) external onlyOwner {
        uint256 amount = _xaiAmount == type(uint256).max ? xai.balanceOf(address(this)) : _xaiAmount;
        xai.safeTransfer(_to, amount);
    }

    /**
     * @dev Returns the underlying balance of XAI that this module owns in a Silo.
     *
     * @param _silo Silo to check.
     */
    function availableXai(ISiloLike _silo) public view returns(uint256) {
        ISiloLike.AssetStorage memory assetStorage = _silo.assetStorage(address(xai));
        IERC20 shareToken = assetStorage.collateralToken;

        uint256 shares = shareToken.balanceOf(address(this));
        uint256 totalShares = shareToken.totalSupply();
        uint256 totalDeposits = assetStorage.totalDeposits;

        return _toAmount(shares, totalDeposits, totalShares);
    }

    function _toAmount(uint256 _share, uint256 _totalAmount, uint256 _totalShares) internal pure returns (uint256) {
        if (_totalShares == 0 || _totalAmount == 0) {
            return 0;
        }

        return _share * _totalAmount / _totalShares;
    }
}
