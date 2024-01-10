// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/// @title NFP Token Contract
/// @author NFP Swap
/// @notice Basic govnernance token for the NFP project
contract NfpToken is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    uint private _initTime;
    uint private _mintEventCount;
    uint256 public _maxSupply = 1000000;
    uint256 public _totalTokens = 0;

    address[] private _founderAddresses;
    address private _devAddress;
    address private _salesAddress;
    address private _daoAddress;
    address private _rewardAddress;
    address private _airdropAddress;
    address private _stakingAddress;

    struct ScheduledMint {
        address to;
        uint year;
        uint256 amount;
        bool minted;
    }

    ScheduledMint[] public mintingSchedule;

    constructor(uint256 maxSupply) ERC20("NFP Token", "NFP") {
        _maxSupply = maxSupply;
        _initTime = block.timestamp;
        _mintEventCount = 0;
    }

    /// @notice This gets the number of uyears passed since deployment of contract
    function getYearsPassed() public view returns (uint) {
        uint currentTime = block.timestamp;
        uint timeDiff = currentTime.sub(_initTime);
        uint yearsPassed = timeDiff.div(365 days).div(10);
        return yearsPassed;
    }

    /// @notice Mints tokens based on pre-defined minting schedule
    function mint() public {
        require(_founderAddresses.length > 0, "Founder addresses not set");
        require(_devAddress > address(0), "Dev wallet address not set");
        require(_salesAddress > address(0), "Sales wallet address not set");
        require(_daoAddress > address(0), "Dao wallet address not set");
        require(_rewardAddress > address(0), "Reward contract address not set");
        require(
            _airdropAddress > address(0),
            "Airdrop contract address not set"
        );

        uint yearsPassed = getYearsPassed();

        for (uint i = 0; i < mintingSchedule.length; i++) {
            ScheduledMint memory scheduledMint = mintingSchedule[i];
            if (scheduledMint.year == yearsPassed && !scheduledMint.minted) {
                _mint(
                    scheduledMint.to,
                    scheduledMint.amount.mul(10**decimals())
                );
                mintingSchedule[i].minted = true;
                _totalTokens = _totalTokens.add(scheduledMint.amount);
            }
        }
    }

    /// @notice Burns token and updates totals
    function burn(uint256 amount) public virtual override {
        require(amount > 0, "Cannot burn 0 tokens");
        require(_totalTokens > amount, "Cannot burn more than total tokens");
        _totalTokens = _totalTokens.sub(amount);
        _maxSupply = _maxSupply.sub(amount);
        _burn(_msgSender(), amount.mul(10**decimals()));
    }

    /// @notice Creates the minting schedule for the project founder wallets
    function createFounderScheduledMints() private {
        for (uint i = 0; i < _founderAddresses.length; i++) {
            uint256 yearZeroFounderAmount = _maxSupply.mul(5).div(100).div(
                _founderAddresses.length
            );
            mintingSchedule.push(
                ScheduledMint(
                    _founderAddresses[i],
                    0,
                    yearZeroFounderAmount,
                    false
                )
            );
            uint256 yearlyFounderAmount = _maxSupply.mul(125).div(10000).div(
                _founderAddresses.length
            );
            mintingSchedule.push(
                ScheduledMint(
                    _founderAddresses[i],
                    1,
                    yearlyFounderAmount,
                    false
                )
            );
            mintingSchedule.push(
                ScheduledMint(
                    _founderAddresses[i],
                    2,
                    yearlyFounderAmount,
                    false
                )
            );
            mintingSchedule.push(
                ScheduledMint(
                    _founderAddresses[i],
                    3,
                    yearlyFounderAmount,
                    false
                )
            );
            mintingSchedule.push(
                ScheduledMint(
                    _founderAddresses[i],
                    4,
                    yearlyFounderAmount,
                    false
                )
            );
        }
    }

    /// @notice Create the minting schedule for the dev wallet
    function createDevScheduledMints() private {
        uint256 yearZeroDevAmount = _maxSupply.mul(10).div(1000);
        mintingSchedule.push(
            ScheduledMint(_devAddress, 0, yearZeroDevAmount, false)
        );
        uint256 yearlyDevAmount = _maxSupply.mul(225).div(10000);
        mintingSchedule.push(
            ScheduledMint(_devAddress, 1, yearlyDevAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_devAddress, 2, yearlyDevAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_devAddress, 3, yearlyDevAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_devAddress, 4, yearlyDevAmount, false)
        );
    }

    /// @notice Creates the minting schedule for the sales wallet
    function createSalesScheduledMints() private {
        uint256 yearZeroSalesAmount = _maxSupply.mul(10).div(1000);
        mintingSchedule.push(
            ScheduledMint(_salesAddress, 0, yearZeroSalesAmount, false)
        );
        uint256 yearlySalesAmount = _maxSupply.mul(225).div(10000);
        mintingSchedule.push(
            ScheduledMint(_salesAddress, 1, yearlySalesAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_salesAddress, 2, yearlySalesAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_salesAddress, 3, yearlySalesAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_salesAddress, 4, yearlySalesAmount, false)
        );
    }

    /// @notice Creates the minting schedule for the DAO wallet
    function createDaoScheduledMints() private {
        uint256 yearlyDaoAmount = _maxSupply.mul(625).div(10000);
        mintingSchedule.push(
            ScheduledMint(_daoAddress, 1, yearlyDaoAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_daoAddress, 2, yearlyDaoAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_daoAddress, 3, yearlyDaoAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_daoAddress, 4, yearlyDaoAmount, false)
        );
    }

    /// @notice Creates the minting schedule for the reward wallet
    function createRewardScheduledMints() private {
        uint256 yearZeroRewardAmount = _maxSupply.mul(10).div(100);
        mintingSchedule.push(
            ScheduledMint(_rewardAddress, 0, yearZeroRewardAmount, false)
        );
        uint256 yearlyRewardAmount = _maxSupply.mul(5).div(100);
        mintingSchedule.push(
            ScheduledMint(_rewardAddress, 1, yearlyRewardAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_rewardAddress, 2, yearlyRewardAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_rewardAddress, 3, yearlyRewardAmount, false)
        );
        mintingSchedule.push(
            ScheduledMint(_rewardAddress, 4, yearlyRewardAmount, false)
        );
    }

    /// @notice Creates the minting schedule for the airdrop wallets
    function createAirdropScheduledMints() private {
        uint256 yearZeroAirdropAmount = _maxSupply.mul(15).div(100);
        mintingSchedule.push(
            ScheduledMint(_airdropAddress, 0, yearZeroAirdropAmount, false)
        );
    }

    /// @notice Sets the distribution addresses for the schedules mint events
    function setDistributionAddresses(
        address[] memory founderAddresses,
        address devAddress,
        address salesAddress,
        address daoAddress,
        address rewardAddress,
        address airdropAddress
    ) public onlyOwner {
        require(
            founderAddresses.length > 0,
            "Must have at least one founder address"
        );
        for (uint i = 0; i < founderAddresses.length; i++) {
            require(
                founderAddresses[i] != address(0),
                "Founder addresses not set"
            );
        }
        require(devAddress != address(0), "Dev wallet address not set");
        require(salesAddress != address(0), "Sales wallet address not set");
        require(daoAddress != address(0), "Dao wallet address not set");
        require(rewardAddress != address(0), "Reward contract address not set");
        require(
            airdropAddress != address(0),
            "Aridrop contract address not set"
        );

        _founderAddresses = founderAddresses;
        createFounderScheduledMints();

        _devAddress = devAddress;
        createDevScheduledMints();

        _salesAddress = salesAddress;
        createSalesScheduledMints();

        _daoAddress = daoAddress;
        createDaoScheduledMints();

        _rewardAddress = rewardAddress;
        createRewardScheduledMints();

        _airdropAddress = airdropAddress;
        createAirdropScheduledMints();
    }

    /// @notice Sets the address for the staking
    function setStakingFarmAddress(address stakingAddress) public onlyOwner {
        require(stakingAddress != address(0), "Staking address not set");
        _stakingAddress = stakingAddress;
    }

    /// @notice Override for transfer from to allow transfer for trusted staking address with less gas spent
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        address spender = _msgSender();
        if (to != _stakingAddress) {
            _spendAllowance(from, spender, amount);
        }
        _transfer(from, to, amount);
        return true;
    }
}
