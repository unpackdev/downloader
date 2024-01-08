// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

import "./IPolicyBook.sol";
import "./IPolicyBookRegistry.sol";
import "./IContractsRegistry.sol";
import "./ILiquidityRegistry.sol";
import "./IBMICoverStaking.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract LiquidityRegistry is ILiquidityRegistry, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IPolicyBookRegistry public policyBookRegistry;
    IBMICoverStaking public bmiCoverStaking;

    // User address => policy books array
    mapping(address => EnumerableSet.AddressSet) private _policyBooks;

    event PolicyBookAdded(address _userAddr, address _policyBookAddress);
    event PolicyBookRemoved(address _userAddr, address _policyBookAddress);

    modifier onlyEligibleContracts() {
        require(
            msg.sender == address(bmiCoverStaking) || policyBookRegistry.isPolicyBook(msg.sender),
            "LR: Not an eligible contract"
        );
        _;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        bmiCoverStaking = IBMICoverStaking(_contractsRegistry.getBMICoverStakingContract());
    }

    function tryToAddPolicyBook(address _userAddr, address _policyBookAddr)
        external
        override
        onlyEligibleContracts
    {
        if (
            IERC20(_policyBookAddr).balanceOf(_userAddr) > 0 ||
            bmiCoverStaking.balanceOf(_userAddr) > 0
        ) {
            _policyBooks[_userAddr].add(_policyBookAddr);

            emit PolicyBookAdded(_userAddr, _policyBookAddr);
        }
    }

    function tryToRemovePolicyBook(address _userAddr, address _policyBookAddr)
        external
        override
        onlyEligibleContracts
    {
        if (
            IERC20(_policyBookAddr).balanceOf(_userAddr) == 0 &&
            bmiCoverStaking.balanceOf(_userAddr) == 0 &&
            IPolicyBook(_policyBookAddr).getWithdrawalStatus(_userAddr) ==
            IPolicyBook.WithdrawalStatus.NONE
        ) {
            _policyBooks[_userAddr].remove(_policyBookAddr);

            emit PolicyBookRemoved(_userAddr, _policyBookAddr);
        }
    }

    function getPolicyBooksArrLength(address _userAddr) external view override returns (uint256) {
        return _policyBooks[_userAddr].length();
    }

    function getPolicyBooksArr(address _userAddr)
        external
        view
        override
        returns (address[] memory _resultArr)
    {
        uint256 _policyBooksArrLength = _policyBooks[_userAddr].length();

        _resultArr = new address[](_policyBooksArrLength);

        for (uint256 i = 0; i < _policyBooksArrLength; i++) {
            _resultArr[i] = _policyBooks[_userAddr].at(i);
        }
    }

    /// @notice _bmiXRatio comes with 10**18 precision
    function getLiquidityInfos(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view override returns (LiquidityInfo[] memory _resultArr) {
        uint256 _to = (_offset.add(_limit)).min(_policyBooks[_userAddr].length()).max(_offset);

        _resultArr = new LiquidityInfo[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            address _currentPolicyBookAddr = _policyBooks[_userAddr].at(i);

            (uint256 _lockedAmount, , ) =
                IPolicyBook(_currentPolicyBookAddr).withdrawalsInfo(_userAddr);
            uint256 _availableAmount =
                IERC20(address(_currentPolicyBookAddr)).balanceOf(_userAddr);

            uint256 _bmiXRaito = IPolicyBook(_currentPolicyBookAddr).convertBMIXToSTBL(10**18);

            _resultArr[i - _offset] = LiquidityInfo(
                _currentPolicyBookAddr,
                _lockedAmount,
                _availableAmount,
                _bmiXRaito
            );
        }
    }

    function getWithdrawalRequests(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    )
        external
        view
        override
        returns (uint256 _arrLength, WithdrawalRequestInfo[] memory _resultArr)
    {
        uint256 _to = (_offset.add(_limit)).min(_policyBooks[_userAddr].length()).max(_offset);

        _resultArr = new WithdrawalRequestInfo[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            IPolicyBook _currentPolicyBook = IPolicyBook(_policyBooks[_userAddr].at(i));

            (uint256 _requestAmount, uint256 _readyToWithdrawDate, bool withdrawalAllowed) =
                _currentPolicyBook.withdrawalsInfo(_userAddr);

            IPolicyBook.WithdrawalStatus _currentStatus =
                _currentPolicyBook.getWithdrawalStatus(_userAddr);

            if (withdrawalAllowed || _currentStatus == IPolicyBook.WithdrawalStatus.NONE) {
                continue;
            }

            uint256 _endWithdrawDate;

            if (block.timestamp > _readyToWithdrawDate) {
                _endWithdrawDate = _readyToWithdrawDate.add(
                    _currentPolicyBook.READY_TO_WITHDRAW_PERIOD()
                );
            }

            (uint256 coverTokens, uint256 liquidity) =
                _currentPolicyBook.getNewCoverAndLiquidity();

            _resultArr[_arrLength] = WithdrawalRequestInfo(
                address(_currentPolicyBook),
                _requestAmount,
                _currentPolicyBook.convertBMIXToSTBL(_requestAmount),
                liquidity.sub(coverTokens),
                _readyToWithdrawDate,
                _endWithdrawDate
            );

            _arrLength++;
        }
    }

    function getWithdrawalSet(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view override returns (uint256 _arrLength, WithdrawalSetInfo[] memory _resultArr) {
        uint256 _to = (_offset.add(_limit)).min(_policyBooks[_userAddr].length()).max(_offset);

        _resultArr = new WithdrawalSetInfo[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            IPolicyBook _currentPolicyBook = IPolicyBook(_policyBooks[_userAddr].at(i));

            (uint256 _requestAmount, , bool withdrawalAllowed) =
                _currentPolicyBook.withdrawalsInfo(_userAddr);

            if (!withdrawalAllowed) {
                continue;
            }

            (uint256 coverTokens, uint256 liquidity) =
                _currentPolicyBook.getNewCoverAndLiquidity();

            _resultArr[_arrLength] = WithdrawalSetInfo(
                address(_currentPolicyBook),
                _requestAmount,
                _currentPolicyBook.convertBMIXToSTBL(_requestAmount),
                liquidity.sub(coverTokens)
            );

            _arrLength++;
        }
    }
}
