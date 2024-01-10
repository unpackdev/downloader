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
import "./ICapitalPool.sol";

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

    // User address => policy books array - for withdrawl requests for all pools
    mapping(address => EnumerableSet.AddressSet) private _withdrawlRequestsList;
    // list of all users have withdrawl request
    EnumerableSet.AddressSet internal _withdrawlRequestUsersList;

    address public capitalPool;

    event PolicyBookAdded(address _userAddr, address _policyBookAddress);
    event PolicyBookRemoved(address _userAddr, address _policyBookAddress);

    modifier onlyEligibleContracts() {
        require(
            msg.sender == address(bmiCoverStaking) ||
                policyBookRegistry.isPolicyBookFacade(msg.sender) ||
                policyBookRegistry.isPolicyBook(msg.sender),
            "LR: Not an eligible contract"
        );
        _;
    }

    modifier onlyCapitalPool() {
        require(msg.sender == capitalPool, "LR: not Capital Pool");
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
        capitalPool = _contractsRegistry.getCapitalPoolContract();
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

            // remove user withdraw request from the list
            _withdrawlRequestsList[_userAddr].remove(_policyBookAddr);
            if (_withdrawlRequestsList[_userAddr].length() == 0) {
                _withdrawlRequestUsersList.remove(_userAddr);
            }

            emit PolicyBookRemoved(_userAddr, _policyBookAddr);
        }
    }

    function removeExpiredWithdrawalRequest(address _userAddr, address _policyBookAddr)
        external
        override
        onlyEligibleContracts
    {
        // remove user withdraw request from the list
        _withdrawlRequestsList[_userAddr].remove(_policyBookAddr);
        if (_withdrawlRequestsList[_userAddr].length() == 0) {
            _withdrawlRequestUsersList.remove(_userAddr);
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

    /// @notice Register's Withdrawals for all pools
    /// @dev Requires withdrawls to be serialized
    /// @param _policyBook address of the policybook with requested withdrawl
    /// @param _user address user addres requesting withdrawl
    function registerWithdrawl(address _policyBook, address _user)
        external
        override
        onlyEligibleContracts
    {
        _withdrawlRequestsList[_user].add(_policyBook);
        _withdrawlRequestUsersList.add(_user);
    }

    /// @notice fetches the withdrawal data and amounts across all policybooks
    /// @return _totalWithdrawlAmount uint256 collected withdrawl amount
    function getAllPendingWithdrawalRequestsAmount()
        external
        view
        override
        returns (uint256 _totalWithdrawlAmount)
    {
        IPolicyBook.WithdrawalStatus _currentStatus;

        address _userAddr;
        address policyBookAddr;

        for (uint256 i = 0; i < _withdrawlRequestUsersList.length(); i++) {
            _userAddr = _withdrawlRequestUsersList.at(i);

            for (uint256 j = 0; j < _withdrawlRequestsList[_userAddr].length(); j++) {
                policyBookAddr = _withdrawlRequestsList[_userAddr].at(j);
                IPolicyBook _currentPolicyBook = IPolicyBook(policyBookAddr);

                _currentStatus = _currentPolicyBook.getWithdrawalStatus(_userAddr);

                if (
                    _currentStatus == IPolicyBook.WithdrawalStatus.NONE ||
                    _currentStatus == IPolicyBook.WithdrawalStatus.EXPIRED
                ) {
                    continue;
                }

                (uint256 _requestAmount, uint256 _readyToWithdrawDate, ) =
                    _currentPolicyBook.withdrawalsInfo(_userAddr);

                ///@dev exclude all ready request until before ready to withdraw date by 24 hrs
                /// + 1 hr (spare time for transaction execution time)
                if (
                    block.timestamp >=
                    _readyToWithdrawDate.sub(
                        ICapitalPool(capitalPool).rebalanceDuration().add(60 * 60)
                    )
                ) {
                    _totalWithdrawlAmount = _totalWithdrawlAmount.add(
                        _currentPolicyBook.convertBMIXToSTBL(_requestAmount)
                    );
                }
            }
        }
    }
}
