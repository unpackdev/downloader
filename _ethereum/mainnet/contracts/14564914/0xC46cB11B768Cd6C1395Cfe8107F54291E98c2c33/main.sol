//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./events.sol";
import "./IProxy.sol";

contract AdminModule is Events {
    /**
     * @dev Only auth gaurd.
     */
    modifier onlyAuth() {
        require(IProxy(address(this)).getAdmin() == msg.sender, "only auth");
        _;
    }

    /**
     * @dev Update rebalancer.
     * @param rebalancer_ address of rebalancer.
     * @param isRebalancer_ true for setting the rebalancer, false for removing.
     */
    function updateRebalancer(address rebalancer_, bool isRebalancer_)
        external
        onlyAuth
    {
        _isRebalancer[rebalancer_] = isRebalancer_;
        emit updateRebalancerLog(rebalancer_, isRebalancer_);
    }

    /**
     * @dev Update withdrawal fee.
     * @param newWithdrawalFee_ new withdrawal fee.
     */
    function updateWithdrawalFee(uint256 newWithdrawalFee_) external onlyAuth {
        uint256 oldWithdrawalFee_ = _withdrawalFee;
        _withdrawalFee = newWithdrawalFee_;
        emit updateWithdrawalFeeLog(oldWithdrawalFee_, newWithdrawalFee_);
    }


    /**
     * @dev Update ratios.
     * @param ratios_ new ratios.
     */
    function updateRatios(uint16[] memory ratios_) external onlyAuth {
        _ratios = Ratios(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            ratios_[3],
            ratios_[4],
            uint128(ratios_[5]) * 1e23
        );
        emit updateRatiosLog(
            ratios_[0],
            ratios_[1],
            ratios_[2],
            ratios_[3],
            ratios_[4],
            uint128(ratios_[5]) * 1e23
        );
    }

    /**
     * @dev Change status.
     * @param status_ new status, function to pause all functionality of the contract, status = 2 -> pause, status = 1 -> resume.
     */
    function changeStatus(uint256 status_) external onlyAuth {
        _status = status_;
        emit changeStatusLog(status_);
    }

    /**
     * @dev function to initialize variables
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address rebalancer_,
        address token_,
        address atoken_,
        uint256 revenueFee_,
        uint256 withdrawalFee_,
        uint256 idealExcessAmt_,
        uint16[] memory ratios_,
        uint256 swapFee_,
        uint256 saveSlippage_
    ) external initializer onlyAuth {
        address vaultDsaAddr_ = instaIndex.build(
            address(this),
            2,
            address(this)
        );
        _vaultDsa = IDSA(vaultDsaAddr_);
        __ERC20_init(name_, symbol_);
        _isRebalancer[rebalancer_] = true;
        _token = IERC20(token_);
        _tokenDecimals = uint8(TokenInterface(token_).decimals());
        _atoken = IERC20(atoken_);
        _revenueFee = revenueFee_;
        _lastRevenueExchangePrice = 1e18;
        _withdrawalFee = withdrawalFee_;
        _idealExcessAmt =  idealExcessAmt_;
        // sending borrow rate in 4 decimals eg:- 300 meaning 3% and converting into 27 decimals eg:- 3 * 1e25
        _ratios = Ratios(ratios_[0], ratios_[1], ratios_[2], ratios_[3], ratios_[4], uint128(ratios_[5]) * 1e23);
        _tokenMinLimit = _tokenDecimals > 17 ? 1e14 : _tokenDecimals > 11 ? 1e11 : _tokenDecimals > 5 ? 1e4 : 1;
        _swapFee = swapFee_;
        _saveSlippage = saveSlippage_;
    }

}