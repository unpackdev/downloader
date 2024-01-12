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
 * @title Flipping Club Staking Contract v2.0 - flippingclub.xyz
 * @author Flipping Club Team
 */

pragma solidity 0.8.15;

import "./IERC721Receiver.sol";
import "./Context.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./stakeable.sol";
import "./IClaim.sol";
import "./NFTContractFunctions.sol";

contract FlippingClubStakingContract is Stakeable, Pausable, Ownable {
    using SafeMath for uint256;

    uint256 private P1Reward = 5;
    uint256 private P2Reward = 30;
    uint256 private P3Reward = 100;
    uint256 private P4Reward = 400;
    uint256 private P1Duration = 864000;
    uint256 private P2Duration = 3888000;
    uint256 private P3Duration = 7776000;
    uint256 private P4Duration = 15552000;
    uint256 private P1MinStakeValue = 100000000000000000;
    uint256 private P1MaxStakeValue = 20000000000000000000;
    uint256 private P2MinStakeValue = 100000000000000000;
    uint256 private P2MaxStakeValue = 40000000000000000000;
    uint256 private P3MinStakeValue = 100000000000000000;
    uint256 private P3MaxStakeValue = 60000000000000000000;
    uint256 private P4MinStakeValue = 100000000000000000;
    uint256 private P4MaxStakeValue = 80000000000000000000;
    uint256 private maxAllowancePerKey = 5000000000000000000;
    uint256 private constant PACKAGE_1 = 1;
    uint256 private constant PACKAGE_2 = 2;
    uint256 private constant PACKAGE_3 = 3;
    uint256 private constant PACKAGE_4 = 4;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant EXEC = keccak256(abi.encodePacked("EXEC"));
    bytes32 private constant CLAIM = keccak256(abi.encodePacked("CLAIM"));

    address private __checkKeys;
    address private _claimContract;

    event LogDepositReceived(address indexed payee);
    event Claimed(uint256 indexed amount, address indexed payee);

    NFTContractFunctions private ERC721KeyCards;

    constructor(address payable _newAdmin) {
        _grantRole(ADMIN, _newAdmin);
        _grantRole(EXEC, _newAdmin);
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

    function exec_beginStake(
        uint256 _amount,
        uint256 _package,
        uint256 _startTime,
        address _spender,
        uint256 _numKeys
    ) external payable nonReentrant onlyRole(EXEC) whenNotPaused {
        uint256 _reward;
        uint256 _timePeriodInSeconds;
        uint256 _minStakeValue;

        if (_package == PACKAGE_1) {
            _reward = P1Reward;
            _timePeriodInSeconds = P1Duration;
            _minStakeValue = P1MinStakeValue;
        }
        if (_package == PACKAGE_2) {
            _reward = P2Reward;
            _timePeriodInSeconds = P2Duration;
            _minStakeValue = P2MinStakeValue;
        }
        if (_package == PACKAGE_3) {
            _reward = P3Reward;
            _timePeriodInSeconds = P3Duration;
            _minStakeValue = P3MinStakeValue;
        }
        if (_package == PACKAGE_4) {
            _reward = P4Reward;
            _timePeriodInSeconds = P4Duration;
            _minStakeValue = P4MinStakeValue;
        }
        require(_amount >= _minStakeValue, "Stake less than minimum.");
        require(
            ((_amount.mul(_reward)).div(100)) <=
                (_numKeys * maxAllowancePerKey),
            "Not enough Keys."
        );
        require(
            _package == PACKAGE_1 ||
                _package == PACKAGE_2 ||
                _package == PACKAGE_3 ||
                _package == PACKAGE_4,
            "Invalid Package."
        );

        _admin_stake(
            _amount,
            _reward,
            _timePeriodInSeconds,
            _spender,
            _startTime,
            _numKeys
        );
    }

    function _beginStake(
        uint256 _amount,
        uint256 _package,
        uint256[] memory _keysToBeUsed,
        address _spender
    ) private {
        uint256 _reward;
        uint256 _timePeriodInSeconds;
        uint256 _minStakeValue;
        uint256 _maxStakeValue;
        if (_package == PACKAGE_1) {
            _reward = P1Reward;
            _timePeriodInSeconds = P1Duration;
            _minStakeValue = P1MinStakeValue;
            _maxStakeValue = P1MaxStakeValue;
        }
        if (_package == PACKAGE_2) {
            _reward = P2Reward;
            _timePeriodInSeconds = P2Duration;
            _minStakeValue = P2MinStakeValue;
            _maxStakeValue = P2MaxStakeValue;
        }
        if (_package == PACKAGE_3) {
            _reward = P3Reward;
            _timePeriodInSeconds = P3Duration;
            _minStakeValue = P3MinStakeValue;
            _maxStakeValue = P3MaxStakeValue;
        }
        if (_package == PACKAGE_4) {
            _reward = P4Reward;
            _timePeriodInSeconds = P4Duration;
            _minStakeValue = P4MinStakeValue;
            _maxStakeValue = P4MaxStakeValue;
        }

        require(_amount >= _minStakeValue, "Stake less than minimum");
        require(_amount <= _maxStakeValue, "Stake more than maximum");
        require(msg.value == _amount, "Invalid amount sent.");
        require(
            checkTokens(_keysToBeUsed, _spender) == true,
            "Not all Keys owned by address."
        );
        require(checkKey() >= 1, "Address have no Key.");
        require(
            _package == PACKAGE_1 ||
                _package == PACKAGE_2 ||
                _package == PACKAGE_3 ||
                _package == PACKAGE_4,
            "Invalid Package"
        );

        require(
            ((_amount.mul(_reward)).div(100)) <=
                (_keysToBeUsed.length * maxAllowancePerKey),
            "Not enough Keys."
        );
        burnKeys(_keysToBeUsed, _spender);
        _stake(
            _amount,
            _reward,
            _timePeriodInSeconds,
            _spender,
            _keysToBeUsed.length
        );
    }

    function withdrawStake(bool all, uint256 index)
        external
        nonReentrant
        whenNotPaused
    {
        require(_hasStake(msg.sender, index), "No active positions.");
        _withdrawStake(all, index);
    }

    function admin_withdraw_close(
        uint256 stake_index,
        address payable _spender,
        bool refund
    ) external onlyRole(ADMIN) {
        require(_hasStake(_spender, stake_index), "Nothing available.");
        _admin_withdraw_close(stake_index, _spender, refund);
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
        address burnAddress = 0x000000000000000000000000000000000000dEaD;
        for (uint256 i = 0; i < _keysToBeUsed.length; i++) {
            require(
                ERC721KeyCards.isApprovedForAll(_spender, address(this)) ==
                    true,
                "Not approved to spend Keys."
            );
            ERC721KeyCards.safeTransferFrom(
                _spender,
                burnAddress,
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

    function initClaim(uint256 _amount, address _payee)
        external
        nonReentrant
        whenNotPaused
        onlyRole(CLAIM)
    {
        require(address(this).balance > _amount, "Not enough balance.");
        payable(_payee).transfer(_amount);
        emit Claimed(_amount, _payee);
    }

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

    function setPackageOne(
        uint256 _P1Reward,
        uint256 _P1Duration,
        uint256 _min,
        uint256 _max
    ) external onlyRole(ADMIN) {
        P1Reward = _P1Reward;
        P1Duration = _P1Duration;
        P1MinStakeValue = _min;
        P1MaxStakeValue = _max;
    }

    function setPackageTwo(
        uint256 _P2Reward,
        uint256 _P2Duration,
        uint256 _min,
        uint256 _max
    ) external onlyRole(ADMIN) {
        P2Reward = _P2Reward;
        P2Duration = _P2Duration;
        P2MinStakeValue = _min;
        P2MaxStakeValue = _max;
    }

    function setPackageThree(
        uint256 _P3Reward,
        uint256 _P3Duration,
        uint256 _min,
        uint256 _max
    ) external onlyRole(ADMIN) {
        P3Reward = _P3Reward;
        P3Duration = _P3Duration;
        P3MinStakeValue = _min;
        P3MaxStakeValue = _max;
    }

    function setPackageFour(
        uint256 _P4Reward,
        uint256 _P4Duration,
        uint256 _min,
        uint256 _max
    ) external onlyRole(ADMIN) {
        P4Reward = _P4Reward;
        P4Duration = _P4Duration;
        P4MinStakeValue = _min;
        P4MaxStakeValue = _max;
    }

    function getPackage1()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (P1Reward, P1Duration, P1MinStakeValue, P1MaxStakeValue);
    }

    function getPackage2()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (P2Reward, P2Duration, P2MinStakeValue, P2MaxStakeValue);
    }

    function getPackage3()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (P3Reward, P3Duration, P3MinStakeValue, P3MaxStakeValue);
    }

    function getPackage4()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (P4Reward, P4Duration, P4MinStakeValue, P4MaxStakeValue);
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
