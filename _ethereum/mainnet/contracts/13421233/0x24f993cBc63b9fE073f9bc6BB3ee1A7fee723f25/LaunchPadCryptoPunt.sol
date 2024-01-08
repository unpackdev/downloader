// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract LaunchPadCryptoPunt is Ownable {
    using SafeMath for uint256;

    // 4 rounds : 0 = not open, 1 = guaranty round, 2 = First come first serve, 3 = sale finished

    uint256 public round1BeganAt;
    uint256 public claimUnlockedTimestamp;

    function roundNumber() external view returns (uint256) {
        return _roundNumber();
    }

    function _roundNumber() internal view returns (uint256) {
        uint256 _round;
        if (block.timestamp < round1BeganAt || round1BeganAt == 0) {
            _round = 0;
        } else if (
            block.timestamp >= round1BeganAt &&
            block.timestamp < round1BeganAt.add(round1Duration)
        ) {
            _round = 1;
        } else if (
            block.timestamp >= round1BeganAt.add(round1Duration) && !endUnlocked
        ) {
            _round = 2;
        } else if (endUnlocked) {
            _round = 3;
        }

        return _round;
    }

    function setRound1Timestamp(uint256 _round1BeginAt) external onlyOwner {
        round1BeganAt = _round1BeginAt;
    }

    function setClaimableTimestamp(uint256 _claimUnlockedTimestamp)
        external
        onlyOwner
    {
        claimUnlockedTimestamp = _claimUnlockedTimestamp;
    }

    uint256 public round1Duration = 3600; // in secondes 3600 = 1h

    uint256 public initialClaimablePercentage = 50;

    // Add from LaunchPad initial contract
    uint256 public firstVestingUnlockTimestamp; //

    // Add from LaunchPad initial contract
    mapping(address => bool) _initialClaimDone;
    mapping(address => uint256) _firstVestingAmount;

    IERC20 public token;
    IERC20 public stableCoin;

    constructor(IERC20 _stable) {
        stableCoin = _stable;
    }

    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    mapping(address => uint256) public round1Allowance;
    mapping(address => uint256) _round2Allowance;
    mapping(address => bool) _hasParticipated;

    function isWhitelisted(address _address) public view returns (bool) {
        bool result;
        if (_hasParticipated[_address]) {
            result = true;
        } else if (
            round1Allowance[_address] > 0 || _round2Allowance[_address] > 0
        ) {
            result = true;
        }
        return result;
    }

    function round2Allowance(address _address) public view returns (uint256) {
        uint256 result;
        if (_hasParticipated[_address]) {
            result = _round2Allowance[msg.sender];
        } else if (round1Allowance[_address] > 0) {
            result = round1Allowance[_address].mul(4);
        }
        return result;
    }

    uint256 public tokenTarget = 363636 * 1E18;
    uint256 public stableTarget = 7999992 * 1E16;
    uint256 public multiplier = 454; // div per 100

    bool public endUnlocked;

    uint256 public totalOwed;
    mapping(address => uint256) public claimable;
    mapping(address => uint256) public claimed;
    uint256 public stableRaised;

    uint256 public participants;

    // Add from LaunchPad initial contract
    // initiate vesting timestamp
    function initVestingsTimestamp(uint256 _first) external onlyOwner {
        require(_first > block.timestamp, "No good timestamp");
        firstVestingUnlockTimestamp = _first;
    }

    function claimUnlocked() external view returns (bool) {
        return _claimUnlocked();
    }

    function _claimUnlocked() internal view returns (bool) {
        return (block.timestamp >= claimUnlockedTimestamp);
    }

    function finishSale() external onlyOwner {
        require(!endUnlocked, "Presale already ended!");
        endUnlocked = true;
    }

    function addWhitelistedAddress(address _address, uint256 _allocation)
        external
        onlyOwner
    {
        round1Allowance[_address] = _allocation;
    }

    function addMultipleWhitelistedAddresses(
        address[] calldata _addresses,
        uint256[] calldata _allocations
    ) external onlyOwner {
        require(
            _addresses.length == _allocations.length,
            "Issue in _addresses and _allocations length"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            round1Allowance[_addresses[i]] = _allocations[i];
        }
    }

    function removeWhitelistedAddress(address _address) external onlyOwner {
        round1Allowance[_address] = 0;
    }

    function withdrawStable() external onlyOwner returns (bool) {
        require(endUnlocked, "presale has not yet ended");

        return
            stableCoin.transfer(
                msg.sender,
                stableCoin.balanceOf(address(this))
            );
    }

    //update from original contract
    function claimableAmount(address user) external view returns (uint256) {
        return _claimableAmount(user);
    }

    function _claimableAmount(address user) internal view returns (uint256) {
        uint256 amount;

        if (claimable[user] > 0) {
            uint256 _toClaim = claimable[user].mul(multiplier).div(100);
            amount = _toClaim.mul(initialClaimablePercentage).div(100);
        }
        if (block.timestamp > firstVestingUnlockTimestamp) {
            if (_firstVestingAmount[user] > 0) {
                amount = _firstVestingAmount[user];
            } else {
                uint256 _toClaim = claimable[user].mul(multiplier).div(100);
                amount = _toClaim;
            }
        }
        return amount;
    }

    // Add from LaunchPad initial contract
    function remainToClaim(address user) external view returns (uint256) {
        uint256 amount;
        if (claimable[user] > 0) {
            amount = claimable[user].mul(multiplier).div(100);
        } else {
            amount = _firstVestingAmount[user];
        }
        return amount;
    }

    function withdrawToken() external onlyOwner returns (bool) {
        require(endUnlocked, "presale has not yet ended");

        return
            token.transfer(
                msg.sender,
                token.balanceOf(address(this)).sub(totalOwed)
            );
    }

    function emergencyWithdrawToken(address _token)
        external
        onlyOwner
        returns (bool)
    {
        return
            IERC20(_token).transfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
    }

    // function update from initial Smart contract
    function claim() external returns (bool) {
        require(_claimUnlocked(), "claiming not allowed yet");
        if (!_initialClaimDone[msg.sender]) {
            require(claimable[msg.sender] > 0, "nothing to claim");
        } else {
            require(
                (_firstVestingAmount[msg.sender] > 0 &&
                    block.timestamp >= firstVestingUnlockTimestamp),
                "nothing to claim"
            );
        }

        uint256 amount;

        if (!_initialClaimDone[msg.sender]) {
            _initialClaimDone[msg.sender] = true;
            uint256 _toClaim = claimable[msg.sender].mul(multiplier).div(100);
            claimable[msg.sender] = 0;
            amount = _toClaim.mul(initialClaimablePercentage).div(100); // 50%
            _toClaim = _toClaim.sub(amount);

            _firstVestingAmount[msg.sender] = _toClaim; // 50% at first vesting (1month later)
        }
        if (
            _firstVestingAmount[msg.sender] > 0 &&
            block.timestamp >= firstVestingUnlockTimestamp
        ) {
            amount = amount.add(_firstVestingAmount[msg.sender]);

            _firstVestingAmount[msg.sender] = 0;
        }

        claimed[msg.sender] = claimed[msg.sender].add(amount);
        totalOwed = totalOwed.sub(amount);

        return token.transfer(msg.sender, amount);
    }

    function buyRound1Stable(uint256 _amount) external {
        require(_roundNumber() == 1, "presale isn't on good round");

        require(
            stableRaised.add(_amount) <= stableTarget,
            "Target already hit"
        );
        require(
            round1Allowance[msg.sender] >= _amount,
            "Amount too high or not white listed"
        );
        if (!_hasParticipated[msg.sender]) {
            _hasParticipated[msg.sender] = true;
            _round2Allowance[msg.sender] = round1Allowance[msg.sender].mul(4);
        }

        require(stableCoin.transferFrom(msg.sender, address(this), _amount));

        uint256 amount = _amount.mul(multiplier).div(100);

        require(totalOwed.add(amount) <= tokenTarget, "sold out");

        round1Allowance[msg.sender] = round1Allowance[msg.sender].sub(
            _amount,
            "Maximum purchase cap hit"
        );

        if (claimable[msg.sender] == 0) participants = participants.add(1);

        claimable[msg.sender] = claimable[msg.sender].add(_amount);
        totalOwed = totalOwed.add(amount);
        stableRaised = stableRaised.add(_amount);

        if (stableRaised == stableTarget) {
            endUnlocked = true;
        }
    }

    function buyRound2Stable(uint256 _amount) external {
        require(_roundNumber() == 2, "Not the good round");
        require(round2Allowance(msg.sender) > 0, "you are not whitelisted");
        require(_amount > 0, "amount too low");
        require(
            stableRaised.add(_amount) <= stableTarget,
            "target already hit"
        );
        if (!_hasParticipated[msg.sender]) {
            _hasParticipated[msg.sender] = true;
            _round2Allowance[msg.sender] = round1Allowance[msg.sender].mul(4);
        }

        _round2Allowance[msg.sender] = _round2Allowance[msg.sender].sub(
            _amount,
            "Maximum purchase cap hit"
        );

        require(stableCoin.transferFrom(msg.sender, address(this), _amount));

        uint256 amount = _amount.mul(multiplier).div(100);
        require(totalOwed.add(amount) <= tokenTarget, "sold out");

        if (claimable[msg.sender] == 0) participants = participants.add(1);

        claimable[msg.sender] = claimable[msg.sender].add(_amount);
        totalOwed = totalOwed.add(amount);
        stableRaised = stableRaised.add(_amount);

        if (stableRaised == stableTarget) {
            endUnlocked = true;
        }
    }
}
