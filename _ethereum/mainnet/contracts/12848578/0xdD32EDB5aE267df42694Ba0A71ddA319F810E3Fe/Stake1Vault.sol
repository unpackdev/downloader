//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStake1Vault.sol";
import "./ITOS.sol";
import "./IERC20.sol";
import "./IStake1Storage.sol";
import "./LibTokenStake1.sol";
import "./SafeMath.sol";
import "./StakeVaultStorage.sol";

/// @title TOS Token's Vault - stores the TOS for the period of time
/// @notice A vault is associated with the set of stake contracts.
/// Stake contracts can interact with the vault to claim TOS tokens
contract Stake1Vault is StakeVaultStorage, IStake1Vault {
    using SafeMath for uint256;

    /// @dev event on sale-closed
    event ClosedSale();

    /// @dev event of according to request from(staking contract)  the amount of compensation is paid to to.
    /// @param from the stakeContract address that call claim
    /// @param to the address that will receive the reward
    /// @param amount the amount of reward
    event ClaimedReward(address indexed from, address to, uint256 amount);

    /// @dev constructor of Stake1Vault
    constructor() {}

    /// @dev receive function
    receive() external payable {
        revert("cannot receive Ether");
    }

    /// @dev Sets TOS address
    /// @param _tos  TOS address
    function setTOS(address _tos) external override onlyOwner {
        require(_tos != address(0), "Stake1Vault: input is zero");
        tos = _tos;
    }

    /// @dev Change cap of the vault
    /// @param _cap  allocated reward amount
    function changeCap(uint256 _cap) external override onlyOwner {
        require(_cap > 0 && cap != _cap, "Stake1Vault: changeCap fails");
        cap = _cap;
    }

    /// @dev Set Defi Address
    /// @param _defiAddr DeFi related address
    function setDefiAddr(address _defiAddr) external override onlyOwner {
        require(
            _defiAddr != address(0) && defiAddr != _defiAddr,
            "Stake1Vault: _defiAddr is zero"
        );
        defiAddr = _defiAddr;
    }

    /// @dev If the vault has more money than the reward to give, the owner can withdraw the remaining amount.
    /// @param _amount the amount of withdrawal
    function withdrawReward(uint256 _amount) external override onlyOwner {
        require(saleClosed, "Stake1Vault: didn't end sale");
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < stakeAddresses.length; i++) {
            rewardAmount = rewardAmount
                .add(stakeInfos[stakeAddresses[i]].totalRewardAmount)
                .sub(stakeInfos[stakeAddresses[i]].claimRewardAmount);
        }
        uint256 balanceOf = IERC20(tos).balanceOf(address(this));
        require(
            balanceOf >= rewardAmount.add(_amount),
            "Stake1Vault: insuffient"
        );
        require(
            IERC20(tos).transfer(msg.sender, _amount),
            "Stake1Vault: fail withdrawReward"
        );
    }

    /// @dev  Add stake contract
    /// @param _name stakeContract's name
    /// @param stakeContract stakeContract's address
    /// @param periodBlocks the period that give rewards of stakeContract
    function addSubVaultOfStake(
        string memory _name,
        address stakeContract,
        uint256 periodBlocks
    ) external override onlyOwner {
        require(
            stakeContract != address(0) && cap > 0 && periodBlocks > 0,
            "Stake1Vault: addStakerInVault init fails"
        );
        require(
            block.number < stakeStartBlock,
            "Stake1Vault: Already started stake"
        );
        require(!saleClosed, "Stake1Vault: closed sale");
        require(
            paytoken == IStake1Storage(stakeContract).paytoken(),
            "Stake1Vault: Different paytoken"
        );

        LibTokenStake1.StakeInfo storage info = stakeInfos[stakeContract];
        require(info.startBlock == 0, "Stake1Vault: Already added");

        stakeAddresses.push(stakeContract);
        uint256 _endBlock = stakeStartBlock.add(periodBlocks);

        info.name = _name;
        info.startBlock = stakeStartBlock;
        info.endBlock = _endBlock;

        if (stakeEndBlock < _endBlock) stakeEndBlock = _endBlock;
        orderedEndBlocks.push(stakeEndBlock);
    }

    /// @dev  Close the sale that can stake by user
    function closeSale() external override {
        require(!saleClosed, "Stake1Vault: already closed");
        require(
            cap > 0 &&
                stakeStartBlock > 0 &&
                stakeStartBlock < stakeEndBlock &&
                block.number > stakeStartBlock,
            "Stake1Vault: Before stakeStartBlock"
        );
        require(stakeAddresses.length > 0, "Stake1Vault: no stakes");

        realEndBlock = stakeEndBlock;

        // check balance, update balance
        for (uint256 i = 0; i < stakeAddresses.length; i++) {
            LibTokenStake1.StakeInfo storage stakeInfo =
                stakeInfos[stakeAddresses[i]];
            if (paytoken == address(0)) {
                stakeInfo.balance = address(uint160(stakeAddresses[i])).balance;
            } else {
                uint256 balanceAmount =
                    IERC20(paytoken).balanceOf(stakeAddresses[i]);
                stakeInfo.balance = balanceAmount;
            }
            if (stakeInfo.balance > 0)
                realEndBlock = stakeInfos[stakeAddresses[i]].endBlock;
        }

        blockTotalReward = cap.div(realEndBlock.sub(stakeStartBlock));

        uint256 sum = 0;
        // update total
        for (uint256 i = 0; i < stakeAddresses.length; i++) {
            LibTokenStake1.StakeInfo storage totalcheck =
                stakeInfos[stakeAddresses[i]];

            uint256 total = 0;
            for (uint256 j = 0; j < stakeAddresses.length; j++) {
                if (
                    stakeInfos[stakeAddresses[j]].endBlock >=
                    totalcheck.endBlock
                ) {
                    total = total.add(stakeInfos[stakeAddresses[j]].balance);
                }
            }

            if (totalcheck.endBlock > realEndBlock) {
                continue;
            }

            stakeEndBlockTotal[totalcheck.endBlock] = total;
            sum = sum.add(total);

            // reward total
            uint256 totalReward = 0;
            for (uint256 k = i; k > 0; k--) {
                if (
                    stakeEndBlockTotal[stakeInfos[stakeAddresses[k]].endBlock] >
                    0
                ) {
                    totalReward = totalReward.add(
                        stakeInfos[stakeAddresses[k]]
                            .endBlock
                            .sub(stakeInfos[stakeAddresses[k - 1]].endBlock)
                            .mul(blockTotalReward)
                            .mul(totalcheck.balance)
                            .div(
                            stakeEndBlockTotal[
                                stakeInfos[stakeAddresses[k]].endBlock
                            ]
                        )
                    );
                }
            }

            if (
                stakeEndBlockTotal[stakeInfos[stakeAddresses[0]].endBlock] > 0
            ) {
                totalReward = totalReward.add(
                    stakeInfos[stakeAddresses[0]]
                        .endBlock
                        .sub(stakeInfos[stakeAddresses[0]].startBlock)
                        .mul(blockTotalReward)
                        .mul(totalcheck.balance)
                        .div(
                        stakeEndBlockTotal[
                            stakeInfos[stakeAddresses[0]].endBlock
                        ]
                    )
                );
            }
            totalcheck.totalRewardAmount = totalReward;
        }

        saleClosed = true;
        emit ClosedSale();
    }

    /// @dev claim function.
    /// @dev sender is a staking contract.
    /// @dev A function that pays the amount(_amount) to _to by the staking contract.
    /// @dev A function that _to claim the amount(_amount) from the staking contract and gets the tos in the vault.
    /// @param _to a user that received reward
    /// @param _amount the receiving amount
    /// @return true
    function claim(address _to, uint256 _amount)
        external
        override
        returns (bool)
    {
        require(
            saleClosed && _amount > 0,
            "Stake1Vault: on sale or need to end the sale"
        );
        uint256 tosBalance = IERC20(tos).balanceOf(address(this));
        require(tosBalance >= _amount, "Stake1Vault: not enough balance");

        LibTokenStake1.StakeInfo storage stakeInfo = stakeInfos[msg.sender];
        require(stakeInfo.startBlock > 0, "Stake1Vault: startBlock zero");
        require(
            stakeInfo.totalRewardAmount > 0,
            "Stake1Vault: totalRewardAmount is zero"
        );
        require(
            stakeInfo.totalRewardAmount >=
                stakeInfo.claimRewardAmount.add(_amount),
            "Stake1Vault: claim amount exceeds"
        );

        stakeInfo.claimRewardAmount = stakeInfo.claimRewardAmount.add(_amount);

        require(
            IERC20(tos).transfer(_to, _amount),
            "Stake1Vault: TOS transfer fail"
        );

        emit ClaimedReward(msg.sender, _to, _amount);
        return true;
    }

    /// @dev  Whether user(to) can receive a reward amount(_amount)
    /// @param _to  a staking contract.
    /// @param _amount the total reward amount of stakeContract
    /// @return true
    function canClaim(address _to, uint256 _amount)
        external
        view
        override
        returns (bool)
    {
        require(saleClosed, "Stake1Vault: on sale or need to end the sale");
        uint256 tosBalance = IERC20(tos).balanceOf(address(this));
        require(tosBalance >= _amount, "not enough");

        LibTokenStake1.StakeInfo storage stakeInfo = stakeInfos[_to];
        require(stakeInfo.startBlock > 0, "Stake1Vault: startBlock is zero");

        require(
            stakeInfo.totalRewardAmount > 0,
            "Stake1Vault: amount is wrong"
        );
        require(
            stakeInfo.totalRewardAmount >=
                stakeInfo.claimRewardAmount.add(_amount),
            "Stake1Vault: amount exceeds"
        );

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

    /// @dev Give all stakeContracts's addresses in this vault
    /// @return all stakeContracts's addresses
    function stakeAddressesAll()
        external
        view
        override
        returns (address[] memory)
    {
        return stakeAddresses;
    }

    /// @dev Give the ordered end blocks of stakeContracts in this vault
    /// @return the ordered end blocks
    function orderedEndBlocksAll()
        external
        view
        override
        returns (uint256[] memory)
    {
        return orderedEndBlocks;
    }

    /// @dev Give Total reward amount of stakeContract(_account)
    /// @return Total reward amount of stakeContract(_account)
    function totalRewardAmount(address _account)
        external
        view
        override
        returns (uint256)
    {
        return stakeInfos[_account].totalRewardAmount;
    }

    /// @dev Give the infomation of this vault
    /// @return [paytoken,defiAddr], cap, stakeType, [saleStartBlock, stakeStartBlock, stakeEndBlock], blockTotalReward, saleClosed
    function infos()
        external
        view
        override
        returns (
            address[2] memory,
            uint256,
            uint256,
            uint256[3] memory,
            uint256,
            bool
        )
    {
        return (
            [paytoken, defiAddr],
            cap,
            stakeType,
            [saleStartBlock, stakeStartBlock, stakeEndBlock],
            blockTotalReward,
            saleClosed
        );
    }
}
