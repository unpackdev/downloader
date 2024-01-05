// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ERC20PresetMinterPauser.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./StakeRegistry.sol";
import "./SLARegistry.sol";
import "./PeriodRegistry.sol";
import "./StringUtils.sol";

contract Staking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /// @dev StakeRegistry contract
    StakeRegistry private stakeRegistry;
    /// @dev SLARegistry contract
    PeriodRegistry private immutable periodRegistry;
    /// @dev current SLA id
    uint128 public immutable slaID;

    /// @dev (tokenAddress=>uint256) total pooled token balance
    mapping(address => uint256) public providerPool;
    /// @dev (tokenAddress=>uint256) total pooled token balance
    mapping(address => uint256) public usersPool;

    ///@dev (tokenAddress=>dTokenAddress) to keep track of dToken for users
    mapping(address => ERC20PresetMinterPauser) public duTokenRegistry;
    ///@dev (tokenAddress=>dTokenAddress) to keep track of dToken for provider
    mapping(address => ERC20PresetMinterPauser) public dpTokenRegistry;

    /// @dev address[] of the stakers of the SLA contract
    address[] public stakers;
    /// @dev (slaOwner=>bool)
    mapping(address => bool) public registeredStakers;
    /// @dev DSLA token address to burn fees
    address public immutable dslaTokenAddress;
    /// @dev array with the allowed tokens addresses for the current SLA
    address[] public allowedTokens;

    /// @dev corresponds to the burn rate of DSLA tokens, but divided by 1000 i.e burn percentage = burnRate/1000 %
    uint256 public immutable DSLAburnRate;

    /// @dev PeriodRegistry period type of the SLA contract
    PeriodRegistry.PeriodType private immutable periodType;

    /// @dev boolean to declare if contract is whitelisted
    bool public immutable whitelistedContract;
    /// @dev (userAddress=bool) to declare whitelisted addresses
    mapping(address => bool) public whitelist;

    uint64 public immutable leverage;

    modifier onlyAllowedToken(address _token) {
        require(isAllowedToken(_token) == true, "token is not allowed");
        _;
    }

    modifier onlyWhitelisted {
        if (whitelistedContract == true) {
            require(whitelist[msg.sender] == true, "Not whitelisted");
        }
        _;
    }

    /**
     * @dev event for provider reward log
     * @param periodId 1. id of the period
     * @param tokenAddress 2. address of the token
     * @param rewardPercentage 3. reward percentage for the provider
     * @param rewardPercentagePrecision 4. reward percentage for the provider
     * @param rewardAmount 5. amount rewarded
     */
    event ProviderRewardGenerated(
        uint256 indexed periodId,
        address indexed tokenAddress,
        uint256 rewardPercentage,
        uint256 rewardPercentagePrecision,
        uint256 rewardAmount
    );

    event UserCompensationGenerated(
        uint256 indexed periodId,
        address indexed tokenAddress,
        uint256 usersStake,
        uint256 leverage,
        uint256 compensation
    );

    event DTokensCreated(
        address indexed tokenAddress,
        address indexed dpTokenAddress,
        string dpTokenName,
        string dpTokenSymbol,
        address indexed duTokenAddress,
        string duTokenName,
        string duTokenSymbol
    );

    /**
     *@param _slaRegistryAddress 1. period type of the SLA
     *@param _periodType 3. period type of the SLA
     *@param _whitelistedContract 5. enables the white list feature
     *@param _slaID 6. identifies the SLA to uniquely to emit dTokens
     */
    constructor(
        SLARegistry _slaRegistry,
        PeriodRegistry.PeriodType _periodType,
        bool _whitelistedContract,
        uint128 _slaID,
        uint64 _leverage,
        address _contractOwner
    ) public {
        stakeRegistry = _slaRegistry.stakeRegistry();
        periodRegistry = _slaRegistry.periodRegistry();
        periodType = _periodType;
        whitelistedContract = _whitelistedContract;
        (uint256 _DSLAburnRate, , , , , , , uint64 _maxLeverage) =
            stakeRegistry.getStakingParameters();
        dslaTokenAddress = stakeRegistry.DSLATokenAddress();
        DSLAburnRate = _DSLAburnRate;
        whitelist[_contractOwner] = true;
        slaID = _slaID;
        require(
            _leverage <= _maxLeverage && _leverage >= 1,
            "Incorrect leverage"
        );
        leverage = _leverage;
    }

    function addUsersToWhitelist(address[] memory _userAddresses)
        public
        onlyOwner
    {
        for (uint256 index = 0; index < _userAddresses.length; index++) {
            if (whitelist[_userAddresses[index]] == false) {
                whitelist[_userAddresses[index]] = true;
            }
        }
    }

    function removeUsersFromWhitelist(address[] calldata _userAddresses)
        external
        onlyOwner
    {
        for (uint256 index = 0; index < _userAddresses.length; index++) {
            if (whitelist[_userAddresses[index]] == true) {
                whitelist[_userAddresses[index]] = false;
            }
        }
    }

    /**
     *@dev add a token to ve allowed for staking
     *@param _tokenAddress 1. address of the new allowed token
     */
    function addAllowedTokens(address _tokenAddress) external onlyOwner {
        (, , , , , , uint256 maxTokenLength, ) =
            stakeRegistry.getStakingParameters();
        require(!isAllowedToken(_tokenAddress), "Token already added");
        require(
            stakeRegistry.isAllowedToken(_tokenAddress),
            "Token not allowed by the SLARegistry contract"
        );
        allowedTokens.push(_tokenAddress);
        require(
            maxTokenLength >= allowedTokens.length,
            "Allowed tokens length greater than max token length"
        );
        string memory dTokenID = StringUtils.uintToStr(slaID);
        string memory duTokenName =
            string(abi.encodePacked("DSLA-SHORT-", dTokenID));
        string memory duTokenSymbol =
            string(abi.encodePacked("DSLA-SP-", dTokenID));
        string memory dpTokenName =
            string(abi.encodePacked("DSLA-LONG-", dTokenID));
        string memory dpTokenSymbol =
            string(abi.encodePacked("DSLA-LP-", dTokenID));

        ERC20PresetMinterPauser duToken =
            ERC20PresetMinterPauser(
                stakeRegistry.createDToken(duTokenName, duTokenSymbol)
            );
        ERC20PresetMinterPauser dpToken =
            ERC20PresetMinterPauser(
                stakeRegistry.createDToken(dpTokenName, dpTokenSymbol)
            );

        dpTokenRegistry[_tokenAddress] = dpToken;
        duTokenRegistry[_tokenAddress] = duToken;
        emit DTokensCreated(
            _tokenAddress,
            address(dpToken),
            dpTokenName,
            dpTokenName,
            address(duToken),
            duTokenName,
            duTokenName
        );
    }

    /**
     *@dev increase the amount staked per token
     *@param _amount 1. amount to be staked
     *@param _tokenAddress 2. address of the token
     *@notice providers can stake at any time
     *@notice users can stake at any time but no more than provider pool
     */
    function _stake(uint256 _amount, address _tokenAddress)
        internal
        onlyAllowedToken(_tokenAddress)
        onlyWhitelisted
    {
        ERC20(_tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        //duTokens
        if (msg.sender != owner()) {
            (uint256 providerStake, uint256 usersStake) =
                (providerPool[_tokenAddress], usersPool[_tokenAddress]);
            require(
                usersStake.add(_amount).mul(leverage) <= providerStake,
                "Incorrect user stake"
            );
            ERC20PresetMinterPauser duToken = duTokenRegistry[_tokenAddress];
            uint256 p0 = duToken.totalSupply();

            // if there's no minted tokens, then create 1-1 proportion
            if (p0 == 0) {
                duToken.mint(msg.sender, _amount);
            } else {
                uint256 t0 = usersPool[_tokenAddress];
                // mint dTokens proportionally
                uint256 mintedDUTokens = _amount.mul(p0).div(t0);
                duToken.mint(msg.sender, mintedDUTokens);
            }
            usersPool[_tokenAddress] = usersPool[_tokenAddress].add(_amount);
            //dpTokens
        } else {
            ERC20PresetMinterPauser dpToken = dpTokenRegistry[_tokenAddress];
            uint256 p0 = dpToken.totalSupply();

            if (p0 == 0) {
                dpToken.mint(msg.sender, _amount);
            } else {
                uint256 t0 = providerPool[_tokenAddress];
                // mint dTokens proportionally
                uint256 mintedDPTokens = _amount.mul(p0).div(t0);
                dpToken.mint(msg.sender, mintedDPTokens);
            }

            providerPool[_tokenAddress] = providerPool[_tokenAddress].add(
                _amount
            );
        }

        if (registeredStakers[msg.sender] == false) {
            registeredStakers[msg.sender] = true;
            stakers.push(msg.sender);
        }
    }

    /**
     *@dev sets the provider reward
     *@notice it calculates the usersStake and calculates the provider reward from it.
     * @param _periodId 1. id of the period
     * @param _rewardPercentage to calculate the provider reward
     * @param _precision used to avoid getting 0 after division in the SLA's registerSLI function
     */
    function _setRespectedPeriodReward(
        uint256 _periodId,
        uint256 _rewardPercentage,
        uint256 _precision
    ) internal {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            address tokenAddress = allowedTokens[index];
            uint256 usersStake = usersPool[tokenAddress];
            uint256 reward = usersStake.mul(_rewardPercentage).div(_precision);

            usersPool[tokenAddress] = usersPool[tokenAddress].sub(reward);

            providerPool[tokenAddress] = providerPool[tokenAddress].add(reward);

            emit ProviderRewardGenerated(
                _periodId,
                tokenAddress,
                _rewardPercentage,
                _precision,
                reward
            );
        }
    }

    /**
     *@dev sets the users compensation pool
     *@notice it calculates the usersStake and calculates the users compensation from it
     */
    function _setUsersCompensation(uint256 _periodId) internal {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            address tokenAddress = allowedTokens[index];
            uint256 usersStake = usersPool[tokenAddress];
            uint256 compensation = usersStake.mul(leverage);
            providerPool[tokenAddress] = providerPool[tokenAddress].sub(
                compensation
            );
            usersPool[tokenAddress] = usersPool[tokenAddress].add(compensation);
            emit UserCompensationGenerated(
                _periodId,
                tokenAddress,
                usersStake,
                leverage,
                compensation
            );
        }
    }

    /**
     *@dev withdraw staked tokens. Only dpToken owners can withdraw,
     *@param _amount 1. amount to be withdrawn
     *@param _tokenAddress 2. address of the token
     *@param _contractFinished 3. contract finished
     */
    function _withdrawProviderTokens(
        uint256 _amount,
        address _tokenAddress,
        bool _contractFinished
    ) internal onlyAllowedToken(_tokenAddress) {
        uint256 providerStake = providerPool[_tokenAddress];
        uint256 usersStake = usersPool[_tokenAddress];
        if (!_contractFinished) {
            require(
                providerStake.sub(_amount) >= usersStake.mul(leverage),
                "Incorrect withdraw"
            );
        }
        ERC20PresetMinterPauser dpToken = dpTokenRegistry[_tokenAddress];
        uint256 p0 = dpToken.totalSupply();
        uint256 t0 = providerPool[_tokenAddress];
        // Burn duTokens in a way that it doesn't affect the PoolTokens/LPTokens average
        // t0/p0 = (t0-_amount)/(p0-burnedDPTokens)
        // burnedDPTokens = _amount*p0/t0
        uint256 burnedDPTokens = _amount.mul(p0).div(t0);
        dpToken.burnFrom(msg.sender, burnedDPTokens);
        providerPool[_tokenAddress] = providerPool[_tokenAddress].sub(_amount);
        ERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
    }

    /**
     *@dev withdraw staked tokens. Only duToken owners can withdraw,
     *@param _amount 1. amount to be withdrawn
     *@param _tokenAddress 2. address of the token
     */
    function _withdrawUserTokens(uint256 _amount, address _tokenAddress)
        internal
        onlyAllowedToken(_tokenAddress)
    {
        ERC20PresetMinterPauser duToken = duTokenRegistry[_tokenAddress];
        uint256 p0 = duToken.totalSupply();
        uint256 t0 = usersPool[_tokenAddress];
        // Burn duTokens in a way that it doesn't affect the PoolTokens/LPTokens
        // average for current period.
        // t0/p0 = (t0-_amount)/(p0-burnedDUTokens)
        // burnedDUTokens = _amount*p0/t0
        uint256 burnedDUTokens = _amount.mul(p0).div(t0);
        duToken.burnFrom(msg.sender, burnedDUTokens);
        usersPool[_tokenAddress] = usersPool[_tokenAddress].sub(_amount);
        ERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
    }

    /**
     *@dev use this function to evaluate the length of the allowed tokens length
     *@return allowedTokens.length
     */
    function getAllowedTokensLength() external view returns (uint256) {
        return allowedTokens.length;
    }

    function getTokenStake(address _staker, uint256 _allowedTokenIndex)
        external
        view
        returns (address tokenAddress, uint256 stake)
    {
        address allowedTokenAddress = allowedTokens[_allowedTokenIndex];
        if (_staker == owner()) {
            return (allowedTokenAddress, providerPool[allowedTokenAddress]);
        } else {
            ERC20PresetMinterPauser dToken =
                duTokenRegistry[allowedTokenAddress];
            uint256 dTokenSupply = dToken.totalSupply();
            if (dTokenSupply == 0) {
                return (allowedTokenAddress, 0);
            }
            uint256 dTokenBalance = dToken.balanceOf(_staker);
            return (
                allowedTokenAddress,
                usersPool[allowedTokenAddress].mul(dTokenBalance).div(
                    dTokenSupply
                )
            );
        }
    }

    /**
     *@dev checks in the allowedTokens array if there's a token with _tokenAddress value
     *@param _tokenAddress 1. token address to check exixtence
     *@return true if _tokenAddress exists in the allowedTokens array
     */
    function isAllowedToken(address _tokenAddress) public view returns (bool) {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}
