pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Authorizable.sol";
import "./ITreasury.sol";

/// @title WithFeesAndRsOnDepositVault
/// @notice Vault for consumers of the system
abstract contract VaultWithFeesOnClaim is Authorizable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint64 public constant PCT_PRECISION = 10**18;

    struct FeeWeight {
        uint256 weight;
        address to;
        mapping(address => bool) tokens;
        bool callFunc;
    }

    FeeWeight[] internal feeWeights;

    uint256 public sumWeight;
    bool public feesEnabled;

    function _configureVaultWithFeesOnClaim(bool _enableFees) internal {
        feesEnabled = _enableFees;
    }

    function setFeesEnabled(bool _isFeesEnabled) external auth(msg.sender) {
        feesEnabled = _isFeesEnabled;
    }

    function addFeeReceiver(
        address _to,
        uint256 _weight,
        address[] calldata _tokens,
        bool _callFunc
    ) external auth(msg.sender) {
        FeeWeight storage newWeight;
        newWeight.to = _to;
        newWeight.weight = _weight;
        newWeight.callFunc = _callFunc;
        for (uint256 i = 0; i < _tokens.length; i++) {
            newWeight.tokens[_tokens[i]] = true;
        }
        feeWeights.push(newWeight);
    }

    function feeReceiversCount() external view returns (uint256) {
        return feeWeights.length;
    }

    function removeFeeReceiver(uint256 _index) external auth(msg.sender) {
        require(_index < feeWeights.length, "indexOutOfBound");
        sumWeight = sumWeight.sub(feeWeights[_index].weight);
        delete feeWeights[_index];
    }

    function setWeight(uint256 _index, uint256 _weight)
        external
        auth(msg.sender)
    {
        require(_index < feeWeights.length, "indexOutOfBound");
        sumWeight = sumWeight.add(_weight).sub(feeWeights[_index].weight);
        feeWeights[_index].weight = _weight;
    }

    function _getAndDistributeFeesOnClaimForToken(
        address _rewardToken,
        uint256 _amount
    ) internal returns (uint256) {
        if (!feesEnabled) {
            return _amount;
        }
        uint256 fee;
        for (uint256 i = 0; i < feeWeights.length; i++) {
            fee = _mulDiv2(feeWeights[i].weight, _amount, PCT_PRECISION);
            if (feeWeights[i].tokens[_rewardToken]) {
                IERC20(_rewardToken).safeTransfer(feeWeights[i].to, fee);
            }
            _amount = _amount.sub(fee);
            if (feeWeights[i].callFunc) {
                ITreasury(feeWeights[i].to).convertToRewardsToken(
                    _rewardToken,
                    fee
                );
            }
        }
        return _amount;
    }

    function subFeeForClaim(uint256[] memory _amounts)
        public
        view
        returns (uint256[] memory)
    {
        if (!feesEnabled) {
            return _amounts;
        }
        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 value = _amounts[i];
            for (uint256 j = 0; j < feeWeights.length; j++) {
                uint256 _fee = _mulDiv2(
                    feeWeights[j].weight,
                    _amounts[i],
                    PCT_PRECISION
                );
                value = value.sub(_fee);
            }
            _amounts[i] = value;
        }
        return _amounts;
    }

    function _mulDiv2(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure virtual returns (uint256) {
        return x.mul(y).div(z);
    }
}
