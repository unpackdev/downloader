// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

interface IOldSupplyTreasury {
    function frozenUnderlyToken() external view returns (uint256);
}

contract SupplyTreasuryFundForEmpty is ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant FULL_UTILIZATION_RATE = 1000;
    uint256 public constant RATE_DENOMINATOR = 10;
    uint256 public constant PRECISION = 1e18;

    address public oldSupplyTreasury;
    address public underlyToken;
    address public owner;

    uint256 public frozenUnderlyToken;

    bool public isErc20;
    bool private initialized;

    event Migrate(address _newTreasuryFund, bool _setReward);
    event DepositFor(address _for, uint256 _amount, bool _isErc20);
    event WithdrawFor(address _to, uint256 _amount);
    event Borrow(address _to, uint256 _lendingAmount, uint256 _lendingInterest);
    event RepayBorrow(uint256 _frozenUnderlyToken, uint256 _lendingAmount);

    modifier onlyInitialized() {
        require(initialized, "!initialized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "SupplyTreasuryFund: !authorized");
        _;
    }

    constructor(address _owner, address _oldSupplyTreasury) public {
        owner = _owner;
        oldSupplyTreasury = _oldSupplyTreasury;
    }

    // compatible old pool
    function initialize(
        // _virtualBalance
        address,
        address _underlyToken,
        bool _isErc20
    ) public onlyOwner {
        initialize(_underlyToken, _isErc20);
    }

    function initialize(address _underlyToken, bool _isErc20) public onlyOwner {
        require(!initialized, "initialized");

        underlyToken = _underlyToken;
        isErc20 = _isErc20;

        if (oldSupplyTreasury != address(0)) {
            frozenUnderlyToken = IOldSupplyTreasury(oldSupplyTreasury)
                .frozenUnderlyToken();
        }

        initialized = true;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function migrate(address _newTreasuryFund, bool _setReward)
        external
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        uint256 bal;

        if (isErc20) {
            bal = IERC20(underlyToken).balanceOf(address(this));

            sendToken(underlyToken, owner, bal);
        } else {
            bal = address(this).balance;

            if (bal > 0) {
                sendToken(address(0), owner, bal);
            }
        }

        emit Migrate(_newTreasuryFund, _setReward);

        return bal;
    }

    function _depositFor(address _for, uint256 _amount) internal {
        emit DepositFor(_for, _amount, isErc20);
    }

    function depositFor(address _for)
        public
        payable
        onlyInitialized
        onlyOwner
        nonReentrant
    {
        _depositFor(_for, msg.value);
    }

    function depositFor(address _for, uint256 _amount)
        public
        onlyInitialized
        onlyOwner
        nonReentrant
    {
        _depositFor(_for, _amount);
    }

    function withdrawFor(address _to, uint256 _amount)
        public
        onlyInitialized
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        if (isErc20) {
            sendToken(underlyToken, _to, _amount);
        } else {
            sendToken(address(0), _to, _amount);
        }

        emit WithdrawFor(_to, _amount);

        return _amount;
    }

    function sendToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) internal {
        if (_token == address(0)) {
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function borrow(
        address,
        uint256,
        uint256
    ) public onlyInitialized nonReentrant onlyOwner returns (uint256) {
        revert("SupplyTreasuryFundEmpty: Function disabled");
    }

    function repayBorrow()
        public
        payable
        onlyInitialized
        nonReentrant
        onlyOwner
    {
        revert("SupplyTreasuryFundEmpty: Function disabled");
    }

    function repayBorrow(uint256)
        public
        onlyInitialized
        nonReentrant
        onlyOwner
    {
        revert("SupplyTreasuryFundEmpty: Function disabled");
    }

    function claim()
        public
        onlyInitialized
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        return 0;
    }

    function getBalance() public view returns (uint256) {
        if (isErc20) {
            return IERC20(underlyToken).balanceOf(address(this));
        }

        return address(this).balance;
    }

    function getReward(address) public onlyOwner nonReentrant {}

    function getUtilizationRate() public view returns (uint256) {}

    function getBorrowRatePerBlock() public view returns (uint256) {}
}
