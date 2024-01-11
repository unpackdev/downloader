// SPDX-License-Identifier: MIT
/**
 *  ______ _ _             _                _____ _       _
 * |  ____| (_)           (_)              / ____| |     | |
 * | |__  | |_ _ __  _ __  _ _ __   __ _  | |    | |_   _| |__
 * |  __| | | | '_ \| '_ \| | '_ \ / _` | | |    | | | | | '_ \
 * | |    | | | |_) | |_) | | | | | (_| | | |____| | |_| | |_) |
 * |_|    |_|_| .__/| .__/|_|_| |_|\__, |  \_____|_|\__,_|_.__/
 *            | |   | |             __/ |
 *   _____ _  |_|   |_|  _         |___/  _____            _                  _
 *  / ____| |      | |  (_)              / ____|          | |                | |
 * | (___ | |_ __ _| | ___ _ __   __ _  | |     ___  _ __ | |_ _ __ __ _  ___| |_
 *  \___ \| __/ _` | |/ / | '_ \ / _` | | |    / _ \| '_ \| __| '__/ _` |/ __| __|
 *  ____) | || (_| |   <| | | | | (_| | | |___| (_) | | | | |_| | | (_| | (__| |_
 * |_____/ \__\__,_|_|\_\_|_| |_|\__, |  \_____\___/|_| |_|\__|_|  \__,_|\___|\__|
 *                                __/ |
 *                               |___/
 *
 * @title Flipping Club Staking Contract - flippingclub.xyz
 * @dev Contract to manage staking of eth based on different plans
 * @author Flipping Club Team
 */
import "./IERC721Receiver.sol";
import "./Context.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./stakeable.sol";

pragma solidity 0.8.11;

interface IClaim {
    function initClaim(address _payee, uint256 _amount) external payable;
}

interface NFTContractFunctions {
    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function approve(address to, uint256 tokenId) external;
}

contract FlippingClubStakingManager is Stakeable, Pausable, Ownable {
    using SafeMath for uint256;
    event LogDepositReceived(address indexed payee);
    event Claimed(uint256 indexed amount, address indexed payee);

    NFTContractFunctions private ERC721KeyCards;

    uint256 private P1Reward = 210; // Basis Point
    uint256 private P2Reward = 280;
    uint256 private P3Reward = 460;
    uint256 private P4Reward = 930;
    uint256 private P1Duration = 864000; // Seconds
    uint256 private P2Duration = 3888000;
    uint256 private P3Duration = 7776000;
    uint256 private P4Duration = 15552000;
    uint256 private constant PACKAGE_1 = 1;
    uint256 private constant PACKAGE_2 = 2;
    uint256 private constant PACKAGE_3 = 3;
    uint256 private constant PACKAGE_4 = 4;
    uint256 private maxAllowancePerKey = 5000000000000000000;
    uint256 private minStakeValue = 100000000000000000;
    uint256 private maxStakeValue = 100000000000000000000;
    uint256 private minWithdraw = 100000000000000000;
    address private __checkKeys = 0xd2F735f959c3DC91e6C23C8254e70D07B6aaCD68; // FlippingClub Access Key Contract
    address private _claimContract = 0x0000000000000000000000000000000000000000;
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));

    constructor(address payable _newAdmin) {
        _grantRole(ADMIN, _newAdmin);
    }

    receive() external payable {
        emit LogDepositReceived(msg.sender);
    }

    function beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed
    ) external payable nonReentrant whenNotPaused {
        _beginStake(_amount, _package, _keysToBeUsed, msg.sender);
    }

    function admin_beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed,
        address _spender
    ) external payable nonReentrant onlyRole(ADMIN) whenNotPaused {
        _beginStake(_amount, _package, _keysToBeUsed, _spender);
    }

    function _beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed,
        address _spender
    ) private {
        require(
            _amount >= minStakeValue,
            "Stake: Cannot stake less than minimum"
        );
        require(
            _amount <= maxStakeValue,
            "Stake: Cannot stake more than maximum"
        );
        require(msg.value == _amount, "Stake: Invalid amount of eth sent.");
        require(
            checkTokens(_keysToBeUsed, _spender) == true,
            "Stake: Not all Keys presented are owned by this address."
        );
        require(checkKey() >= 1, "Stake: This address dont have any Key.");
        require(
            _package == PACKAGE_1 ||
                _package == PACKAGE_2 ||
                _package == PACKAGE_3 ||
                _package == PACKAGE_4,
            "Stake: Invalid Package"
        );
        uint256 _rewardPerHour = 0;
        uint256 _timePeriodInSeconds = 0;
        if (_package == PACKAGE_1) {
            _rewardPerHour = P1Reward;
            _timePeriodInSeconds = P1Duration;
        }
        if (_package == PACKAGE_2) {
            _rewardPerHour = P2Reward;
            _timePeriodInSeconds = P2Duration;
        }
        if (_package == PACKAGE_3) {
            _rewardPerHour = P3Reward;
            _timePeriodInSeconds = P3Duration;
        }
        if (_package == PACKAGE_4) {
            _rewardPerHour = P4Reward;
            _timePeriodInSeconds = P4Duration;
        }
        require(
            ((_amount / _rewardPerHour) * (_timePeriodInSeconds / 3600)) <=
                (_keysToBeUsed.length * maxAllowancePerKey),
            "Stake: Not enough Keys for this package."
        );
        burnKeys(_keysToBeUsed, _spender);
        _stake(_amount, _rewardPerHour, _timePeriodInSeconds, _spender);
    }

    function withdrawStake(uint256 amount, uint256 stake_index)
        external
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        require(amount >= minWithdraw, "Claim: Amount is less than minimum");
        return _withdrawStake(amount, stake_index);
    }

    function checkTokens(uint256[] memory _tokenList, address _msgSender)
        private
        view
        returns (bool)
    {
        require(__checkKeys != address(0), "Key Contract not set.");
        for (uint256 i = 0; i < _tokenList.length; i++) {
            if (ERC721KeyCards.ownerOf(_tokenList[i]) != _msgSender) {
                return false;
            }
        }
        return true;
    }

    function burnKeys(uint256[] memory _keysToBeUsed, address _spender)
        public
        whenNotPaused
    {
        for (uint256 i = 0; i < _keysToBeUsed.length; i++) {
            require(
                ERC721KeyCards.isApprovedForAll(_spender, address(this)) ==
                    true,
                "BurnKeys: Contract is not approved to spend Keys."
            );
            ERC721KeyCards.safeTransferFrom(
                _spender,
                address(this),
                _keysToBeUsed[i]
            );
        }
    }

    function checkKey() private view returns (uint256) {
        require(__checkKeys != address(0), "Key Contract not set.");
        return ERC721KeyCards.balanceOf(msg.sender);
    }

    /// @notice Initiates Pool participition in batches.
    function initPool(uint256 _amount, address _payee)
        external
        nonReentrant
        onlyRole(ADMIN)
    {
        payable(_payee).transfer(_amount);
    }

    /// @notice Initiates claim for specific address.
    function broadcastClaim(address payable _payee, uint256 _amount)
        external
        payable
        onlyRole(EXEC)
        nonReentrant
        whenNotPaused
    {
        require(_claimContract != address(0), "Claim Contract not set.");
        IClaim(_claimContract).initClaim{value: msg.value}(_payee, _amount);
        emit Claimed(_amount, _payee);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setPackageOne(uint256 _P1Reward, uint256 _P1Duration)
        external
        onlyRole(ADMIN)
    {
        P1Reward = _P1Reward;
        P1Duration = _P1Duration;
    }

    function setPackageTwo(uint256 _P2Reward, uint256 _P2Duration)
        external
        onlyRole(ADMIN)
    {
        P2Reward = _P2Reward;
        P2Duration = _P2Duration;
    }

    function setPackageThree(uint256 _P3Reward, uint256 _P3Duration)
        external
        onlyRole(ADMIN)
    {
        P3Reward = _P3Reward;
        P3Duration = _P3Duration;
    }

    function setPackageFour(uint256 _P4Reward, uint256 _P4Duration)
        external
        onlyRole(ADMIN)
    {
        P4Reward = _P4Reward;
        P4Duration = _P4Duration;
    }

    function getPackages()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            P1Reward,
            P1Duration,
            P2Reward,
            P2Duration,
            P3Reward,
            P3Duration,
            P4Reward,
            P4Duration
        );
    }

    function setCheckKeysContractAddress(address KeysContract)
        external
        onlyRole(ADMIN)
    {
        __checkKeys = KeysContract;
        ERC721KeyCards = NFTContractFunctions(__checkKeys);
    }

    function setClaimContract(address ClaimContract) external onlyRole(ADMIN) {
        _claimContract = ClaimContract;
    }

    function setmaxAllowancePerKey(uint256 _maxAllowancePerKey)
        external
        onlyRole(ADMIN)
    {
        maxAllowancePerKey = _maxAllowancePerKey;
    }

    function getmaxAllowancePerKey() external view returns (uint256) {
        return maxAllowancePerKey;
    }

    function setMinWithdraw(uint256 _minWithdraw) external onlyRole(ADMIN) {
        minWithdraw = _minWithdraw;
    }

    function getminWithdraw() external view returns (uint256) {
        return minWithdraw;
    }

    function setminStakeValue(uint256 _minStakeValue) external onlyRole(ADMIN) {
        minStakeValue = _minStakeValue;
    }

    function setmaxStakeValue(uint256 _maxStakeValue) external onlyRole(ADMIN) {
        maxStakeValue = _maxStakeValue;
    }

    function getMinMaxValue() external view returns (uint256, uint256) {
        return (minStakeValue, maxStakeValue);
    }

    function pause() external whenNotPaused onlyRole(ADMIN) {
        _pause();
    }

    function unPause() external whenPaused onlyRole(ADMIN) {
        _unpause();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
