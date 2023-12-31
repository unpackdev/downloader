// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

import "./IEyeconsRebasePoolV1.sol";
import "./IEyecons.sol";

contract EyeconsRebasePoolV1 is 
    IEyeconsRebasePoolV1, 
    Initializable,
    UUPSUpgradeable,
    ERC721HolderUpgradeable, 
    ERC1155HolderUpgradeable, 
    PausableUpgradeable, 
    AccessControlUpgradeable 
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    bytes32 public constant AUTHORITY_ROLE = keccak256("AUTHORITY_ROLE");
    uint256 public constant RESTRICTION_TIME = 60 days;
    uint256 public constant ONE_MONTH = 30 days;
    uint256 public constant NUMBER_OF_MONTHS_PER_YEAR = 12;
    uint256 public constant EXTRA_MONTH = 1;
    uint256 public constant BASE_POINTS = 10000;
    uint256 public constant BASE_POWER = 50000;
    uint256 public constant BASE_POWER_INCREASE = 40909;
    uint256 public constant BASE_LEVEL = 1;

    // V1
    uint256 public upgradingPrice;
    uint256 public currentCycleStartTime;
    uint256 public lastMerkleRootIdForEyeToken;
    address payable public treasury;
    address public eye;
    bool public isLaunched;
    IERC20MetadataUpgradeable public tether;
    IERC721Upgradeable public eyecons;
    CountersUpgradeable.Counter private _merkleRootId;
    CountersUpgradeable.Counter private _cycleId;
    EnumerableSetUpgradeable.AddressSet private _depositors;

    mapping(uint256 => uint256) public basePowerFactorByYear;
    mapping(uint256 => uint256) public basePowerIncreaseFactorByYear;
    mapping(uint256 => uint256) public lastDepositTimeByTokenId;
    mapping(uint256 => uint256) public storedAccumulatedPowerByTokenId;
    mapping(uint256 => uint256) public storedRemainingDurationByTokenId;
    mapping(uint256 => uint256) public storedLevelByTokenId;
    mapping(uint256 => uint256) public storedPowerByTokenId;
    mapping(uint256 => address) public depositorByTokenId;
    mapping(address => mapping(uint256 => bytes32)) public merkleRootByTokenAndId;
    mapping(uint256 => mapping(uint256 => uint256)) public storedDepositDurationByCycleIdAndTokenId;
    mapping(address => mapping(bytes32 => bool)) public isClaimedByAccountAndMerkleRoot;
    mapping(address => EnumerableSetUpgradeable.UintSet) private _depositedTokenIdsByAccount;

    /// @inheritdoc IEyeconsRebasePoolV1
    function initialize(
        uint256 upgradingPrice_,
        IERC20MetadataUpgradeable tether_,
        address payable treasury_,
        address eye_, 
        address eyecons_, 
        address authority_
    ) 
        external 
        initializer 
    {
        __UUPSUpgradeable_init();
        __ERC721Holder_init();
        __ERC1155Holder_init();
        __Pausable_init();
        __AccessControl_init();
        basePowerIncreaseFactorByYear[0] = 10000;
        basePowerFactorByYear[1] = 15000;
        basePowerIncreaseFactorByYear[1] = 15000;
        basePowerFactorByYear[2] = 20000;
        basePowerIncreaseFactorByYear[2] = 20000;
        upgradingPrice = upgradingPrice_;
        tether = tether_;
        treasury = treasury_;
        eye = eye_;
        eyecons = IERC721Upgradeable(eyecons_);
        _pause();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AUTHORITY_ROLE, authority_);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function launch() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (isLaunched) {
            revert AttemptToLaunchAgain();
        }
        currentCycleStartTime = block.timestamp;
        isLaunched = true;
        _unpause();
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function updateBasePowerFactor(
        uint256 year_, 
        uint256 basePowerFactor_
    ) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        emit BasePowerFactorUpdated(
            year_, 
            basePowerFactorByYear[year_], 
            basePowerFactor_
        );
        basePowerFactorByYear[year_] = basePowerFactor_;
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function updateBasePowerIncreaseFactor(
        uint256 year_, 
        uint256 basePowerIncreaseFactor_
    ) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        emit BasePowerIncreaseFactorUpdated(
            year_, 
            basePowerIncreaseFactorByYear[year_], 
            basePowerIncreaseFactor_
        );
        basePowerIncreaseFactorByYear[year_] = basePowerIncreaseFactor_;
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function updateUpgradingPrice(uint256 upgradingPrice_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit UpgradingPriceUpdated(upgradingPrice, upgradingPrice_);
        upgradingPrice = upgradingPrice_;
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function updateTreasury(address payable treasury_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit TreasuryUpdated(treasury, treasury_);
        treasury = treasury_;
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function setMerkleRoot(
        address token_, 
        bytes32 merkleRoot_
    )
        external
        onlyRole(AUTHORITY_ROLE) 
        whenPaused 
    {
        uint256 m_merkleRootId = _merkleRootId.current();
        if (token_ == eye) {
            currentCycleStartTime = block.timestamp;
            lastMerkleRootIdForEyeToken = m_merkleRootId;
            _cycleId.increment();
        }
        merkleRootByTokenAndId[token_][m_merkleRootId] = merkleRoot_;
        _merkleRootId.increment();
        emit MerkleRootSet(merkleRoot_, token_, m_merkleRootId);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function pause() external onlyRole(AUTHORITY_ROLE) {
        _pause();
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function unpause() external onlyRole(AUTHORITY_ROLE) {
        if (!isLaunched) {
            revert ForbiddenToUnpause();
        }
        _unpause();
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function provideERC20Reward(IERC20MetadataUpgradeable token_, uint256 amount_) external {
        token_.safeTransferFrom(msg.sender, address(this), amount_);
        emit ERC20RewardProvided(address(token_), amount_);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function provideERC721Reward(IERC721Upgradeable token_, uint256[] calldata tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; ) { 
            token_.safeTransferFrom(msg.sender, address(this), tokenIds_[i], "");
            unchecked {
                i++;
            }
        }
        emit ERC721RewardProvided(address(token_), tokenIds_);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function provideERC1155Reward(
        IERC1155Upgradeable token_, 
        uint256[] calldata tokenIds_, 
        uint256[] calldata amounts_
    ) 
        external 
    {
        if (tokenIds_.length != amounts_.length) {
            revert InvalidArrayLength();
        }
        for (uint256 i = 0; i < tokenIds_.length; ) { 
            token_.safeTransferFrom(msg.sender, address(this), tokenIds_[i], amounts_[i], "");
            unchecked {
                i++;
            }
        }
        emit ERC1155RewardProvided(address(token_), tokenIds_, amounts_);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function deposit(uint256[] calldata tokenIds_) external whenNotPaused {
        if (tokenIds_.length == 0) {
            revert InvalidArrayLength();
        }
        for (uint256 i = 0; i < tokenIds_.length; ) {
            uint256 tokenId = tokenIds_[i];
            _depositedTokenIdsByAccount[msg.sender].add(tokenId);
            depositorByTokenId[tokenId] = msg.sender;
            lastDepositTimeByTokenId[tokenId] = block.timestamp;
            eyecons.safeTransferFrom(msg.sender, address(this), tokenId);
            unchecked {
                i++;
            }
        }
        if (!_depositors.contains(msg.sender)) {
            _depositors.add(msg.sender);
        }
        emit Deposited(msg.sender, tokenIds_);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function withdraw(uint256[] calldata tokenIds_) external whenNotPaused {
        if (tokenIds_.length == 0) {
            revert InvalidArrayLength();
        }
        for (uint256 i = 0; i < tokenIds_.length; ) {
            uint256 tokenId = tokenIds_[i];
            if (!_depositedTokenIdsByAccount[msg.sender].contains(tokenId)) {
                revert InvalidTokenIdToWithdraw(tokenId);
            }
            (
                uint256 accumulatedPower, 
                uint256 currentPower, 
                uint256 currentLevel,
            ) = tokenInfo(tokenId);
            unchecked {
                storedAccumulatedPowerByTokenId[tokenId] += accumulatedPower;
            }
            if (storedPowerByTokenId[tokenId] != currentPower) {
                storedPowerByTokenId[tokenId] = currentPower;
            }
            if (storedLevelByTokenId[tokenId] != currentLevel) {
                storedLevelByTokenId[tokenId] = currentLevel;
            }
            _depositedTokenIdsByAccount[msg.sender].remove(tokenId);
            delete depositorByTokenId[tokenId];
            eyecons.safeTransferFrom(address(this), msg.sender, tokenId);
            unchecked {
                uint256 depositDuration = block.timestamp - lastDepositTimeByTokenId[tokenId];
                if (lastDepositTimeByTokenId[tokenId] < currentCycleStartTime) {
                    storedDepositDurationByCycleIdAndTokenId[_cycleId.current()][tokenId] 
                        += block.timestamp - currentCycleStartTime;
                } else {
                    storedDepositDurationByCycleIdAndTokenId[_cycleId.current()][tokenId] 
                        += depositDuration;
                }
                storedRemainingDurationByTokenId[tokenId] = ONE_MONTH - depositDuration % ONE_MONTH;
                i++;
            }
        }
        if (_depositedTokenIdsByAccount[msg.sender].length() == 0) {
            _depositors.remove(msg.sender);
        }
        emit Withdrawn(msg.sender, tokenIds_);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function claim(
        TokenType tokenType_,
        address token_,
        uint256 merkleRootId_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_,
        bytes32[] calldata merkleProof_
    ) 
        external 
        whenNotPaused
    { 
        if (token_ == eye) {
            merkleRootId_ = lastMerkleRootIdForEyeToken;
        }
        bytes32 merkleRoot = merkleRootByTokenAndId[token_][merkleRootId_];
        if (isClaimedByAccountAndMerkleRoot[msg.sender][merkleRoot]) {
            revert AttemptToClaimAgain();
        }
        bytes32 leaf;
        if (tokenType_ == TokenType.ERC20) {
            if (tokenIds_.length > 0 || amounts_.length != 1) {
                revert InvalidArrayLength();
            }
            leaf = keccak256(
                abi.encodePacked(
                    msg.sender, 
                    token_,
                    amounts_[0],
                    merkleRootId_
                )
            );
        } else if (tokenType_ == TokenType.ERC721) {
            if (tokenIds_.length == 0 || amounts_.length > 0) {
                revert InvalidArrayLength();
            }
            leaf = keccak256(
                abi.encodePacked(
                    msg.sender, 
                    token_,
                    tokenIds_,
                    merkleRootId_
                )
            );
        } else {
            if (tokenIds_.length == 0 || amounts_.length == 0 || tokenIds_.length != amounts_.length) {
                revert InvalidArrayLength();
            }
            leaf = keccak256(
                abi.encodePacked(
                    msg.sender, 
                    token_,
                    tokenIds_,
                    amounts_,
                    merkleRootId_
                )
            );
        }
        if (!MerkleProofUpgradeable.verifyCalldata(merkleProof_, merkleRoot, leaf)) {
            revert InvalidProof();
        }
        isClaimedByAccountAndMerkleRoot[msg.sender][merkleRoot] = true;
        if (tokenType_ == TokenType.ERC20) {
            IERC20MetadataUpgradeable(token_).safeTransfer(msg.sender, amounts_[0]);
        } else if (tokenType_ == TokenType.ERC721) {
            for (uint256 i = 0; i < tokenIds_.length; ) {
                IERC721Upgradeable(token_).safeTransferFrom(address(this), msg.sender, tokenIds_[i], "");
                unchecked {
                    i++;
                }
            }
        } else {
            for (uint256 i = 0; i < tokenIds_.length; ) {
                IERC1155Upgradeable(token_).safeTransferFrom(address(this), msg.sender, tokenIds_[i], amounts_[i], "");
                unchecked {
                    i++;
                }
            }
        }
        emit Claimed(msg.sender, token_, tokenIds_, amounts_);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function isEligibleForRewardInThisCycle(uint256 tokenId_) external view returns (bool) {
        if (!(eyecons.ownerOf(tokenId_) == address(this))) {
            return false;
        }
        (bool isSubscriptionActive, ) = IEyecons(address(eyecons)).subscriptionStatus(tokenId_);
        if (lastDepositTimeByTokenId[tokenId_] < currentCycleStartTime) {
            return block.timestamp - currentCycleStartTime >= RESTRICTION_TIME && isSubscriptionActive;
        } else {
            return 
                block.timestamp 
                - lastDepositTimeByTokenId[tokenId_] 
                + storedDepositDurationByCycleIdAndTokenId[_cycleId.current()][tokenId_] 
                >= RESTRICTION_TIME
                && isSubscriptionActive;
        }
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function cumulativePowerByTokenId(uint256 tokenId_) external view returns (uint256) {
        (uint256 accumulatedPower, , ,) = tokenInfo(tokenId_);
        return accumulatedPower + storedAccumulatedPowerByTokenId[tokenId_];
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function numberOfDepositedTokensByAccount(address account_) external view returns (uint256) {
        return _depositedTokenIdsByAccount[account_].length();
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function getDepositedTokenIdByAccountAt(address account_, uint256 index_) external view returns (uint256) {
        return _depositedTokenIdsByAccount[account_].at(index_);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function numberOfDepositors() external view returns (uint256) {
        return _depositors.length();
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function getDepositorAt(uint256 index_) external view returns (address) {
        return _depositors.at(index_);
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function currentMerkleRootId() external view returns (uint256) {
        return _merkleRootId.current();
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function currentCycleId() external view returns (uint256) {
        return _cycleId.current();
    }

    /// @inheritdoc IEyeconsRebasePoolV1
    function tokenInfo(
        uint256 tokenId_
    ) 
        public 
        view 
        returns (
            uint256 accumulatedPower_, 
            uint256 currentPower_, 
            uint256 currentLevel_,
            address depositor_
        ) 
    {
        uint256 depositDuration;
        if (eyecons.ownerOf(tokenId_) == address(this)) {
            unchecked {
                depositDuration = block.timestamp - lastDepositTimeByTokenId[tokenId_];
            }
        }
        uint256 m_storedPowerByTokenId = storedPowerByTokenId[tokenId_];
        uint256 m_storedLevelByTokenId = storedLevelByTokenId[tokenId_];
        currentPower_ = m_storedPowerByTokenId == 0 ? BASE_POWER : m_storedPowerByTokenId;
        currentLevel_ = m_storedLevelByTokenId == 0 ? BASE_LEVEL : m_storedLevelByTokenId;
        uint256 m_storedRemainingDurationByTokenId = storedRemainingDurationByTokenId[tokenId_];
        uint256 numberOfYears = currentLevel_ / (NUMBER_OF_MONTHS_PER_YEAR + EXTRA_MONTH);
        if (depositDuration > m_storedRemainingDurationByTokenId && m_storedRemainingDurationByTokenId > 0) {
            unchecked {
                depositDuration -= m_storedRemainingDurationByTokenId;
                accumulatedPower_ += currentPower_ * m_storedRemainingDurationByTokenId;
                currentLevel_++;
                if (currentLevel_ % (NUMBER_OF_MONTHS_PER_YEAR + NUMBER_OF_MONTHS_PER_YEAR * numberOfYears + EXTRA_MONTH) == 0) {
                    numberOfYears++;
                    currentPower_ = BASE_POWER * basePowerFactorByYear[numberOfYears] / BASE_POINTS;
                } else {
                    currentPower_ += BASE_POWER_INCREASE * basePowerIncreaseFactorByYear[numberOfYears] / BASE_POINTS;
                }
            }
        }
        uint256 numberOfMonths = depositDuration / ONE_MONTH;
        for (uint256 i = 0; i < numberOfMonths; ) {
            unchecked {
                accumulatedPower_ += currentPower_ * ONE_MONTH;
                currentLevel_++;
                if (currentLevel_ % (NUMBER_OF_MONTHS_PER_YEAR + NUMBER_OF_MONTHS_PER_YEAR * numberOfYears + EXTRA_MONTH) == 0) {
                    numberOfYears++;
                    currentPower_ = BASE_POWER * basePowerFactorByYear[numberOfYears] / BASE_POINTS;
                } else {
                    currentPower_ += BASE_POWER_INCREASE * basePowerIncreaseFactorByYear[numberOfYears] / BASE_POINTS;
                }
                i++;
            }
        }
        unchecked {
            uint256 leftDuration = depositDuration - numberOfMonths * ONE_MONTH;
            accumulatedPower_ += currentPower_ * leftDuration;
        }
        depositor_ = depositorByTokenId[tokenId_];
    }

    /// @inheritdoc IERC165Upgradeable
    function supportsInterface(
        bytes4 interfaceId_
    )
        public
        view
        override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}