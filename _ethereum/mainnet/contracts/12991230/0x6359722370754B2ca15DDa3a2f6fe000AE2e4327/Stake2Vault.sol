//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStake2Vault.sol";
import "./ITOS.sol";
import "./IERC20.sol";

import "./SafeMath.sol";
import "./Stake2VaultStorage.sol";

/// @title TOS Token's Vault - stores the TOS for the period of time
/// @notice A vault is associated with the set of stake contracts.
/// Stake contracts can interact with the vault to claim TOS tokens
contract Stake2Vault is Stake2VaultStorage, IStake2Vault {
    using SafeMath for uint256;

    /// @dev event of according to request from(staking contract)  the amount of mining is paid to to.
    /// @param to the address that will receive the reward
    /// @param minableAmount minable amount
    /// @param miningAmount amount mined
    /// @param nonMiningAmount Amount not mined
    event ClaimedMining(
        address indexed to,
        uint256 minableAmount,
        uint256 miningAmount,
        uint256 nonMiningAmount
    );
    event Claimed(address indexed from, address to, uint256 amount);

    /// @dev constructor of Stake1Vault
    constructor() {}

    /// @dev receive function
    receive() external payable {
        revert("cannot receive Ether");
    }

    /// @dev Sets TOS address
    /// @param _tos  TOS address
    function setTOS(address _tos)
        external
        override
        onlyOwner
        nonZeroAddress(_tos)
    {
        tos = _tos;
    }

    /// @dev Change cap of the vault
    /// @param _cap  allocated reward amount
    function changeCap(uint256 _cap) external override onlyOwner {
        require(_cap > 0 && cap != _cap, "Stake2Vault: changeCap fails");
        cap = _cap;
    }

    /// @dev change name
    /// @param _name   name
    function changeName(string memory _name) external override onlyOwner {
        require(
            keccak256(abi.encodePacked(name)) !=
                keccak256(abi.encodePacked(_name)),
            "Stake2Vault: changeName fails"
        );
        name = _name;
    }

    /// @dev set stake address
    /// @param _stakeAddress  stake address
    function setStakeAddress(address _stakeAddress)
        external
        override
        nonZeroAddress(_stakeAddress)
        onlyOwner
    {
        require(
            stakeAddress != _stakeAddress,
            "Stake2Vault: setStakeAddress fails"
        );
        stakeAddress = _stakeAddress;
    }

    /// @dev set mining amount per second
    /// @param _miningPerSecond  a mining amount per second
    function setMiningAmountPerSecond(uint256 _miningPerSecond)
        external
        override
        onlyOwner
    {
        require(
            _miningPerSecond > 0 && miningPerSecond != _miningPerSecond,
            "Stake2Vault: zero or same _miningPerSecond"
        );
        miningPerSecond = _miningPerSecond;
    }

    /// @dev set mining start time
    /// @param _miningStartTime  mining start time
    function setMiningStartTime(uint256 _miningStartTime)
        external
        override
        onlyOwner
    {
        require(
            _miningStartTime > 0 && miningStartTime != _miningStartTime,
            "Stake2Vault: zero or same _miningStartTime"
        );
        miningStartTime = _miningStartTime;
    }

    /// @dev set mining end time
    /// @param _miningEndTime  mining end time
    function setMiningEndTime(uint256 _miningEndTime)
        external
        override
        onlyOwner
    {
        require(
            _miningEndTime > 0 && miningEndTime != _miningEndTime,
            "Stake2Vault: zero or same _miningEndTime"
        );
        miningEndTime = _miningEndTime;
    }

    /// @dev If the vault has more money than the reward to give, the owner can withdraw the remaining amount.
    /// @param to to address
    /// @param _amount the amount of withdrawal
    function withdraw(address to, uint256 _amount) external override onlyOwner {
        uint256 balanceOf = IERC20(tos).balanceOf(address(this));
        require(balanceOf >= _amount, "Stake2Vault: insuffient");
        require(
            IERC20(tos).transfer(to, _amount),
            "Stake2Vault: fail withdraw"
        );
    }

    /// @dev  a according to request from(staking contract)  the amount of mining is paid to to.
    /// @param to the address that will receive the reward
    /// @param minableAmount minable amount
    /// @param miningAmount amount mined
    /// @param nonMiningAmount Amount not mined
    function claimMining(
        address to,
        uint256 minableAmount,
        uint256 miningAmount,
        uint256 nonMiningAmount
    ) external override nonZero(minableAmount) returns (bool) {
        require(
            miningStartTime < block.timestamp,
            "Stake2Vault: It is not a mining period"
        );
        require(
            stakeAddress == msg.sender,
            "Stake2Vault: sender is not stakeContract"
        );
        require(
            minableAmount == miningAmount.add(nonMiningAmount),
            "Stake2Vault: minable amount is not correct"
        );

        uint256 tosBalance = IERC20(tos).balanceOf(address(this));
        require(tosBalance >= minableAmount, "Stake2Vault: not enough balance");

        miningAmountTotal = miningAmountTotal.add(miningAmount);
        nonMiningAmountTotal = nonMiningAmountTotal.add(nonMiningAmount);
        totalMinedAmount = totalMinedAmount.add(minableAmount);
        require(
            totalMinedAmount <=
                (block.timestamp.sub(miningStartTime)).mul(miningPerSecond),
            "Stake2Vault: Exceeded the set mining amount"
        );

        if (miningAmount > 0)
            require(
                IERC20(tos).transfer(to, miningAmount),
                "Stake2Vault: TOS transfer fail"
            );

        if (nonMiningAmount > 0)
            require(
                ITOS(tos).burn(address(this), nonMiningAmount),
                "Stake2Vault: TOS burn fail"
            );

        emit ClaimedMining(to, minableAmount, miningAmount, nonMiningAmount);
        return true;
    }

    function claim(address _to, uint256 _amount)
        external
        override
        onlyOwner
        nonZero(_amount)
        returns (bool)
    {
        uint256 tosBalance = IERC20(tos).balanceOf(address(this));
        require(tosBalance >= _amount, "Stake2Vault: not enough balance");
        require(
            IERC20(tos).transfer(_to, _amount),
            "Stake2Vault: TOS transfer fail"
        );

        emit Claimed(msg.sender, _to, _amount);
        return true;
    }

    /// @dev Returns Give the TOS balance stored in the vault
    /// @return the balance of TOS in this vault.
    function balanceTOSAvailableAmount()
        external
        view
        override
        returns (uint256)
    {
        return IERC20(tos).balanceOf(address(this));
    }

    /// @dev Give the infomation of this vault
    /// @return return1 [tos, stakeAddress]
    /// @return return2 cap
    /// @return return3 stakeType
    /// @return return4 miningPerSecond
    /// @return return5 name
    function infos()
        external
        view
        override
        returns (
            address[2] memory,
            uint256,
            uint256,
            uint256,
            string memory
        )
    {
        return ([tos, stakeAddress], cap, stakeType, miningPerSecond, name);
    }

    /// @dev Give all stakeContracts's addresses in this vault
    /// @return all stakeContracts's addresses
    function stakeAddressesAll()
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory addr = new address[](1);
        addr[0] = stakeAddress;
        return addr;
    }
}
