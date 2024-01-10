// SPDX-License-Identifier: LicenseRef-StarterLabs-Business-Source
/*
-----------------------------------------------------------------------------
The Licensed Work is (c) 2022 Starter Labs, LLC
Licensor:             Starter Labs, LLC
Licensed Work:        OpenStarter v1
Effective Date:       2022 March 1
Full License Text:    https://github.com/StarterXyz/LICENSE
-----------------------------------------------------------------------------
 */
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./OpenStarterLibrary.sol";

contract OpenStarterStaking is ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    OpenStarterLibrary public starterLibrary;

    event Staked(address indexed from, address _token, uint256 amount);
    event Unstaked(address indexed from, address _token, uint256 amount);

    struct AccountInfo {
        uint256[15] balances;
        uint256 lastStakedTimestamp;
        uint256 lastUnstakedTimestamp;
    }

    mapping(address => AccountInfo) public accounts;

    address[15] public stakingTokens; // Staking Tokens
    address[] public stakers; // Stakers Addresses
    uint256[15] public minStakeTime = [
        5 * 24 * 3600,
        7 * 24 * 3600,
        10 * 24 * 3600,
        14 * 24 * 3600
    ]; // MinStakeTime

    uint256 maxTierCount = 4;

    modifier onlyStarterDev() {
        require(
            msg.sender == starterLibrary.owner() ||
                starterLibrary.getStarterDev(msg.sender),
            "Dev Required"
        );
        _;
    }

    constructor(
        address _starterLibrary,
        address _apeToken,
        address _startToken,
        address _sosToken
    ) public {
        starterLibrary = OpenStarterLibrary(_starterLibrary);
        stakingTokens[0] = _apeToken;
        stakingTokens[1] = _startToken;
        stakingTokens[2] = _sosToken;
    }

    function stake(uint256 stakeTokenIndex, uint256 _amount)
        public
        nonReentrant
    {
        require(_amount > 0, "Invalid amount");

        ERC20(stakingTokens[stakeTokenIndex]).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        AccountInfo storage account = accounts[msg.sender];
        account.balances[stakeTokenIndex] = account
            .balances[stakeTokenIndex]
            .add(_amount);

        if (
            account.lastStakedTimestamp == 0 &&
            account.lastUnstakedTimestamp == 0
        ) {
            stakers.push(msg.sender);
        }

        if (account.lastStakedTimestamp == 0) {
            account.lastStakedTimestamp = block.timestamp;
        }

        emit Staked(msg.sender, stakingTokens[stakeTokenIndex], _amount);
    }

    function unstake(uint256 stakeTokenIndex, uint256 _amount)
        external
        nonReentrant
    {
        AccountInfo storage account = accounts[msg.sender];
        require(!address(msg.sender).isContract(), "No contracts");

        require(account.balances[stakeTokenIndex] > 0, "Nothing to unstake");
        require(_amount > 0, "Invalid amount");
        if (account.balances[stakeTokenIndex] < _amount) {
            _amount = account.balances[stakeTokenIndex];
        }
        account.balances[stakeTokenIndex] = account
            .balances[stakeTokenIndex]
            .sub(_amount);

        account.lastStakedTimestamp = 0; // reset earlier staking time
        account.lastUnstakedTimestamp = block.timestamp;
        ERC20(stakingTokens[stakeTokenIndex]).transfer(msg.sender, _amount);

        emit Unstaked(msg.sender, stakingTokens[stakeTokenIndex], _amount);
    }

    function getStakerTier(address _staker) public view returns (uint256) {
        uint256 userTier = 0;
        uint256 i = 0;
        for (i = 0; i < 5; i++) {
            uint256 userTokenTier = starterLibrary.getUserTier(
                i,
                accounts[_staker].balances[i] +
                    starterLibrary.getExternalStaked(i, _staker)
            );

            if (userTier < userTokenTier) {
                userTier = userTokenTier;
                if (userTier == maxTierCount)
                    // break if already in max tier
                    break;
            }
        }
        uint256 stakedTime = block.timestamp -
            (
                accounts[_staker].lastStakedTimestamp == 0
                    ? accounts[_staker].lastUnstakedTimestamp
                    : accounts[_staker].lastStakedTimestamp
            );

        for (i = 0; i < maxTierCount; i++) {
            if (stakedTime < minStakeTime[i]) {
                break;
            }
        }
        if (userTier > i) {
            return i;
        }
        return userTier;
    }

    function getStakerCount(uint256 _tier) public view returns (uint256) {
        uint256 i = 0;
        uint256 count = 0;
        uint256 stakersLen = stakers.length;
        for (i = 0; i < stakersLen; i++) {
            if (_tier == getStakerTier(stakers[i])) {
                count = count.add(1);
            }
        }
        return count;
    }

    function setLibrary(address _newInfo) external onlyStarterDev {
        starterLibrary = OpenStarterLibrary(_newInfo);
    }

    function getUserInfo(address _staker)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            getStakerTier(_staker),
            accounts[_staker].lastStakedTimestamp,
            accounts[_staker].lastUnstakedTimestamp
        );
    }

    function getUserBalances(address _staker)
        public
        view
        returns (uint256[15] memory)
    {
        return accounts[_staker].balances;
    }

    function setStakingToken(uint256 _index, address _tokenAddress)
        external
        onlyStarterDev
    {
        stakingTokens[_index] = _tokenAddress;
    }

    function setMaxTierCount(uint256 _tierCount) external onlyStarterDev {
        maxTierCount = _tierCount;
    }

    function setMinStakeTime(uint256 _index, uint256 _value)
        external
        onlyStarterDev
    {
        minStakeTime[_index] = _value;
    }
}
