// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IFlashLoanReceiver.sol";
import "./ILoyalty.sol";
import "./ILendingPool.sol";
import "./MultiPoolBase.sol";

contract LendingPoolBase is ILendingPool, MultiPoolBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    mapping (address => bool) lendingTokens; // Tokens active for borrowing

    event FlashLoan(
        address indexed _receiver,
        address indexed _token,
        uint256 _amount,
        uint256 _totalFee
    );

    modifier LendingActive(address _token) {
        require(lendingTokens[_token] == true, "Flash Loans for this token are not active");
        _;
    }

    function flashLoan(
        address _receiver,
        address _token,
        uint256 _amount,
        bytes memory _params
    )
        public
        override
        nonReentrant
        LendingActive(_token)
        NonZeroAmount(_amount)
    {
        uint256 tokensAvailableBefore = _getReservesAvailable(_token);
        require(
            tokensAvailableBefore >= _amount,
            "Not enough token available to complete transaction"
        );

        uint256 totalFee = ILoyalty(loyaltyAddress()).getTotalFee(tx.origin, _amount);
        
        require(
            totalFee > 0, 
            "Amount too small for flash loan"
        );

        IFlashLoanReceiver receiver = IFlashLoanReceiver(_receiver);
        address payable userPayable = address(uint160(_receiver));

        // transfer flash loan funds to user
        IERC20(_token).safeTransfer(userPayable, _amount);
        
        // execute arbitrary user code
        receiver.executeOperation(_token, _amount, totalFee, _params);

        // Ensure token balances are equal + fees immediately after transfer.
        //  Since ETH reverts transactions that fail checks like below, we can
        //  ensure that funds are returned to the contract before end of transaction
        uint256 tokensAvailableAfter = _getReservesAvailable(_token);
        require(
            tokensAvailableAfter == tokensAvailableBefore.add(totalFee),
            "Token balances are inconsistent. Transaction reverted"
        );

        poolInfo[tokenPools[_token]].accTokenPerShare = poolInfo[tokenPools[_token]]
            .accTokenPerShare.mul(totalFee.mul(1e12).div(poolInfo[tokenPools[_token]].totalStaked));
        ILoyalty(loyaltyAddress()).updatePoints(tx.origin);

        emit FlashLoan(_receiver, _token, _amount, totalFee);
    }

    function getReservesAvailable(address _token)
        external
        override
        view
        returns (uint256)
    {
        if (!lendingTokens[_token]) {
            return 0;
        }
        return _getReservesAvailable(_token);
    }

    function _getReservesAvailable(address _token)
        internal
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    function getFeeForAmount(address _token, uint256 _amount)
        external
        override
        view
        returns (uint256)
    {
        if (!lendingTokens[_token]) {
            return 0;
        }
        return ILoyalty(loyaltyAddress()).getTotalFee(tx.origin, _amount);
    }

    function setLendingToken(address _token, bool _active)
        external
        HasPatrol("ADMIN")
    {
        _setLendingToken(_token, _active);
    }

    function _setLendingToken(address _token, bool _active)
        internal
    {
        lendingTokens[_token] = _active;
    }
}