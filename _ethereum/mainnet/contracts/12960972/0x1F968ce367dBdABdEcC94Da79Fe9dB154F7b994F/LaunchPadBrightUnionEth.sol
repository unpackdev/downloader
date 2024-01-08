// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract LaunchPadBrightUnionEth is Ownable {
    using SafeMath for uint256;

    // 4 rounds : 0 = not open, 1 = guaranty round, 2 = First come first serve, 3 = sale finished
    uint256 public round1BeganAt;
    uint256 public claimUnlockedTimestamp; // init timestamp of claim begins

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

    uint256 constant round1Duration = 3600; // in secondes 3600 = 1h

    // Add from LaunchPad initial contract
    uint256 public firstVestingUnlockTimestamp;
    uint256 public secondVestingUnlockTimestamp;
    //uint256 public thirdVestingUnlockTimestamp;

    // Add from LaunchPad initial contract
    mapping(address => bool) _initialClaimDone;
    mapping(address => uint256) _firstVestingAmount;
    mapping(address => uint256) _secondVestingAmount;
    //mapping(address => uint256) _thirdVestingAmount;

    IERC20 public immutable token;

    constructor(IERC20 _token) {
        token = _token;
    }

    mapping(address => bool) public isWhitelisted; // used for front end when user have claim and used his allowances
    mapping(address => uint256) public round1Allowance;
    mapping(address => uint256) public round2Allowance;

    uint256 public tokenTarget;
    uint256 public weiTarget;
    uint256 public multiplier;

    bool public endUnlocked;

    uint256 public totalOwed;
    mapping(address => uint256) public claimable;
    mapping(address => uint256) public claimed;
    uint256 public weiRaised;

    uint256 public participants;

    event StartSale(uint256 startTimestamp);
    event EndUnlockedEvent(uint256 endTimestamp);
    event ClaimUnlockedEvent(uint256 claimTimestamp);

    event RoundChange(uint256 roundNumber);

    function initSale(uint256 _tokenTarget, uint256 _weiTarget)
        external
        onlyOwner
    {
        require(_weiTarget > 0, "wei target can't be Zero");
        require(_tokenTarget > 0, "token target can't be Zero");
        tokenTarget = _tokenTarget;
        weiTarget = _weiTarget;
        multiplier = tokenTarget.div(weiTarget);
    }

    // Add from LaunchPad initial contract
    // initiate vesting timestamp
    function initVestingsTimestamp(uint256 _first, uint256 _second)
        external
        onlyOwner
    {
        require(
            _second > _first && _first > block.timestamp,
            "No good timestamp"
        );
        firstVestingUnlockTimestamp = _first;
        secondVestingUnlockTimestamp = _second;
        //thirdVestingUnlockTimestamp = _third;
    }

    function getRound1Duration() external view returns (uint256) {
        return round1Duration;
    }

    function claimUnlocked() external view returns (bool) {
        return _claimUnlocked();
    }

    function _claimUnlocked() internal view returns (bool) {
        return (block.timestamp >= claimUnlockedTimestamp);
    }

    function setTokenTarget(uint256 _tokenTarget) external onlyOwner {
        require(_roundNumber() == 0, "Presale already started!");
        tokenTarget = _tokenTarget;
        multiplier = tokenTarget.div(weiTarget);
    }

    function setStableTarget(uint256 _weiTarget) external onlyOwner {
        require(_roundNumber() == 0, "Presale already started!");
        weiTarget = _weiTarget;
        multiplier = tokenTarget.div(weiTarget);
    }

    function startSale() external onlyOwner {
        require(_roundNumber() == 0, "Presale round isn't 0");

        round1BeganAt = block.timestamp;
        emit StartSale(block.timestamp);
    }

    function finishSale() external onlyOwner {
        require(!endUnlocked, "Presale already ended!");

        endUnlocked = true;
        emit EndUnlockedEvent(block.timestamp);
    }

    function addWhitelistedAddress(address _address, uint256 _allocation)
        external
        onlyOwner
    {
        isWhitelisted[_address] = true;
        round1Allowance[_address] = _allocation;
        round2Allowance[_address] = _allocation.mul(2);
    }

    function addMultipleWhitelistedAddressesMultiplier4(
        address[] calldata _addresses,
        uint256[] calldata _allocations
    ) external onlyOwner {
        require(
            _addresses.length == _allocations.length,
            "Issue in _addresses and _allocations length"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            isWhitelisted[_addresses[i]] = true;
            round1Allowance[_addresses[i]] = _allocations[i];
            round2Allowance[_addresses[i]] = _allocations[i].mul(4); // here to param allowance to round 2
        }
    }

    function addMultipleWhitelistedAddressesMultiplier1(
        address[] calldata _addresses,
        uint256[] calldata _allocations
    ) external onlyOwner {
        require(
            _addresses.length == _allocations.length,
            "Issue in _addresses and _allocations length"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            isWhitelisted[_addresses[i]] = true;
            round1Allowance[_addresses[i]] = _allocations[i];
            round2Allowance[_addresses[i]] = _allocations[i]; // here to param allowance to round 2
        }
    }

    // Add from LaunchPad initial contract
    // add allocations for round 2
    // This function can update an existing allocation
    function addMultipleWhitelistedAddressesForRound2(
        address[] calldata _addresses,
        uint256[] calldata _allocations
    ) external onlyOwner {
        require(
            _addresses.length == _allocations.length,
            "Issue in _addresses and _allocations length"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!isWhitelisted[_addresses[i]]) {
                isWhitelisted[_addresses[i]] = true;
            }
            if (round2Allowance[_addresses[i]] != _allocations[i]) {
                round2Allowance[_addresses[i]] = _allocations[i];
            }
        }
    }

    function removeWhitelistedAddress(address _address) external onlyOwner {
        isWhitelisted[_address] = false;
        round1Allowance[_address] = 0;
        round2Allowance[_address] = 0;
    }

    function withdrawWei(uint256 _amount) external onlyOwner {
        require(endUnlocked, "presale has not yet ended");
        (bool _sent, ) = msg.sender.call{value: _amount}("");
        require(_sent, "Error in Transfer");
    }

    //update from original contract
    function claimableAmount(address user) external view returns (uint256) {
        uint256 amount;

        if (!_claimUnlocked()) {
            amount = 0;
        } else if (claimable[msg.sender] > 0) {
            uint256 _toClaim = claimable[user].mul(multiplier);
            amount = _toClaim.mul(3000).div(10000);
        } else if (
            _firstVestingAmount[user] > 0 &&
            block.timestamp >= firstVestingUnlockTimestamp
        ) {
            amount = _firstVestingAmount[user];
        } else if (
            _secondVestingAmount[user] > 0 &&
            block.timestamp >= secondVestingUnlockTimestamp
        ) {
            amount = _secondVestingAmount[user];
        }
        //  else if (
        //     _thirdVestingAmount[user] > 0 &&
        //     block.timestamp >= thirdVestingUnlockTimestamp
        // ) {
        //     amount = _thirdVestingAmount[user];
        // }
        return amount;
    }

    // Add from LaunchPad initial contract
    function remainToClaim(address user) external view returns (uint256) {
        uint256 amount;
        if (claimable[user] > 0) {
            amount = claimable[user].mul(multiplier);
        } else {
            amount = _firstVestingAmount[user].add(_secondVestingAmount[user]);
            //.add(_thirdVestingAmount[user]);
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

    // function update from initial Smart contract
    //
    function claim() external returns (bool) {
        require(_claimUnlocked(), "claiming not allowed yet");
        if (!_initialClaimDone[msg.sender]) {
            require(claimable[msg.sender] > 0, "nothing to claim");
        } else {
            require(
                (_firstVestingAmount[msg.sender] > 0 &&
                    block.timestamp >= firstVestingUnlockTimestamp) ||
                    (_secondVestingAmount[msg.sender] > 0 &&
                        block.timestamp >= secondVestingUnlockTimestamp),
                //     ||
                // (_thirdVestingAmount[msg.sender] > 0 &&
                //     block.timestamp >= thirdVestingUnlockTimestamp)
                //     ,
                "nothing to claim for the moment"
            );
        }

        uint256 amount;

        if (!_initialClaimDone[msg.sender]) {
            _initialClaimDone[msg.sender] = true;
            uint256 _toClaim = claimable[msg.sender].mul(multiplier);
            claimable[msg.sender] = 0;

            amount = _toClaim.mul(3000).div(10000);
            _toClaim = _toClaim.sub(amount);
            _firstVestingAmount[msg.sender] = _toClaim.div(2);
            _secondVestingAmount[msg.sender] = _toClaim.div(2);
            //_thirdVestingAmount[msg.sender] = _toClaim.div(4);
        } else if (
            _firstVestingAmount[msg.sender] > 0 &&
            block.timestamp >= firstVestingUnlockTimestamp
        ) {
            amount = _firstVestingAmount[msg.sender];
            _firstVestingAmount[msg.sender] = 0;
        } else if (
            _secondVestingAmount[msg.sender] > 0 &&
            block.timestamp >= secondVestingUnlockTimestamp
        ) {
            amount = _secondVestingAmount[msg.sender];
            _secondVestingAmount[msg.sender] = 0;
        }
        // else if (
        //     _thirdVestingAmount[msg.sender] > 0 &&
        //     block.timestamp >= thirdVestingUnlockTimestamp
        // ) {
        //     amount = _thirdVestingAmount[msg.sender];
        //     _thirdVestingAmount[msg.sender] = 0;
        // }

        claimed[msg.sender] = claimed[msg.sender].add(amount);
        totalOwed = totalOwed.sub(amount);

        return token.transfer(msg.sender, amount);
    }

    function buyRound1() public payable {
        require(_roundNumber() == 1, "presale isn't on good round");
        require(msg.value > 0, "amount too low");
        require(weiRaised.add(msg.value) <= weiTarget, "Target already hit");
        require(
            round1Allowance[msg.sender] >= msg.value,
            "Amount too high or not white listed"
        );

        uint256 amount = msg.value.mul(multiplier);
        require(
            totalOwed.add(amount) <= token.balanceOf(address(this)),
            "sold out"
        );

        round1Allowance[msg.sender] = round1Allowance[msg.sender].sub(
            msg.value,
            "Maximum purchase cap hit"
        );

        if (claimable[msg.sender] == 0) participants = participants.add(1);

        claimable[msg.sender] = claimable[msg.sender].add(msg.value);
        totalOwed = totalOwed.add(amount);
        weiRaised = weiRaised.add(msg.value);
    }

    function buyRound2() public payable {
        require(_roundNumber() == 2, "Not the good round");
        require(msg.value > 0, "amount too low");
        require(
            round2Allowance[msg.sender] > 0,
            "you don't have round2 allowance"
        );
        require(weiRaised.add(msg.value) <= weiTarget, "target already hit");

        round2Allowance[msg.sender] = round2Allowance[msg.sender].sub(
            msg.value,
            "Maximum purchase cap hit"
        );

        uint256 amount = msg.value.mul(multiplier);
        require(
            totalOwed.add(amount) <= token.balanceOf(address(this)),
            "sold out"
        );

        if (claimable[msg.sender] == 0) participants = participants.add(1);

        claimable[msg.sender] = claimable[msg.sender].add(msg.value);
        totalOwed = totalOwed.add(amount);
        weiRaised = weiRaised.add(msg.value);
    }

    fallback() external payable {
        if (_roundNumber() == 1) {
            buyRound1();
        } else if (_roundNumber() == 2) {
            buyRound2();
        } else {
            revert();
        }
    }

    receive() external payable {
        if (_roundNumber() == 1) {
            buyRound1();
        } else if (_roundNumber() == 2) {
            buyRound2();
        } else {
            revert();
        }
    }
}
