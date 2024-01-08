// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";

/// @title Eleven-Yellow BOTTO governance service
/// @notice Staked BOTTO tokens represent a weighting for influence on governance issues
contract BottoGovernance is OwnableUpgradeable {
    using SafeMath for uint256;

    address public botto;
    uint256 public totalStaked;
    mapping(address => uint256) public userStakes;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event RecoveryTransfer(address token, uint256 amount, address recipient);

    /// @param botto_ ERC20 contract address of BOTTO token
    /// @dev BOTTO token contract address is initialized
    function initialize(address botto_) public initializer {
        __Ownable_init();
        botto = botto_;
    }

    /// @notice Stake BOTTO tokens for governance purposes
    /// @param amount_ the amount of BOTTO tokens to stake
    /// @dev Stake requires approval for governance contract to transfer & hold BOTTO tokens
    function stake(uint256 amount_) public virtual {
        require(amount_ > 0, "Invalid amount");
        userStakes[msg.sender] = userStakes[msg.sender].add(amount_);
        IERC20(botto).transferFrom(msg.sender, address(this), amount_);
        totalStaked = totalStaked.add(amount_);
        emit Staked(msg.sender, amount_);
    }

    /// @notice Unstake previously staked tokens
    /// @dev Existing token stake is transferred back to owner
    function unstake() public virtual {
        uint256 amount = userStakes[msg.sender];
        require(amount > 0, "No existing stake");
        userStakes[msg.sender] = 0;
        totalStaked = totalStaked.sub(amount);
        IERC20(botto).transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /// @notice Sweeps excess tokens to a specified recipient address
    /// @param token_ address of token to recover
    /// @param recipient_ payable address for token beneficiary
    /// @dev Total token balance is recovered; only excess non-staked tokens in case of BOTTO
    function recover(address token_, address payable recipient_)
        public
        virtual
        onlyOwner
    {
        uint256 _balance = IERC20(token_).balanceOf(address(this));

        if (token_ == botto) {
            _balance = _balance.sub(totalStaked);
        }

        TransferHelper.safeTransfer(token_, recipient_, _balance);
        emit RecoveryTransfer(token_, _balance, recipient_);
    }
}
