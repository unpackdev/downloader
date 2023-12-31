// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";

contract CAT is Ownable {
    // TYPES //
    struct Stake {
        uint256 stake;
        uint256 notWithdrawn;
        uint256 timestamp;
        address partner;
        uint256 percentage;
    }
    // TYPES //

    // STORAGE //
    uint256 constant public hundredPercent = 10 ** 27;
    uint256 constant public referralLvls = 10;
    address constant public zeroAddress = 0x0000000000000000000000000000000000000000;

    uint256 public depositLvls;
    uint256 public minDepositValue;
    uint256 public withdrawFee;

    bool public depositPause;
    bool public reinvestPause;
    bool public withdrawPause;

    uint256[] public depositPercentages;
    uint256[] public depositAmount;
    uint256[referralLvls] public referralPercentages;

    mapping(address => bool) public left;
    mapping(address => Stake) public stake;
    mapping(address => mapping(uint256 => uint256)) public referralLvlRewards; // user => ref lvl => amount
    mapping(address => mapping(address => uint256)) public referralUserRewards; // user => invited up to 'referralLvls' => amount
    mapping(address => address[]) public referralUsers; // user => invited up to 'referralLvls'
    // STORAGE //

    // MODIFIERS //
    modifier depositNotPaused() {
        require(!depositPause, "paused");
        _;
    }

    modifier reinvestNotPaused() {
        require(!reinvestPause, "paused");
        _;
    }

    modifier withdrawNotPaused() {
        require(!withdrawPause, "paused");
        _;
    }
    // MODIFIERS //

    // MAIN //
    function deposit(address _partner) external payable depositNotPaused {
        require(msg.value >= minDepositValue, "invalidAmount");

        _updateNotWithdrawn();

        Stake memory _senderStake = stake[msg.sender];
        _senderStake.stake += msg.value;
        if (_senderStake.percentage == 0) {
            require(_partner != msg.sender, "invalidPartner");
            if (_partner != zeroAddress) {
                require(stake[_partner].percentage != 0, "invalidPartner");
            }
            _senderStake.partner = _partner;
        }
        stake[msg.sender] = _senderStake;

        _updatePercentage();
    }

    function reinvest(uint256 _amount) external reinvestNotPaused {
        require(_amount > 0, "invalidAmount");

        _updateNotWithdrawn();

        stake[msg.sender].notWithdrawn -= _amount;
        stake[msg.sender].stake += _amount;

        _updatePercentage();
    }

    function withdraw(uint256 _amount) external withdrawNotPaused {
        require(_amount > 0, "invalidAmount");
        require(!left[msg.sender], "left");

        _updateNotWithdrawn();

        uint256 _fee = _amount * withdrawFee / hundredPercent;
        stake[msg.sender].notWithdrawn -= _amount;

        payable(owner()).transfer(_fee);
        payable(msg.sender).transfer(_amount - _fee);
    }

    function _updateNotWithdrawn() private {
        uint256 _pending = getPendingReward(msg.sender);
        stake[msg.sender].timestamp = block.timestamp;
        stake[msg.sender].notWithdrawn += _pending;
        _traverseTree(msg.sender, stake[msg.sender].partner, _pending);
    }

    function _traverseTree(address _user, address _partner, uint256 _value) private {
        if (_value != 0) {
            for (uint256 i; i < referralLvls; i++) {
                if (_partner == zeroAddress) {
                    break;
                }
                uint256 _reward = _value * referralPercentages[i] / hundredPercent;

                stake[_partner].notWithdrawn += _reward;
                referralLvlRewards[_partner][i] += _reward;

                if (referralUserRewards[_partner][_user] == 0) {
                    referralUsers[_partner].push(_user);
                }
                referralUserRewards[_partner][_user] += _reward;

                _partner = stake[_partner].partner;
            }
        }
    }

    function _updatePercentage() private {
        uint256 _depositLvls = depositLvls;
        uint256 _stake = stake[msg.sender].stake;
        uint256[] memory _depositAmount = depositAmount;

        for (uint256 i; i < _depositLvls; i++) {
            if (_stake >= _depositAmount[i]) {
                stake[msg.sender].percentage = depositPercentages[i];
                break;
            }
        }
    }
    // MAIN //

    // SETTERS //
    function setDepositLvls(uint256 _newLvls, uint256[] calldata _newAmount, uint256[] calldata _newPercentages) external onlyOwner {
        depositLvls = _newLvls;

        uint256 _currentLength = depositAmount.length;

        if (_currentLength > _newLvls) {
            uint256 _toDelete = _currentLength - _newLvls;
            for (uint256 i; i < _toDelete; i++) {
                depositAmount.pop();
                depositPercentages.pop();
            }
        }

        if (_currentLength < _newLvls) {
            uint256 _toAdd = _newLvls - _currentLength;
            for (uint256 i; i < _toAdd; i++) {
                depositAmount.push(0);
                depositPercentages.push(0);
            }
        }

        setDepositAmount(_newAmount);
        setDepositPercentages(_newPercentages);
    }

    function setMinDepositValue(uint256 _value) external onlyOwner {
        minDepositValue = _value;
    }

    function setWithdrawFee(uint256 _value) external onlyOwner {
        withdrawFee = _value;
    }

    function setDepositPause(bool _value) external onlyOwner {
        depositPause = _value;
    }

    function setReinvestPause(bool _value) external onlyOwner {
        reinvestPause = _value;
    }

    function setWithdrawPause(bool _value) external onlyOwner {
        withdrawPause = _value;
    }

    function setDepositPercentages(uint256[] calldata _newPercentages) public onlyOwner {
        uint256 _depositLvls = depositLvls;
        require(_newPercentages.length == _depositLvls, "invalidLength");

        uint256 _limit = _depositLvls - 1;
        for (uint256 i; i < _limit; i++) {
            require(_newPercentages[i] > _newPercentages[i + 1], "invalidPercentages");
            depositPercentages[i] = _newPercentages[i];
        }
        depositPercentages[_limit] = _newPercentages[_limit];

        require(_newPercentages[_limit] != 0, "invalidPercentage");
    }

    function setDepositAmount(uint256[] calldata _newAmoun) public onlyOwner {
        uint256 _depositLvls = depositLvls;
        require(_newAmoun.length == _depositLvls, "invalidLength");

        uint256 _limit = _depositLvls - 1;
        for (uint256 i; i < _limit; i++) {
            require(_newAmoun[i] > _newAmoun[i + 1], "invalidAmount");
            depositAmount[i] = _newAmoun[i];
        }
        depositAmount[_limit] = _newAmoun[_limit];

        require(_newAmoun[_limit] != 0, "invalidAmount");
    }

    function setReferralPercentages(uint256[] calldata _newPercentages) external onlyOwner {
        require(_newPercentages.length == referralLvls, "invalidLength");

        uint256 _limit = referralLvls - 1;
        for (uint256 i; i < _limit; i++) {
            require(_newPercentages[i] > _newPercentages[i + 1], "invalidPercentages");
            referralPercentages[i] = _newPercentages[i];
        }
        referralPercentages[_limit] = _newPercentages[_limit];

        require(_newPercentages[_limit] != 0, "invalidPercentage");
    }

    function setNewPartner(address _user, address _newPartner) external onlyOwner {
        require(_user != zeroAddress, "invalidUser");
        require(_user != _newPartner, "invalidPartner");
        if (_newPartner != zeroAddress) {
            require(stake[_newPartner].percentage != 0, "invalidPartner");
        }

        stake[_user].partner = _newPartner;
    }

    function leaveCat(address[] calldata account, bool[] calldata _left) external onlyOwner {
        require(account.length == _left.length, "invalidLength");
        for (uint256 i; i < account.length; i++) {
            left[account[i]] = _left[i];
        }
    }

    function arbitrageTransfer(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
    // SETTERS //

    // GETTERS //
    function getPendingReward(address _account) public view returns(uint256) {
        Stake memory _stake = stake[_account];
        return ((_stake.stake * ((block.timestamp - _stake.timestamp) / 24 hours) * _stake.percentage) / hundredPercent);
    }

    function getReferralUsers(address _account) public view returns(address[] memory) {
        return referralUsers[_account];
    }

    function getReferralUsersLength(address _account) public view returns(uint256) {
        return referralUsers[_account].length;
    }

    function getReferralUsersIndexed(address _account, uint256 _from, uint256 _to) public view returns(address[] memory) {
        address[] memory _info = new address[](_to - _from);

        for(uint256 _index = 0; _from < _to; ++_index) {
            _info[_index] = referralUsers[_account][_from];
            _from++;
        }

        return _info;
    }

    function getDepositPercentages() public view returns(uint256[] memory) {
        return depositPercentages;
    }

    function getDepositPercentagesLength() public view returns(uint256) {
        return depositPercentages.length;
    }

    function getDepositPercentagesIndexed(uint256 _from, uint256 _to) public view returns(uint256[] memory) {
        uint256[] memory _info = new uint256[](_to - _from);

        for(uint256 _index = 0; _from < _to; ++_index) {
            _info[_index] = depositPercentages[_from];
            _from++;
        }

        return _info;
    }

    function getDepositAmount() public view returns(uint256[] memory) {
        return depositAmount;
    }

    function getDepositAmountLength() public view returns(uint256) {
        return depositAmount.length;
    }

    function getDepositAmountIndexed(uint256 _from, uint256 _to) public view returns(uint256[] memory) {
        uint256[] memory _info = new uint256[](_to - _from);

        for(uint256 _index = 0; _from < _to; ++_index) {
            _info[_index] = depositAmount[_from];
            _from++;
        }

        return _info;
    }

    function getReferralPercentages() public view returns(uint256[referralLvls] memory) {
        return referralPercentages;
    }
    // GETTERS //
}