// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Treasury.sol";
import "./ISharedData.sol";

import "./IERC20.sol";

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

contract IDO is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    Treasury,
    ISharedData
{
    struct UserInfo {
        uint256 deposit;
        uint256 tokenInfoId;
        uint256 claimedAmount;
        uint256 refundedAmount;
    }

    struct TokenInfo {
        IERC20 token;
        // How much IDO tokens we will revice per 1 IERC20 token
        uint256 presaleRate;
        uint256 amount;
        bool isActive;
    }

    address[] public users;
    TokenInfo[] public tokenInfo;
    VestingInfo[] public vestingInfo;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Project token
    address public tokenAddress;
    uint256 public minimumContributionLimit;
    uint256 public maximumContributionLimit;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalCap;
    uint256 public startDepositTime;
    uint256 public endDepositTime;
    uint256 public depositCount;
    address public admin;
    address public manager;
    bool public isMainTokenAllowed;

    mapping(address => UserInfo) public allowanceToUserInfo;

    event Claim(address indexed user, uint256 amount);
    event Refund(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event DepositToken(
        address indexed currency,
        address indexed user,
        uint256 amount
    );

    event Debug(string key, uint256 value);

    function initialize(IDOParams memory params) public virtual initializer {
        __Pausable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, params._admin);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, params._manager);

        admin = params._admin;
        manager = params._manager;

        tokenAddress = params._tokenAddress;
        minimumContributionLimit = params._minimumContributionLimit;
        maximumContributionLimit = params._maximumContributionLimit;
        softCap = params._softCap;
        hardCap = params._hardCap;

        isMainTokenAllowed = params._presaleRate == 0 ? false : true;

        startDepositTime = params._startDepositTime;
        endDepositTime = params._endDepositTime;

        tokenAddress = params._tokenAddress;
        depositCount = 0;

        for (uint256 index = 0; index < params._vestingInfo.length; index++) {
            vestingInfo.push(
                VestingInfo(
                    params._vestingInfo[index]._time,
                    params._vestingInfo[index]._percent
                )
            );
        }

        if (isMainTokenAllowed) {
            tokenInfo.push(
                TokenInfo({
                    presaleRate: params._presaleRate,
                    token: IERC20(address(0)),
                    amount: 0,
                    isActive: true
                })
            );
        } else {
            uint256 tokensLength = params._tokens.length;

            for (uint256 index = 0; index < tokensLength; index++) {
                addToken(
                    IERC20(params._tokens[index]._tokenAddress),
                    params._tokens[index]._presaleRate
                );
            }
        }
    }

    function userInfoList() public view returns (address[] memory) {
        return users;
    }

    function tokenInfoList() public view returns (TokenInfo[] memory) {
        return tokenInfo;
    }

    function isClaimAllowed() public view returns (bool) {
        return block.timestamp > vestingInfo[0]._time;
    }

    function isClaimOrRefund() public view returns (uint256 result) {
        if (block.timestamp > vestingInfo[0]._time) {
            result = 1;
            if (isMainTokenAllowed) {
                uint256 idoBalance = address(this).balance;
                if (idoBalance < softCap) {
                    result = 2;
                }
            } else {
                if (totalCap < softCap) {
                    result = 2;
                }
            }
        }
    }

    function vestingLength() public view returns (uint256) {
        return vestingInfo.length;
    }

    function deposit() public payable virtual whenNotPaused {
        require(isMainTokenAllowed);
        _deposirRequire(msg.sender, msg.value);

        allowanceToUserInfo[msg.sender].deposit = msg.value;

        depositCount++;
        users.push(msg.sender);
        totalCap = totalCap + msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function depositToken(IERC20 currency, uint256 amount)
        public
        whenNotPaused
    {
        require(!isMainTokenAllowed);

        _deposirRequire(msg.sender, amount);
        uint256 tokenInfoId = getTokenInfoId(currency);

        uint256 amountToProcess = amount;

        if (currency == IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)) {
            amountToProcess = amount / 1000000000000;
        }

        if (
            currency == IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7) ||
            currency == IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)
        ) {
            amountToProcess = amount / 1000000000000;
        }

        _takeMoneyFromSender(currency, msg.sender, amountToProcess);
        allowanceToUserInfo[msg.sender].deposit = amount;
        allowanceToUserInfo[msg.sender].tokenInfoId = tokenInfoId;
        depositCount++;

        users.push(msg.sender);

        addTokenInfoAmount(tokenInfoId, amount);

        emit DepositToken(msg.sender, msg.sender, amount);
    }

    function claim() public virtual whenNotPaused {
        if (isMainTokenAllowed) {
            uint256 idoBalance = address(this).balance;
            require(idoBalance >= softCap);
        } else {
            require(totalCap >= softCap);
        }

        require(block.timestamp > vestingInfo[0]._time, "Claim not started");
        require(
            allowanceToUserInfo[msg.sender].deposit > 0,
            "You don't have an allocation to Claim"
        );

        TokenInfo storage _tokenInfo = tokenInfo[
            allowanceToUserInfo[msg.sender].tokenInfoId
        ];

        uint256 allowedPercentage = 0;

        for (uint256 index = 0; index < vestingInfo.length; index++) {
            if (block.timestamp > vestingInfo[index]._time) {
                allowedPercentage += vestingInfo[index]._percent;
            }
        }

        uint256 claimAmount = (_tokenInfo.presaleRate *
            allowanceToUserInfo[msg.sender].deposit) / (1 ether);

        require(
            claimAmount > allowanceToUserInfo[msg.sender].claimedAmount,
            "Clamed all allocation"
        );

        uint256 calculatedClaimAmount = (claimAmount * allowedPercentage) /
            (1 ether) /
            100;

        calculatedClaimAmount -= allowanceToUserInfo[msg.sender].claimedAmount;

        require(calculatedClaimAmount > 0, "Zero transfer");

        uint256 amountToProcess = calculatedClaimAmount;

        if (
            IERC20(tokenAddress) ==
            IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
        ) {
            amountToProcess = calculatedClaimAmount * 1000000000000;
        }

        IERC20(tokenAddress).transfer(msg.sender, amountToProcess);

        allowanceToUserInfo[msg.sender].claimedAmount += calculatedClaimAmount;
        emit Claim(msg.sender, calculatedClaimAmount);
    }

    function refund() public virtual whenNotPaused {
        require(block.timestamp > endDepositTime, "Claim not started");
        require(
            allowanceToUserInfo[msg.sender].refundedAmount == 0,
            "You have already claimed"
        );
        require(
            allowanceToUserInfo[msg.sender].deposit > 0,
            "You don't have an allocation to Claim"
        );
        uint256 amount = 0;
        if (isMainTokenAllowed) {
            uint256 idoBalance = address(this).balance;
            require(idoBalance <= softCap);
            amount = allowanceToUserInfo[msg.sender].deposit;

            payable(msg.sender).transfer(amount);
        } else {
            require(totalCap <= softCap);
            amount = allowanceToUserInfo[msg.sender].deposit;
            IERC20 token = tokenInfo[
                allowanceToUserInfo[msg.sender].tokenInfoId
            ].token;
            token.transfer(msg.sender, amount);
        }

        allowanceToUserInfo[msg.sender].refundedAmount = amount;
        emit Refund(msg.sender, amount);
    }

    function transferBalance(uint256 tokenId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        require(block.timestamp > endDepositTime, "IDO in progress");

        if (isMainTokenAllowed) {
            uint256 idoBalance = address(this).balance;
            require(idoBalance >= softCap);
            payable(msg.sender).transfer(idoBalance);
        } else {
            uint256 amountToProcess = tokenInfo[tokenId].amount;

            if (
                address(tokenInfo[tokenId].token) ==
                0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
            ) {
                amountToProcess = tokenInfo[tokenId].amount / 1000000000000;
            }
            _sendMoneyToIDOOwner(
                tokenInfo[tokenId].token,
                msg.sender,
                amountToProcess
            );
        }
    }

    function updateTokenAddress(address _address)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAddress = _address;
    }

    function updateStartDepositTime(uint256 _time)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(_time < endDepositTime, "Should be less than endDepositTime");
        startDepositTime = _time;
    }

    function updateEndDepositTime(uint256 _time) public onlyRole(MANAGER_ROLE) {
        require(
            _time > startDepositTime,
            "Should be more than startDepositTime"
        );

        endDepositTime = _time;
    }

    function updateStartClaimTime(VestingInfoParams memory params)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(params._vestingInfo.length > 0, "vesting Info needed");

        require(
            params._vestingInfo[0]._time > endDepositTime,
            "Start Claim Time should be more than End Deposit Time"
        );

        for (
            uint256 index = 0;
            index < params._vestingInfo.length - 1;
            index++
        ) {
            require(
                params._vestingInfo[index + 1]._time >=
                    params._vestingInfo[index]._time,
                "Each vesting time should be equal or more then previous"
            );
        }

        for (uint256 index = 0; index < params._vestingInfo.length; index++) {
            delete vestingInfo[index];
            vestingInfo[index] = VestingInfo(
                params._vestingInfo[index]._time,
                params._vestingInfo[index]._percent
            );
        }
    }

    function updateSoftCap(uint256 _softCap) public onlyRole(MANAGER_ROLE) {
        softCap = _softCap;
    }

    function updateHardCap(uint256 _hardCap) public onlyRole(MANAGER_ROLE) {
        hardCap = _hardCap;
    }

    function updateMinimumContributionLimit(uint256 _limit)
        public
        onlyRole(MANAGER_ROLE)
    {
        minimumContributionLimit = _limit;
    }

    function updateMaximumContributionLimit(uint256 _limit)
        public
        onlyRole(MANAGER_ROLE)
    {
        maximumContributionLimit = _limit;
    }

    function addToken(IERC20 _token, uint256 _price)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(!isMainTokenAllowed);

        tokenInfo.push(
            TokenInfo({
                token: _token,
                presaleRate: _price,
                amount: 0,
                isActive: true
            })
        );
    }

    function multiAddToken(IERC20[] memory _tokens, uint256[] memory _prices)
        public
        onlyRole(MANAGER_ROLE)
    {
        require(!isMainTokenAllowed);

        require(
            _tokens.length == _prices.length,
            "_tokens and _prices should has the same length"
        );
        uint256 length = _tokens.length;
        for (uint256 id = 0; id < length; ++id) {
            addToken(_tokens[id], _prices[id]);
        }
    }

    function transferToken(address to) public onlyRole(MANAGER_ROLE) {
        uint256 idoBalance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(to, idoBalance);
    }

    function deactivateToken(uint256 id) public {
        tokenInfo[id].isActive = false;
    }

    function activateToken(uint256 id) public {
        tokenInfo[id].isActive = true;
    }

    function pause() public onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function getTokenInfoId(IERC20 _token) private view returns (uint256) {
        uint256 length = tokenInfo.length;
        uint256 id = 0;
        for (id; id < length; ++id) {
            if (_token == tokenInfo[id].token) {
                break;
            }
        }

        return id;
    }

    function addTokenInfoAmount(uint256 _tokenId, uint256 _amount) private {
        tokenInfo[_tokenId].amount = tokenInfo[_tokenId].amount + _amount;
        totalCap = totalCap + _amount;
    }

    function _deposirRequire(address sender, uint256 amount) private view {
        require(block.timestamp > startDepositTime, "IDO not started");
        require(block.timestamp < endDepositTime, "IDO canceled");
        require(
            allowanceToUserInfo[sender].deposit == 0,
            "You have already made a deposit"
        );
        uint256 tempTotalCap = totalCap + amount;
        require(tempTotalCap <= hardCap, "The totalCap exceeds the HardCap");

        require(
            amount >= minimumContributionLimit,
            "Value is less than min allowed"
        );
        require(
            amount <= maximumContributionLimit,
            "Value is more than max allowed"
        );
        require(totalCap <= hardCap, "HardCap is filled");
    }
}
