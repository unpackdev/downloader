//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./CountersUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract PogexLocker is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _lockIds;

    struct Locker {
        address token;
        address owner;
        uint256 amount;
        uint256 lockedDate;
        uint256 expireDate;
        uint256 claimedAt;
        bool isClaimed;
    }

    struct VestingLocker {
        address token;
        address owner;
        uint256 amount;
        uint256 lockedDate;
        uint256 initialPercentage;
        uint256 releaseCycle;
        uint256 releasePercentage;
        uint256 lastClaim;
        uint256 nextClaim;
        uint256 remainingTokens;
        bool isTotallyClaimed;
        bool isInitialClaimed;
    }

    mapping(uint256 => Locker) public lockerDetails;
    mapping(uint256 => VestingLocker) public vestingLockerDetails;
    mapping(address => bool) public isFeesExcluded;

    mapping(address => uint256[]) public lockedTokensId;

    uint256 public fee;

    event NewTokenLocked(
        uint256 id,
        address token,
        address owner,
        uint256 amount,
        uint256 expireDate,
        string title,
        string dex
    );
    event LockerOwnershipChanged(
        uint256 lockerId,
        address newOwner,
        address previousOwner
    );

    event LockerUnlocked(
        uint256 lockerId,
        address unlockedBy,
        uint256 unlockedAmount
    );

    function initialize() public initializer {
        __Ownable_init();
    }

    receive() external payable {}

    function lockTokens(
        address _tokenAddress,
        uint256 amount,
        uint256 lockTime,
        bool isLp,
        string memory _title,
        string memory _dex
    ) external payable nonReentrant returns (uint256) {
        require(_tokenAddress != address(0), "Please submit a valid address");

        if (!isFeesExcluded[msg.sender]) {
            require(
                msg.value >= fee,
                "Please submit asking price in order to complete the transaction"
            );
        }

        require(
            IERC20(_tokenAddress).balanceOf(msg.sender) >= amount,
            "Not enough tokens to lock"
        );

        require(
            lockTime > block.timestamp,
            "Lock time should be greater than 0"
        );

        uint256 oldTokenBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);

        uint256 currentBalance = IERC20(_tokenAddress).balanceOf(address(this));

        require(
            currentBalance.sub(oldTokenBalance) >= amount,
            "Require token amount not received"
        );

        if (isLp) {
            address factoryAddress = _parseFactoryAddress(_tokenAddress);
            require(
                _isValidLpToken(_tokenAddress, factoryAddress),
                "This is not an LP token"
            );
        }

        _lockIds.increment();
        uint256 lockerId = _lockIds.current();

        lockedTokensId[msg.sender].push(lockerId);

        lockerDetails[lockerId].token = _tokenAddress;
        lockerDetails[lockerId].owner = msg.sender;
        lockerDetails[lockerId].amount = amount;
        lockerDetails[lockerId].lockedDate = block.timestamp;
        lockerDetails[lockerId].expireDate = lockTime;

        emit NewTokenLocked(
            lockerId,
            _tokenAddress,
            msg.sender,
            amount,
            lockerDetails[lockerId].expireDate,
            _title,
            _dex
        );

        return lockerId;
    }

    function _isValidLpToken(
        address token,
        address factory
    ) private view returns (bool) {
        IUniswapV2Pair pair = IUniswapV2Pair(token);
        address factoryPair = IUniswapV2Factory(factory).getPair(
            pair.token0(),
            pair.token1()
        );
        return factoryPair == token;
    }

    function _parseFactoryAddress(
        address token
    ) internal view returns (address) {
        address possibleFactoryAddress;
        try IUniswapV2Pair(token).factory() returns (address factory) {
            possibleFactoryAddress = factory;
        } catch {
            revert("This is not an LP token");
        }
        require(
            possibleFactoryAddress != address(0) &&
                _isValidLpToken(token, possibleFactoryAddress),
            "This is not an LP token."
        );
        return possibleFactoryAddress;
    }

    // transfer locker ownership
    function transferLockerOwnerShip(
        uint256 lockerId,
        address _newOwner
    ) external {
        if (!isVesting(lockerId)) {
            require(
                lockerDetails[lockerId].owner == msg.sender,
                "You are not the owner of this locker"
            );

            lockerDetails[lockerId].owner = _newOwner;

            emit LockerOwnershipChanged(lockerId, _newOwner, msg.sender);
        } else {
            require(
                vestingLockerDetails[lockerId].owner == msg.sender,
                "You are not the owner of this locker"
            );

            vestingLockerDetails[lockerId].owner = _newOwner;

            emit LockerOwnershipChanged(lockerId, _newOwner, msg.sender);
        }
    }

    // change locker expire time
    function extendLockerExpireTime(
        uint256 lockerId,
        uint256 extendedTime
    ) public {
        if (!isVesting(lockerId)) {
            require(
                lockerDetails[lockerId].owner == msg.sender,
                "You are not the owner of this locker"
            );

            require(
                lockerDetails[lockerId].expireDate < extendedTime,
                "`Initial lock time can not be less than extended time"
            );

            lockerDetails[lockerId].expireDate = extendedTime;
        } else {
            require(
                vestingLockerDetails[lockerId].owner == msg.sender,
                "You are not the owner of this locker"
            );

            require(
                vestingLockerDetails[lockerId].nextClaim < extendedTime,
                "`Initial lock time can not be less than extended time"
            );

            require(
                vestingLockerDetails[lockerId].nextClaim < block.timestamp,
                "Unable to change time"
            );

            vestingLockerDetails[lockerId].nextClaim = extendedTime;
        }
    }

    // unlock tokens
    function unlockTokens(uint256 lockerId) public {
        require(
            lockerDetails[lockerId].owner == msg.sender,
            "You are not the owner of this locker"
        );
        require(
            !lockerDetails[lockerId].isClaimed,
            "Locker has been already claimed"
        );

        require(
            lockerDetails[lockerId].expireDate <= block.timestamp,
            "Locker is still locked"
        );

        lockerDetails[lockerId].isClaimed = true;

        lockerDetails[lockerId].claimedAt = block.timestamp;

        IERC20(lockerDetails[lockerId].token).transfer(
            msg.sender,
            lockerDetails[lockerId].amount
        );

        emit LockerUnlocked(
            lockerId,
            msg.sender,
            lockerDetails[lockerId].amount
        );
    }

    function getMyLockers() public view returns (uint256[] memory) {
        return lockedTokensId[msg.sender];
    }

    function isVesting(uint256 lockerId) public view returns (bool) {
        bool status;
        require(
            lockerDetails[lockerId].amount > 0 ||
                vestingLockerDetails[lockerId].amount > 0,
            "Invalid locker id"
        );

        if (vestingLockerDetails[lockerId].amount > 0) {
            status = true;
        }
        return status;
    }

    // lock vesting
    function lockAndVesting(
        address _tokenAddress,
        uint256 _amount,
        uint256 _initialReleaseTime,
        uint256 _initialPercentage,
        uint256 _releaseCycle,
        uint256 _releasePercentage,
        string memory _title,
        string memory _dex
    ) public payable nonReentrant {
        require(_tokenAddress != address(0), "Please submit a valid address");

        require(
            msg.value >= fee,
            "Please submit asking price in order to complete the transaction"
        );

        require(
            IERC20(_tokenAddress).balanceOf(msg.sender) >= _amount,
            "Not enough tokens to lock"
        );

        require(_initialReleaseTime > 0, "Lock time should be greater than 0");
        require(
            _initialReleaseTime > block.timestamp,
            "Release time must be a future date"
        );

        uint256 oldTokenBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

        uint256 currentBalance = IERC20(_tokenAddress).balanceOf(address(this));

        require(
            currentBalance.sub(oldTokenBalance) >= _amount,
            "Require token amount not received"
        );

        _lockIds.increment();
        uint256 lockerId = _lockIds.current();

        lockedTokensId[msg.sender].push(lockerId);

        vestingLockerDetails[lockerId].token = _tokenAddress;
        vestingLockerDetails[lockerId].owner = msg.sender;
        vestingLockerDetails[lockerId].amount = _amount;
        vestingLockerDetails[lockerId].lockedDate = block.timestamp;
        vestingLockerDetails[lockerId].initialPercentage = _initialPercentage;
        vestingLockerDetails[lockerId].releaseCycle = _releaseCycle;
        vestingLockerDetails[lockerId].releasePercentage = _releasePercentage;
        vestingLockerDetails[lockerId].nextClaim = _initialReleaseTime;
        vestingLockerDetails[lockerId].remainingTokens = _amount;

        emit NewTokenLocked(
            lockerId,
            _tokenAddress,
            msg.sender,
            _amount,
            vestingLockerDetails[lockerId].nextClaim,
            _title,
            _dex
        );
    }

    // unlock vesting
    function unlockVesting(uint256 lockId) public nonReentrant {
        require(
            vestingLockerDetails[lockId].owner == msg.sender,
            "You are not the owner of this locker"
        );

        require(
            vestingLockerDetails[lockId].nextClaim <= block.timestamp,
            "Unable to claim at this time"
        );

        require(
            !vestingLockerDetails[lockId].isTotallyClaimed,
            "Locker has been fully claimed"
        );

        uint256 tokensToRelease;

        if (!vestingLockerDetails[lockId].isInitialClaimed) {
            tokensToRelease = vestingLockerDetails[lockId]
                .amount
                .mul(vestingLockerDetails[lockId].initialPercentage)
                .div(100);
            vestingLockerDetails[lockId].isInitialClaimed = true;
        } else {
            tokensToRelease = vestingLockerDetails[lockId]
                .amount
                .mul(vestingLockerDetails[lockId].releasePercentage)
                .div(100);
        }

        if (tokensToRelease > vestingLockerDetails[lockId].remainingTokens) {
            tokensToRelease = vestingLockerDetails[lockId].remainingTokens;
        }

        vestingLockerDetails[lockId].nextClaim = vestingLockerDetails[lockId]
            .nextClaim
            .add(vestingLockerDetails[lockId].releaseCycle);

        vestingLockerDetails[lockId].remainingTokens = vestingLockerDetails[
            lockId
        ].remainingTokens.sub(tokensToRelease);

        vestingLockerDetails[lockId].lastClaim = block.timestamp;

        if (vestingLockerDetails[lockId].remainingTokens == 0) {
            vestingLockerDetails[lockId].isTotallyClaimed = true;
        }
    }

    // withdraw bnb
    function withdrawBnb() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // withdraw all bep20 tokens
    function withdrawBep20Tokens(
        address _token,
        uint256 percentage
    ) public onlyOwner {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        require(tokenBalance > 0, "No enough tokens in the pool");

        uint256 tokensToTransfer = tokenBalance.mul(percentage).div(100);

        IERC20(_token).transfer(msg.sender, tokensToTransfer);
    }

    function setFeesExcluded(address _wallet, bool _status) external onlyOwner {
        isFeesExcluded[_wallet] = _status;
    }

    function changeFees(uint256 _fee) external onlyOwner {
        fee = _fee;
    }
}
