pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./ITreasury.sol";
import "./IFeeReceiving.sol";

abstract contract VaultWithFees is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    struct ClaimFee {
        uint64 percentage;
        address to;
        bool needFeeReceiving;
        mapping(address => bool) tokens;
    }

    ClaimFee[] internal claimFee;
    uint64 public sumClaimFee;
    bool public claimFeesEnabled;

    struct DepositFee {
        uint64 percentage;
        address to;
    }

    DepositFee public depositFee;

    uint64 public constant PCT_BASE = 100000;

    event SetDepositFee(uint256 fee);
    event SetDepositWallet(address to);

    function _configureVaultWithFees(
        address _depositFeeWallet,
        bool _enableClaimFees
    ) internal {
        claimFeesEnabled = _enableClaimFees;
        depositFee.to = _depositFeeWallet;
    }

    function setFeesEnabled(bool _isFeesEnabled) external onlyOwner {
        claimFeesEnabled = _isFeesEnabled;
    }

    function addClaimFeeReceiver(
        address _to,
        uint64 _percentage,
        bool _needFeeReceiving,
        address[] calldata _tokens
    ) external onlyOwner {
        require(sumClaimFee + _percentage <= PCT_BASE, "!sumClaimFee overflow");
        ClaimFee storage newWeight;
        newWeight.to = _to;
        newWeight.percentage = _percentage;
        newWeight.needFeeReceiving = _needFeeReceiving;
        for (uint256 i = 0; i < _tokens.length; i++) {
            newWeight.tokens[_tokens[i]] = true;
        }
        claimFee.push(newWeight);
        sumClaimFee = sumClaimFee + _percentage;
    }

    function claimFeeReceiversCount() external view returns (uint256) {
        return claimFee.length;
    }

    function claimFeeReceivers(uint256 _index)
        external
        view
        returns (
            uint64,
            address,
            bool
        )
    {
        return (
            claimFee[_index].percentage,
            claimFee[_index].to,
            claimFee[_index].needFeeReceiving
        );
    }

    function removeClaimFeeReceiver(uint256 _index) external onlyOwner {
        require(_index < claimFee.length, "indexOutOfBound");
        sumClaimFee = sumClaimFee - claimFee[_index].percentage;
        claimFee[_index] = claimFee[claimFee.length - 1];
        claimFee.pop();
    }

    function setClaimFeePercentage(uint256 _index, uint64 _percentage)
        external
        onlyOwner
    {
        require(_index < claimFee.length, "indexOutOfBound");
        require(uint256(sumClaimFee).add(uint256(_percentage)) <= uint256(uint64(-1)), "checkPercentageOverflow");
        sumClaimFee = sumClaimFee + _percentage - claimFee[_index].percentage;
        claimFee[_index].percentage = _percentage;
    }

    function setDepositFee(uint64 _newPercentage) external onlyOwner {
        require(
            _newPercentage < PCT_BASE &&
                _newPercentage != depositFee.percentage,
            "Invalid percentage"
        );
        depositFee.percentage = _newPercentage;
        emit SetDepositFee(_newPercentage);
    }

    function setDepositWallet(address _to) external onlyOwner {
        depositFee.to = _to;
        emit SetDepositWallet(_to);
    }

    function _getFeesOnClaimForToken(
        address _for,
        address _rewardToken,
        uint256 _amount
    ) internal returns (uint256) {
        if (!claimFeesEnabled) {
            return _amount;
        }
        uint256 fee;
        for (uint256 i = 0; i < claimFee.length; i++) {
            ClaimFee memory _claimFee = claimFee[i];
            fee = uint256(_claimFee.percentage).mul(_amount).div(PCT_BASE);
            if (claimFee[i].tokens[_rewardToken]) {
                IERC20(_rewardToken).safeTransfer(_claimFee.to, fee);
            }
            _amount = _amount.sub(fee);
            if (_claimFee.to.isContract() && _claimFee.needFeeReceiving) {
                IFeeReceiving(_claimFee.to).feeReceiving(
                    _for,
                    _rewardToken,
                    fee
                );
            }
        }
        return _amount;
    }

    function _getFeesOnDeposit(IERC20 _stakingToken, uint256 _amount)
        internal
        returns (uint256 _sumWithoutFee)
    {
        if (depositFee.percentage > 0) {
            uint256 _fee = uint256(depositFee.percentage).mul(_amount).div(PCT_BASE);
            _stakingToken.safeTransfer(depositFee.to, _fee);
            _sumWithoutFee = _amount.sub(_fee);
        } else {
            _sumWithoutFee = _amount;
        }
    }
}
