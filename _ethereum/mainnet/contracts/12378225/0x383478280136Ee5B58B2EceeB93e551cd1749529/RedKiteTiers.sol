// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract RedKiteTiers is IERC721Receiver, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Info of each user
    struct UserInfo {
        uint256 staked; // How many tokens the user has provided
        uint256 stakedTime; // Block timestamp when the user provided token
    }

    // RedKiteTiers allow to stake multi tokens to up your tier. Please
    // visit the website to get token list or use the token contract to
    // check it is supported or not.

    // Info of each Token
    // Currency Rate with PKF: amount * rate / 10 ** decimals
    // Default PKF: rate=1, decimals=0
    struct ExternalToken {
        address contractAddress;
        uint256 decimals;
        uint256 rate;
        bool isERC721;
        bool canStake;
    }

    uint256 constant MAX_NUM_TIERS = 10;
    uint8 currentMaxTier = 4;

    // Address take user's withdraw fee
    address public penaltyWallet;
    // The POLKAFOUNDRY TOKEN!
    address public PKF;

    // Info of each user that stakes tokens
    mapping(address => mapping(address => UserInfo)) public userInfo;
    // Info of total Non-PKF token staked, converted with rate
    mapping(address => uint256) public userExternalStaked;
    // Minimum PKF need to stake each tier
    uint256[MAX_NUM_TIERS] tierPrice;
    // Percentage of penalties
    uint256[6] public withdrawFeePercent;
    // The maximum number of days of penalties
    uint256[5] public daysLockLevel;
    // Info of each token can stake
    mapping(address => ExternalToken) public externalToken;

    bool public canEmergencyWithdraw;

    event StakedERC20(address indexed user, address token, uint256 amount);
    event StakedSingleERC721(
        address indexed user,
        address token,
        uint128 tokenId
    );
    event StakedBatchERC721(
        address indexed user,
        address token,
        uint128[] tokenIds
    );
    event WithdrawnERC20(
        address indexed user,
        address token,
        uint256 indexed amount,
        uint256 fee,
        uint256 lastStakedTime
    );
    event WithdrawnSingleERC721(
        address indexed user,
        address token,
        uint128 tokenId,
        uint256 lastStakedTime
    );
    event WithdrawnBatchERC721(
        address indexed user,
        address token,
        uint128[] tokenIds,
        uint256 lastStakedTime
    );
    event EmergencyWithdrawnERC20(
        address indexed user,
        address token,
        uint256 amount,
        uint256 lastStakedTime
    );
    event EmergencyWithdrawnERC721(
        address indexed user,
        address token,
        uint128[] tokenIds,
        uint256 lastStakedTime
    );
    event AddExternalToken(
        address indexed token,
        uint256 decimals,
        uint256 rate,
        bool isERC721,
        bool canStake
    );
    event ExternalTokenStatsChange(
        address indexed token,
        uint256 decimals,
        uint256 rate,
        bool canStake
    );
    event ChangePenaltyWallet(address indexed penaltyWallet);

    constructor(address _pkf, address _sPkf, address _uniLp, address _penaltyWallet) {
        owner = msg.sender;
        penaltyWallet = _penaltyWallet;

        PKF = _pkf;

        addExternalToken(_pkf, 0, 1 , false, true);
        addExternalToken(_sPkf, 0, 1, false, true);
        addExternalToken(_uniLp, 0, 150, false, true);

        tierPrice[1] = 500e18;
        tierPrice[2] = 5000e18;
        tierPrice[3] = 20000e18;
        tierPrice[4] = 60000e18;

        daysLockLevel[0] = 10 days;
        daysLockLevel[1] = 20 days;
        daysLockLevel[2] = 30 days;
        daysLockLevel[3] = 60 days;
        daysLockLevel[4] = 90 days;
    }

    function depositERC20(address _token, uint256 _amount)
        external
        nonReentrant()
    {
        if (_token == PKF) {
            IERC20(PKF).transferFrom(msg.sender, address(this), _amount);
        } else {
            require(
                externalToken[_token].canStake == true,
                "TIER::TOKEN_NOT_ACCEPTED"
            );
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);

            ExternalToken storage token = externalToken[_token];
            userExternalStaked[msg.sender] = userExternalStaked[msg.sender].add(
                _amount.mul(token.rate).div(10**token.decimals)
            );
        }

        userInfo[msg.sender][_token].staked = userInfo[msg.sender][_token]
            .staked
            .add(_amount);
        userInfo[msg.sender][_token].stakedTime = block.timestamp;

        emit StakedERC20(msg.sender, _token, _amount);
    }

    function depositSingleERC721(address _token, uint128 _tokenId)
        external
        nonReentrant()
    {
        require(
            externalToken[_token].canStake == true,
            "TIER::TOKEN_NOT_ACCEPTED"
        );
        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenId);

        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].add(
            token.rate
        );

        userInfo[msg.sender][_token].staked = userInfo[msg.sender][_token]
            .staked
            .add(1);
        userInfo[msg.sender][_token].stakedTime = block.timestamp;

        emit StakedSingleERC721(msg.sender, _token, _tokenId);
    }

    function depositBatchERC721(address _token, uint128[] memory _tokenIds)
        external
        nonReentrant()
    {
        require(
            externalToken[_token].canStake == true,
            "TIER::TOKEN_NOT_ACCEPTED"
        );
        _batchSafeTransferFrom(_token, msg.sender, address(this), _tokenIds);

        uint256 amount = _tokenIds.length;
        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].add(
            amount.mul(token.rate)
        );

        userInfo[msg.sender][_token].staked = userInfo[msg.sender][_token]
            .staked
            .add(amount);
        userInfo[msg.sender][_token].stakedTime = block.timestamp;

        emit StakedBatchERC721(msg.sender, _token, _tokenIds);
    }

    function withdrawERC20(address _token, uint256 _amount)
        external
        nonReentrant()
    {
        UserInfo storage user = userInfo[msg.sender][_token];
        require(user.staked >= _amount, "not enough amount to withdraw");

        if (_token != PKF) {
            ExternalToken storage token = externalToken[_token];
            userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
                _amount.mul(token.rate).div(10**token.decimals)
            );
        }

        uint256 toPunish = calculateWithdrawFee(msg.sender, _token, _amount);
        if (toPunish > 0) {
            IERC20(_token).transfer(penaltyWallet, toPunish);
        }

        user.staked = user.staked.sub(_amount);

        IERC20(_token).transfer(msg.sender, _amount.sub(toPunish));
        emit WithdrawnERC20(
            msg.sender,
            _token,
            _amount,
            toPunish,
            user.stakedTime
        );
    }

    function withdrawSingleERC721(address _token, uint128 _tokenId)
        external
        nonReentrant()
    {
        UserInfo storage user = userInfo[msg.sender][_token];
        require(user.staked >= 1, "not enough amount to withdraw");

        user.staked = user.staked.sub(1);

        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
            token.rate
        );

        IERC721(_token).safeTransferFrom(address(this), msg.sender, _tokenId);
        emit WithdrawnSingleERC721(
            msg.sender,
            _token,
            _tokenId,
            user.stakedTime
        );
    }

    function withdrawBatchERC721(address _token, uint128[] memory _tokenIds)
        external
        nonReentrant()
    {
        UserInfo storage user = userInfo[msg.sender][_token];
        uint256 amount = _tokenIds.length;
        require(user.staked >= amount, "not enough amount to withdraw");

        user.staked = user.staked.sub(amount);

        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
            amount.mul(token.rate)
        );

        _batchSafeTransferFrom(_token, address(this), msg.sender, _tokenIds);
        emit WithdrawnBatchERC721(
            msg.sender,
            _token,
            _tokenIds,
            user.stakedTime
        );
    }

    function setPenaltyWallet(address _penaltyWallet) external onlyOwner {
        require(
            penaltyWallet != _penaltyWallet,
            "TIER::ALREADY_PENALTY_WALLET"
        );
        penaltyWallet = _penaltyWallet;

        emit ChangePenaltyWallet(_penaltyWallet);
    }

    function updateEmergencyWithdrawStatus(bool _status) external onlyOwner {
        canEmergencyWithdraw = _status;
    }

    function emergencyWithdrawERC20(address _token) external {
        require(canEmergencyWithdraw, "function disabled");
        UserInfo storage user = userInfo[msg.sender][_token];
        require(user.staked > 0, "nothing to withdraw");

        uint256 _amount = user.staked;
        user.staked = 0;

        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
            _amount.mul(token.rate).div(10**token.decimals)
        );

        IERC20(_token).transfer(msg.sender, _amount);
        emit EmergencyWithdrawnERC20(
            msg.sender,
            _token,
            _amount,
            user.stakedTime
        );
    }

    function emergencyWithdrawERC721(address _token, uint128[] memory _tokenIds)
        external
    {
        require(canEmergencyWithdraw, "function disabled");
        UserInfo storage user = userInfo[msg.sender][_token];
        require(user.staked > 0, "nothing to withdraw");

        uint256 _amount = user.staked;
        user.staked = 0;

        ExternalToken storage token = externalToken[_token];
        userExternalStaked[msg.sender] = userExternalStaked[msg.sender].sub(
            _amount.mul(10**token.decimals).div(token.rate)
        );

        if (_amount == 1) {
            IERC721(_token).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenIds[0]
            );
        } else {
            _batchSafeTransferFrom(
                _token,
                address(this),
                msg.sender,
                _tokenIds
            );
        }
        emit EmergencyWithdrawnERC721(
            msg.sender,
            _token,
            _tokenIds,
            user.stakedTime
        );
    }

    function addExternalToken(
        address _token,
        uint256 _decimals,
        uint256 _rate,
        bool _isERC721,
        bool _canStake
    ) public onlyOwner {
        ExternalToken storage token = externalToken[_token];

        require(_rate > 0, "TIER::INVALID_TOKEN_RATE");

        token.contractAddress = _token;
        token.decimals = _decimals;
        token.rate = _rate;
        token.isERC721 = _isERC721;
        token.canStake = _canStake;

        emit AddExternalToken(_token, _decimals, _rate, _isERC721, _canStake);
    }

    function setExternalToken(
        address _token,
        uint256 _decimals,
        uint256 _rate,
        bool _canStake
    ) external onlyOwner {
        ExternalToken storage token = externalToken[_token];

        require(token.contractAddress == _token, "TIER::TOKEN_NOT_EXISTS");
        require(_rate > 0, "TIER::INVALID_TOKEN_RATE");

        token.decimals = _decimals;
        token.rate = _rate;
        token.canStake = _canStake;

        emit ExternalTokenStatsChange(_token, _decimals, _rate, _canStake);
    }

    function updateTier(uint8 _tierId, uint256 _amount) external onlyOwner {
        require(_tierId > 0 && _tierId <= MAX_NUM_TIERS, "invalid _tierId");
        tierPrice[_tierId] = _amount;
        if (_tierId > currentMaxTier) {
            currentMaxTier = _tierId;
        }
    }

    function updateWithdrawFee(uint256 _key, uint256 _percent)
        external
        onlyOwner
    {
        require(_percent < 100, "too high percent");
        withdrawFeePercent[_key] = _percent;
    }

    function updatePunishTime(uint256 _key, uint256 _days) external onlyOwner {
        require(_days >= 0, "too short time");
        daysLockLevel[_key] = _days * 1 days;
    }

    function getUserTier(address _userAddress)
        external
        view
        returns (uint8 res)
    {
        uint256 totalStaked =
            userInfo[_userAddress][PKF].staked.add(
                userExternalStaked[_userAddress]
            );

        for (uint8 i = 1; i <= MAX_NUM_TIERS; i++) {
            if (tierPrice[i] == 0 || totalStaked < tierPrice[i]) {
                return res;
            }

            res = i;
        }
    }

    function calculateWithdrawFee(
        address _userAddress,
        address _token,
        uint256 _amount
    ) public view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress][_token];
        require(user.staked >= _amount, "not enough amount to withdraw");

        if (block.timestamp < user.stakedTime.add(daysLockLevel[0])) {
            return _amount.mul(withdrawFeePercent[0]).div(100); //30%
        }

        if (block.timestamp < user.stakedTime.add(daysLockLevel[1])) {
            return _amount.mul(withdrawFeePercent[1]).div(100); //25%
        }

        if (block.timestamp < user.stakedTime.add(daysLockLevel[2])) {
            return _amount.mul(withdrawFeePercent[2]).div(100); //20%
        }

        if (block.timestamp < user.stakedTime.add(daysLockLevel[3])) {
            return _amount.mul(withdrawFeePercent[3]).div(100); //10%
        }

        if (block.timestamp < user.stakedTime.add(daysLockLevel[4])) {
            return _amount.mul(withdrawFeePercent[4]).div(100); //5%
        }

        return _amount.mul(withdrawFeePercent[5]).div(100);
    }

    //frontend func
    function getTiers()
        external
        view
        returns (uint256[MAX_NUM_TIERS] memory buf)
    {
        for (uint8 i = 1; i < MAX_NUM_TIERS; i++) {
            if (tierPrice[i] == 0) {
                return buf;
            }
            buf[i - 1] = tierPrice[i];
        }

        return buf;
    }

    function userTotalStaked(address _userAddress) external view returns (uint256) {
        return
            userInfo[_userAddress][PKF].staked.add(
                userExternalStaked[_userAddress]
            );
    }

    function _batchSafeTransferFrom(
        address _token,
        address _from,
        address _recepient,
        uint128[] memory _tokenIds
    ) internal {
        for (uint256 i = 0; i != _tokenIds.length; i++) {
            IERC721(_token).safeTransferFrom(_from, _recepient, _tokenIds[i]);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}