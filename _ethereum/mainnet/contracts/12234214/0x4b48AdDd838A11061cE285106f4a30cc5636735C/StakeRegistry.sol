// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20PresetMinterPauser.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";
import "./SLA.sol";
import "./IMessenger.sol";
import "./SLARegistry.sol";
import "./StringUtils.sol";

/**
 * @title StakeRegistry
 * @dev StakeRegistry is a contract to register the staking activity of the platform, along
 with controlling certain admin privileged parameters
 */
contract StakeRegistry is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    /// @dev struct to return on getActivePool function.
    struct ActivePool {
        address SLAAddress;
        uint256 stake;
        string assetName;
        address assetAddress;
    }

    struct LockedValue {
        uint256 lockedValue;
        uint256 slaPeriodIdsLength;
        uint256 dslaDepositByPeriod;
        uint256 dslaPlatformReward;
        uint256 dslaMessengerReward;
        uint256 dslaUserReward;
        uint256 dslaBurnedByVerification;
        mapping(uint256 => bool) verifiedPeriods;
    }

    address public DSLATokenAddress;
    SLARegistry public slaRegistry;

    //______ onlyOwner modifiable parameters ______

    /// @dev corresponds to the burn rate of DSLA tokens, but divided by 1000 i.e burn percentage = DSLAburnRate/1000 %
    uint256 private _DSLAburnRate = 3;
    /// @dev (ownerAddress => slaAddress => LockedValue) stores the locked value by the staker
    mapping(address => LockedValue) public slaLockedValue;
    /// @dev DSLA deposit by period to create SLA
    uint256 private _dslaDepositByPeriod = 1000 ether;
    /// @dev DSLA rewarded to the foundation
    uint256 private _dslaPlatformReward = 250 ether;
    /// @dev DSLA rewarded to the Messenger creator
    uint256 private _dslaMessengerReward = 250 ether;
    /// @dev DSLA rewarded to user calling the period verification
    uint256 private _dslaUserReward = 250 ether;
    /// @dev DSLA burned after every period verification
    uint256 private _dslaBurnedByVerification = 250 ether;
    /// @dev max token length for allowedTokens array of Staking contracts
    uint256 private _maxTokenLength = 1;
    /// @dev max times of hedge leverage
    uint64 private _maxLeverage = 100;

    /// @dev array with the allowed tokens addresses of the StakeRegistry
    address[] public allowedTokens;

    /// @dev (userAddress => SLA[]) with user staked SLAs to get tokenPool
    mapping(address => SLA[]) public userStakedSlas;

    /**
     * @dev event to log a verifiation reward distributed
     * @param sla 1. The address of the created service level agreement contract
     * @param requester 2. -
     * @param userReward 3. -
     * @param platformReward 4. -
     * @param messengerReward 5. -
     * @param burnedDSLA 6. -
     */
    event VerificationRewardDistributed(
        address indexed sla,
        address indexed requester,
        uint256 userReward,
        uint256 platformReward,
        uint256 messengerReward,
        uint256 burnedDSLA
    );

    /**
     * @dev event to log modifications on the staking parameters
     *@param DSLAburnRate 1. (DSLAburnRate/1000)% of DSLA to be burned after a reward/compensation is paid
     *@param dslaDepositByPeriod 2. DSLA deposit by period to create SLA
     *@param dslaPlatformReward 3. DSLA rewarded to Stacktical team
     *@param dslaUserReward 4. DSLA rewarded to user calling the period verification
     *@param dslaBurnedByVerification 5. DSLA burned after every period verification
     */
    event StakingParametersModified(
        uint256 DSLAburnRate,
        uint256 dslaDepositByPeriod,
        uint256 dslaPlatformReward,
        uint256 dslaMessengerReward,
        uint256 dslaUserReward,
        uint256 dslaBurnedByVerification,
        uint256 maxTokenLength,
        uint64 maxLeverage
    );

    /**
     * @dev event to log modifications on the staking parameters
     *@param sla 1. -
     *@param owner 2. -
     *@param amount 3. -
     */

    event LockedValueReturned(
        address indexed sla,
        address indexed owner,
        uint256 amount
    );

    /**
     * @dev event to log modifications on the staking parameters
     *@param dTokenAddress 1. -
     *@param sla 2. -
     *@param name 3. -
     *@param symbol 4. -
     */
    event DTokenCreated(
        address indexed dTokenAddress,
        address indexed sla,
        string name,
        string symbol
    );

    /**
     * @dev event to log modifications on the staking parameters
     *@param sla 1. -
     *@param owner 2. -
     *@param amount 3. -
     */
    event ValueLocked(
        address indexed sla,
        address indexed owner,
        uint256 amount
    );

    /**
     * @param _dslaTokenAddress 1. DSLA Token
     */
    constructor(address _dslaTokenAddress) public {
        require(
            _dslaDepositByPeriod ==
                _dslaPlatformReward
                    .add(_dslaMessengerReward)
                    .add(_dslaUserReward)
                    .add(_dslaBurnedByVerification),
            "Staking parameters should match on summation"
        );
        DSLATokenAddress = _dslaTokenAddress;
        allowedTokens.push(_dslaTokenAddress);
    }

    /// @dev Throws if called by any address other than the SLARegistry contract or Chainlink Oracle.
    modifier onlySLARegistry() {
        require(
            msg.sender == address(slaRegistry),
            "Can only be called by SLARegistry"
        );
        _;
    }

    /**
     * @dev sets the SLARegistry contract address and can only be called
     * once
     */
    function setSLARegistry() external {
        // Only able to trigger this function once
        require(
            address(slaRegistry) == address(0),
            "SLARegistry address has already been set"
        );

        slaRegistry = SLARegistry(msg.sender);
    }

    /**
     *@dev add a token to ve allowed for staking
     *@param _tokenAddress 1. address of the new allowed token
     */
    function addAllowedTokens(address _tokenAddress) external onlyOwner {
        require(!isAllowedToken(_tokenAddress), "token already added");
        allowedTokens.push(_tokenAddress);
    }

    function isAllowedToken(address _tokenAddress) public view returns (bool) {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     *@dev public view function that returns true if the _owner has staked on _sla
     *@param _user 1. address to check
     *@param _sla 2. sla to check
     *@return bool, true if _sla was staked by _user
     */

    function slaWasStakedByUser(address _user, address _sla)
        public
        view
        returns (bool)
    {
        for (uint256 index = 0; index < userStakedSlas[_user].length; index++) {
            if (address(userStakedSlas[_user][index]) == _sla) {
                return true;
            }
        }
        return false;
    }

    /**
     *@dev register the sending SLA contract as staked by _owner
     *@param _owner 1. SLA contract to stake
     */
    function registerStakedSla(address _owner) external returns (bool) {
        require(
            slaRegistry.isRegisteredSLA(msg.sender),
            "Only for registered SLAs"
        );
        if (!slaWasStakedByUser(_owner, msg.sender)) {
            userStakedSlas[_owner].push(SLA(msg.sender));
        }
        return true;
    }

    /**
     *@dev to create dTokens for staking
     *@param _name 1. token name
     *@param _symbol 2. token symbol
     */
    function createDToken(string calldata _name, string calldata _symbol)
        external
        returns (address)
    {
        require(
            slaRegistry.isRegisteredSLA(msg.sender),
            "Only for registered SLAs"
        );
        ERC20PresetMinterPauser dToken =
            new ERC20PresetMinterPauser(_name, _symbol);
        dToken.grantRole(dToken.MINTER_ROLE(), msg.sender);
        emit DTokenCreated(address(dToken), msg.sender, _name, _symbol);
        return address(dToken);
    }

    function lockDSLAValue(
        address _slaOwner,
        address _sla,
        uint256 _periodIdsLength
    ) external onlySLARegistry nonReentrant {
        uint256 lockedValue = _dslaDepositByPeriod.mul(_periodIdsLength);
        ERC20(DSLATokenAddress).safeTransferFrom(
            _slaOwner,
            address(this),
            lockedValue
        );
        slaLockedValue[_sla] = LockedValue({
            lockedValue: lockedValue,
            slaPeriodIdsLength: _periodIdsLength,
            dslaDepositByPeriod: _dslaDepositByPeriod,
            dslaPlatformReward: _dslaPlatformReward,
            dslaMessengerReward: _dslaMessengerReward,
            dslaUserReward: _dslaUserReward,
            dslaBurnedByVerification: _dslaBurnedByVerification
        });
        emit ValueLocked(_sla, _slaOwner, lockedValue);
    }

    function distributeVerificationRewards(
        address _sla,
        address _verificationRewardReceiver,
        uint256 _periodId
    ) external onlySLARegistry nonReentrant {
        LockedValue storage _lockedValue = slaLockedValue[_sla];
        require(
            !_lockedValue.verifiedPeriods[_periodId],
            "Period rewards already distributed"
        );
        _lockedValue.verifiedPeriods[_periodId] = true;
        _lockedValue.lockedValue = _lockedValue.lockedValue.sub(
            _lockedValue.dslaDepositByPeriod
        );
        ERC20(DSLATokenAddress).safeTransfer(
            _verificationRewardReceiver,
            _lockedValue.dslaUserReward
        );
        ERC20(DSLATokenAddress).safeTransfer(
            owner(),
            _lockedValue.dslaPlatformReward
        );
        ERC20(DSLATokenAddress).safeTransfer(
            IMessenger(SLA(_sla).messengerAddress()).owner(),
            _lockedValue.dslaMessengerReward
        );
        _burnDSLATokens(_lockedValue.dslaBurnedByVerification);
        emit VerificationRewardDistributed(
            _sla,
            _verificationRewardReceiver,
            _lockedValue.dslaUserReward,
            _lockedValue.dslaPlatformReward,
            _lockedValue.dslaMessengerReward,
            _lockedValue.dslaBurnedByVerification
        );
    }

    function returnLockedValue(address _sla)
        external
        onlySLARegistry
        nonReentrant
    {
        LockedValue storage _lockedValue = slaLockedValue[_sla];
        uint256 remainingBalance = _lockedValue.lockedValue;
        require(remainingBalance > 0, "locked value is empty");
        _lockedValue.lockedValue = 0;
        ERC20(DSLATokenAddress).safeTransfer(
            SLA(_sla).owner(),
            remainingBalance
        );
        emit LockedValueReturned(_sla, SLA(_sla).owner(), remainingBalance);
    }

    function _burnDSLATokens(uint256 _amount) internal {
        bytes4 BURN_SELECTOR = bytes4(keccak256(bytes("burn(uint256)")));
        (bool _success, ) =
            DSLATokenAddress.call(
                abi.encodeWithSelector(BURN_SELECTOR, _amount)
            );
        require(_success, "DSLA burn process was not successful");
    }

    /**
     * @dev returns the active pools owned by a user.
     * @param _slaOwner 1. owner of the active pool
     * @return ActivePool[], array of structs: {SLAAddress,stake,assetName}
     */
    function getActivePool(address _slaOwner)
        external
        view
        returns (ActivePool[] memory)
    {
        bytes4 NAME_SELECTOR = bytes4(keccak256(bytes("name()")));
        uint256 stakeCounter = 0;
        // Count the stakes of the user, checking every SLA staked
        for (
            uint256 index = 0;
            index < userStakedSlas[_slaOwner].length;
            index++
        ) {
            SLA currentSLA = SLA(userStakedSlas[_slaOwner][index]);
            stakeCounter = stakeCounter.add(
                currentSLA.getAllowedTokensLength()
            );
        }

        ActivePool[] memory activePools = new ActivePool[](stakeCounter);
        // to insert on activePools array
        uint256 stakePosition = 0;
        for (
            uint256 index = 0;
            index < userStakedSlas[_slaOwner].length;
            index++
        ) {
            SLA currentSLA = userStakedSlas[_slaOwner][index];
            for (
                uint256 tokenIndex = 0;
                tokenIndex < currentSLA.getAllowedTokensLength();
                tokenIndex++
            ) {
                (address tokenAddress, uint256 stake) =
                    currentSLA.getTokenStake(_slaOwner, tokenIndex);
                (, bytes memory tokenNameBytes) =
                    tokenAddress.staticcall(
                        abi.encodeWithSelector(NAME_SELECTOR)
                    );
                ActivePool memory currentActivePool =
                    ActivePool({
                        SLAAddress: address(currentSLA),
                        stake: stake,
                        assetName: string(tokenNameBytes),
                        assetAddress: tokenAddress
                    });
                activePools[stakePosition] = currentActivePool;
                stakePosition = stakePosition.add(1);
            }
        }
        return activePools;
    }

    //_______ OnlyOwner functions _______
    function setStakingParameters(
        uint256 DSLAburnRate,
        uint256 dslaDepositByPeriod,
        uint256 dslaPlatformReward,
        uint256 dslaMessengerReward,
        uint256 dslaUserReward,
        uint256 dslaBurnedByVerification,
        uint256 maxTokenLength,
        uint64 maxLeverage
    ) external onlyOwner {
        _DSLAburnRate = DSLAburnRate;
        _dslaDepositByPeriod = dslaDepositByPeriod;
        _dslaPlatformReward = dslaPlatformReward;
        _dslaMessengerReward = dslaMessengerReward;
        _dslaUserReward = dslaUserReward;
        _dslaBurnedByVerification = dslaBurnedByVerification;
        _maxTokenLength = maxTokenLength;
        _maxLeverage = maxLeverage;
        require(
            _dslaDepositByPeriod ==
                _dslaPlatformReward
                    .add(_dslaMessengerReward)
                    .add(_dslaUserReward)
                    .add(_dslaBurnedByVerification),
            "Staking parameters should match on summation"
        );
        emit StakingParametersModified(
            DSLAburnRate,
            dslaDepositByPeriod,
            dslaPlatformReward,
            dslaMessengerReward,
            dslaUserReward,
            dslaBurnedByVerification,
            maxTokenLength,
            maxLeverage
        );
    }

    function getStakingParameters()
        external
        view
        returns (
            uint256 DSLAburnRate,
            uint256 dslaDepositByPeriod,
            uint256 dslaPlatformReward,
            uint256 dslaMessengerReward,
            uint256 dslaUserReward,
            uint256 dslaBurnedByVerification,
            uint256 maxTokenLength,
            uint64 maxLeverage
        )
    {
        DSLAburnRate = _DSLAburnRate;
        dslaDepositByPeriod = _dslaDepositByPeriod;
        dslaPlatformReward = _dslaPlatformReward;
        dslaMessengerReward = _dslaMessengerReward;
        dslaUserReward = _dslaUserReward;
        dslaBurnedByVerification = _dslaBurnedByVerification;
        maxTokenLength = _maxTokenLength;
        maxLeverage = _maxLeverage;
    }

    function periodIsVerified(address _sla, uint256 _periodId)
        external
        view
        returns (bool)
    {
        return slaLockedValue[_sla].verifiedPeriods[_periodId];
    }
}
