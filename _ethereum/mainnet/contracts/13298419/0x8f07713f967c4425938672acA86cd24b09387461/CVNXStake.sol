// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ICVNX.sol";
import "./ICVNXStake.sol";

/// @notice CVNX token contract.
contract CVNXStake is ICVNXStake, Ownable {
    /// @notice Emit when token staked.
    event Staked(uint256 indexed amount, address accountAddress);
    /// @notice Emit when token unstaked.
    event Unstaked(uint256 indexed amount, address accountAddress, uint256 indexed timestamp);

    /// @notice CVNX token address.
    ICVNX public cvnxToken;

    mapping(address => Stake[]) accountToStakes;
    mapping(address => uint256) accountToStaked;

    /// @notice Governance contract created in constructor.
    constructor(address _cvnxToken) {
        cvnxToken = ICVNX(_cvnxToken);
    }

    /// @notice Stake (lock) tokens for period.
    /// @param _amount Token amount
    /// @param _address Token holder address
    /// @param _endTimestamp End  of lock period (seconds)
    function stake(uint256 _amount, address _address, uint256 _endTimestamp) external override onlyOwner {
        require(_amount > 0, "[E-57] - Amount can't be a zero.");
        require(_endTimestamp > block.timestamp, "[E-58] - End timestamp should be more than current timestamp.");
        require(_address != address(0), "[E-59] - Zero address.");

        uint256 _accountToStaked = accountToStaked[_address];

        Stake memory _stake = Stake(_amount, _endTimestamp);

        cvnxToken.transferFrom(_address, address(this), _amount);

        accountToStaked[_address] = _accountToStaked + _amount;
        accountToStakes[_address].push(_stake);

        emit Staked(_amount, _address);
    }

    /// @notice Unstake (unlock) all available for unlock tokens.
    function unstake() external override {
        uint256 _accountToStaked = accountToStaked[msg.sender];
        uint256 _unavailableToUnstake;

        for (uint256 i = 0; i < accountToStakes[msg.sender].length; i++) {
            if (accountToStakes[msg.sender][i].endTimestamp > block.timestamp) {
                _unavailableToUnstake += accountToStakes[msg.sender][i].amount;
            }
        }

        uint256 _toUnstake = _accountToStaked - _unavailableToUnstake;

        require(_toUnstake > 0, "[E-46] - Nothing to unstake.");

        accountToStaked[msg.sender] -= _toUnstake;
        cvnxToken.transfer(msg.sender, _toUnstake);

        emit Unstaked(_toUnstake, msg.sender, block.timestamp);
    }

    /// @notice Return list of stakes for address.
    /// @param _address Token holder address
    function getStakesList(address _address) external view override onlyOwner returns(Stake[] memory stakes) {
        return accountToStakes[_address];
    }

    /// @notice Return total stake amount for address.
    /// @param _address Token holder address
    function getStakedAmount(address _address) external view override returns(uint256) {
        return accountToStaked[_address];
    }
}
