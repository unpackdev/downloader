//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./IERC677Receiver.sol";

contract TiersV1 is IERC677Receiver, Initializable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct UserInfo {
        uint256 lastFeeGrowth;
        uint256 lastDeposit;
        uint256 lastWithdraw;
        mapping(address => uint256) amounts;
    }

    uint256 private constant PRECISION = 1e8;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG");
    bool public pausedDeposit;
    bool public pausedWithdraw;
    address public dao;
    IERC20Upgradeable public rewardToken;
    IERC20Upgradeable public votersToken;
    mapping(address => uint256) public totalAmounts;
    uint256 public lastFeeGrowth;
    mapping(address => UserInfo) public userInfos;
    address[] public users;
    mapping(address => uint256) public tokenRates;
    EnumerableSetUpgradeable.AddressSet private tokens;
    mapping(address => uint256) public nftRates;
    EnumerableSetUpgradeable.AddressSet private nfts;
    uint256[50] private __gap;

    event TokenUpdated(address token, uint256 rate);
    event NftUpdated(address token, uint256 rate);
    event DepositPaused(bool paused);
    event WithdrawPaused(bool paused);
    event Donate(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event WithdrawNow(address indexed user, uint256 amount, address indexed to);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _owner, address _dao, address _rewardToken, address _votersToken) public initializer {
        __ReentrancyGuard_init();
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CONFIG_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _owner);
        _setupRole(CONFIG_ROLE, _owner);
        dao = _dao;
        rewardToken = IERC20Upgradeable(_rewardToken);
        votersToken = IERC20Upgradeable(_votersToken);
        lastFeeGrowth = 1;
    }

    function updateToken(address[] calldata _tokens, uint256[] calldata _rates) external onlyRole(CONFIG_ROLE) {
        require(_tokens.length == _rates.length, "tokens and rates length");
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            require(token != address(0), "token is zero");
            require(token != address(votersToken), "do not add voters to tokens");
            tokens.add(token);
            tokenRates[token] = _rates[i];
            emit TokenUpdated(token, _rates[i]);
        }
    }

    function updateNft(address _token, uint _rate) external onlyRole(CONFIG_ROLE) {
        require(_token != address(0), "token is zero");
        nfts.add(_token);
        nftRates[_token] = _rate;
        emit NftUpdated(_token, _rate);
    }

    function updateVotersToken(address _token) external onlyRole(CONFIG_ROLE) {
        require(_token != address(0), "token is zero");
        votersToken = IERC20Upgradeable(_token);
    }

    function updateVotersTokenRate(uint _rate) external onlyRole(CONFIG_ROLE) {
        tokenRates[address(votersToken)] = _rate;
    }

    function updateDao(address _dao) external onlyRole(CONFIG_ROLE) {
        require(_dao != address(0), "address is zero");
        dao = _dao;
    }

    function togglePausedDeposit() external onlyRole(CONFIG_ROLE) {
        pausedDeposit = !pausedDeposit;
        emit DepositPaused(pausedDeposit);
    }

    function togglePausedWithdraw() external onlyRole(CONFIG_ROLE) {
        pausedWithdraw = !pausedWithdraw;
        emit WithdrawPaused(pausedWithdraw);
    }

    function totalAmount() public view returns (uint256 total) {
        uint256 length = tokens.length();
        for (uint256 i = 0; i < length; i++) {
            address token = tokens.at(i);
            total += totalAmounts[token] * tokenRates[token] / PRECISION;
        }
    }

    function usersList(uint page, uint pageSize) external view returns (address[] memory) {
        address[] memory list = new address[](pageSize);
        for (uint i = page * pageSize; i < (page + 1) * pageSize && i < users.length; i++) {
            list[i-(page*pageSize)] = users[i];
        }
        return list;
    }

    function userInfoPendingFees(address user, uint256 tokensOnlyTotal) public view returns (uint256) {
        return (tokensOnlyTotal * (lastFeeGrowth - userInfos[user].lastFeeGrowth)) / PRECISION;
    }

    function userInfoAmount(address user, address token) private view returns (uint256) {
        return userInfos[user].amounts[token];
    }

    function userInfoBalance(address user, address token) private view returns (uint256) {
        return IERC20Upgradeable(token).balanceOf(user);
    }

    function userInfoAmounts(address user) external view returns (uint256, uint256, address[] memory, uint256[] memory, uint256[] memory) {
        (uint256 tokensOnlyTotal, uint256 total) = userInfoTotal(user);
        uint256 tmp = tokens.length() + 1 + nfts.length();
        address[] memory addresses = new address[](tmp);
        uint256[] memory rates = new uint256[](tmp);
        uint256[] memory amounts = new uint256[](tmp);

        {
            uint256 tokensLength = tokens.length();
            for (uint256 i = 0; i < tokensLength; i++) {
                address token = tokens.at(i);
                addresses[i] = token;
                rates[i] = tokenRates[token];
                amounts[i] = userInfoAmount(user, token);
                if (token == address(rewardToken)) {
                    amounts[i] += userInfoPendingFees(user, tokensOnlyTotal);
                }
            }
        }

        tmp = tokens.length() + 1;
        addresses[tmp - 1] = address(votersToken);
        rates[tmp - 1] = tokenRates[address(votersToken)];
        amounts[tmp - 1] = votersToken.balanceOf(user);

        {
            uint256 nftLength = nfts.length();
            for (uint256 i = 0; i < nftLength; i++) {
                address token = nfts.at(i);
                addresses[tmp + i] = token;
                rates[tmp + i] = nftRates[token];
                amounts[tmp + i] = userInfoBalance(user, token);
            }
        }

        return (tokensOnlyTotal, total, addresses, rates, amounts);
    }

    function userInfoTotal(address user) public view returns (uint256, uint256) {
        uint256 total = 0;
        uint256 tokensLength = tokens.length();
        for (uint256 i = 0; i < tokensLength; i++) {
            address token = tokens.at(i);
            total += userInfos[user].amounts[token] * tokenRates[token] / PRECISION;
        }
        uint256 tokensOnlyTotal = total;
        total += votersToken.balanceOf(user) * tokenRates[address(votersToken)] / PRECISION;
        for (uint256 i = 0; i < nfts.length(); i++) {
            address token = nfts.at(i);
            if (IERC20Upgradeable(token).balanceOf(user) > 0) {
                total += nftRates[token];
            }
        }
        return (tokensOnlyTotal, total);
    }

    function _userInfo(address user) private returns (UserInfo storage, uint256, uint256) {
        require(user != address(0), "zero address provided");
        UserInfo storage userInfo = userInfos[user];
        (uint256 tokensOnlyTotal, uint256 total) = userInfoTotal(user);
        if (userInfo.lastFeeGrowth == 0) {
            users.push(user);
        } else {
            uint fees = (tokensOnlyTotal * (lastFeeGrowth - userInfo.lastFeeGrowth)) / PRECISION;
            userInfo.amounts[address(rewardToken)] += fees;
        }
        userInfo.lastFeeGrowth = lastFeeGrowth;
        return (userInfo, tokensOnlyTotal, total);
    }

    function donate(uint256 amount) external {
        _transferFrom(rewardToken, msg.sender, amount);
        lastFeeGrowth += (amount * PRECISION) / totalAmount();
        emit Donate(msg.sender, amount);
    }

    function deposit(address token, uint256 amount) external nonReentrant {
        require(!pausedDeposit, "paused");
        require(tokenRates[token] > 0, "not a supported token");
        (UserInfo storage userInfo,,) = _userInfo(msg.sender);

        _transferFrom(IERC20Upgradeable(token), msg.sender, amount);

        totalAmounts[token] += amount;
        userInfo.amounts[token] += amount;
        userInfo.lastDeposit = block.timestamp;

        emit Deposit(msg.sender, amount);
    }

    function onTokenTransfer(address user, uint amount, bytes calldata _data) external override {
        require(!pausedDeposit, "paused");
        require(msg.sender == address(rewardToken), "onTokenTransfer: not rewardToken");
        (UserInfo storage userInfo,,) = _userInfo(user);
        totalAmounts[address(rewardToken)] += amount;
        userInfo.amounts[address(rewardToken)] += amount;
        userInfo.lastDeposit = block.timestamp;
        emit Deposit(user, amount);
    }

    function withdraw(address token, uint256 amount, address to) external nonReentrant {
        (UserInfo storage user,,) = _userInfo(msg.sender);
        require(!pausedWithdraw, "paused");
        require(block.timestamp > user.lastDeposit + 7 days, "can't withdraw before 7 days after last deposit");

        totalAmounts[token] -= amount;
        user.amounts[token] -= amount;
        user.lastWithdraw = block.timestamp;

        IERC20Upgradeable(token).safeTransfer(to, amount);

        emit Withdraw(msg.sender, amount, to);
    }

    function withdrawNow(address token, uint256 amount, address to) external nonReentrant {
        (UserInfo storage user,,) = _userInfo(msg.sender);
        require(!pausedWithdraw, "paused");

        uint256 half = amount / 2;
        totalAmounts[token] -= amount;
        user.amounts[token] -= amount;
        user.lastWithdraw = block.timestamp;

        // If token is XRUNE, donate, else send to DAO
        if (token == address(rewardToken)) {
            lastFeeGrowth += (half * PRECISION) / totalAmount();
            emit Donate(msg.sender, half);
        } else {
            IERC20Upgradeable(token).safeTransfer(dao, half);
        }

        IERC20Upgradeable(token).safeTransfer(to, amount - half);

        emit WithdrawNow(msg.sender, amount, to);
    }

    function migrateRewards(uint256 amount) external onlyRole(ADMIN_ROLE) {
        rewardToken.safeTransfer(msg.sender, amount);
    }

    function _transferFrom(IERC20Upgradeable token, address from, uint256 amount) private {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore == amount, "_transferFrom: balance change does not match amount");
    }
}
