// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./AccessControlUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

import "./IAlluoStrategy.sol";
import "./IExchange.sol";

contract VoteExecutorV2 is 
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    struct Entry{
        // Percentage of the total contract balance
        // that goes to the exact strategy
        // with 2 desimals, so 6753 == 67.53% 
        uint256 weight;
        // strategy that distributes money to a specific pool
        address strategyAddress;
        // Preferred token for which most exchanges will be made
        address entryToken;
        // Token with which we enter the pool
        address poolToken;
        //
        bytes data;
    }

    struct EntryData{
        // strategy that distributes money to a specific pool
        address strategyAddress;
        //
        bytes data;
    }

    EntryData[] public executedEntries;

    // flag for upgrades availability
    bool public upgradeStatus;

    // List of supported tokens as entry
    EnumerableSetUpgradeable.AddressSet private entryTokens;

    mapping(address => bool) public activeStrategies;

    // Address of the contract responsible for each exchange
    address public exchangeAddress;

    // Acceptable slippage for stablecoin exchange 
    // with 2 decimals, so 200 == 2%
    uint32 public slippage;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    
    /**
     * @dev Contract initializer
     * @param _gnosis gnosis address
     * @param _exchange exchange address
     * @param _startEntryTokens list of supported entry tokens from the beginning
     */
    function initialize(
        address _gnosis, 
        address _exchange, 
        address[] memory _startEntryTokens
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        exchangeAddress = _exchange;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        for(uint256 i = 0; i < _startEntryTokens.length; i++){
            changeEntryTokenStatus(_startEntryTokens[i], true);
        }
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _grantRole(DEFAULT_ADMIN_ROLE, _gnosis);

        slippage = 200;
    }

    /**
     * @dev Main function for executing votes
     * by providing enries
     * @param _entries full info about entry
     */
    function execute(Entry[] memory _entries) external onlyRole(DEFAULT_ADMIN_ROLE){
        uint256 totalWeight;
        for(uint256 i = 0; i < _entries.length; i++){
            totalWeight += _entries[i].weight;
            require(entryTokens.contains(_entries[i].entryToken), "!such entry token");
            require(activeStrategies[_entries[i].strategyAddress], "!such strategy");
        }

        require(totalWeight <= 10000, ">100");

        uint256 totalBalance = getTotalBalance();

        for(uint256 i = 0; i < _entries.length; i++){

            Entry memory entry = _entries[i];

            uint256 amount = entry.weight * totalBalance / 10000;

            // Stablecoins have different decimals, so we need to have one base
            // (18 decimals) for calculation at each step
            uint256 entryDecimalsMult = 10**(18 - IERC20MetadataUpgradeable(entry.entryToken).decimals());
            uint256 poolDecimalsMult = 10**(18 - IERC20MetadataUpgradeable(entry.poolToken).decimals());

            uint256 actualAmount = IERC20MetadataUpgradeable(entry.entryToken).balanceOf(address(this)) * entryDecimalsMult;

            // if entry token not enough contact should exchange other stablecoins
            if(actualAmount < amount){

                uint256 amountLeft = amount - actualAmount;

                uint256 maxLoop = entryTokens.length();
                while(amountLeft > 0 && maxLoop != 0){
                    maxLoop--;
                    (address helpToken, uint256 helpAmount) = findBiggest(entry.entryToken);
                    if(amountLeft <= helpAmount){

                        uint256 exchangeAmountIn = amountLeft / 10**(18 - IERC20MetadataUpgradeable(helpToken).decimals());
                        uint256 exchangeAmountOut = amountLeft / entryDecimalsMult;

                          actualAmount += IExchange(exchangeAddress).exchange(
                            helpToken, 
                            entry.entryToken, 
                            exchangeAmountIn,
                            exchangeAmountOut * (10000 - slippage) / 10000
                        ) * entryDecimalsMult;
                        amountLeft = 0;
                    }
                    else{
                        uint256 exchangeAmountIn = helpAmount / 10**(18 - IERC20MetadataUpgradeable(helpToken).decimals());
                        uint256 exchangeAmountOut = helpAmount / entryDecimalsMult;

                       actualAmount += IExchange(exchangeAddress).exchange(
                            helpToken, 
                            entry.entryToken, 
                            exchangeAmountIn,
                            exchangeAmountOut * (10000 - slippage) / 10000
                        ) * entryDecimalsMult;
                        amountLeft -= helpAmount;
                    }
                }
                amount = actualAmount;
            }
            // final exchange before strategy if needed
            if(entry.entryToken != entry.poolToken){

                amount = IExchange(exchangeAddress).exchange(
                    entry.entryToken, 
                    entry.poolToken, 
                    amount / entryDecimalsMult,
                    0
                );
            }
            else{
                amount = amount / poolDecimalsMult;
            }

            IERC20MetadataUpgradeable(entry.poolToken).safeTransfer(entry.strategyAddress, amount);

            bytes memory exitData = IAlluoStrategy(entry.strategyAddress).invest(entry.data, amount);

            executedEntries.push(EntryData({
                strategyAddress: entry.strategyAddress,
                data: exitData
            }));
        }
    }

    function exitStrategyFully(
        uint256 entryId,
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IAlluoStrategy(executedEntries[entryId].strategyAddress).exitAll(
            executedEntries[entryId].data,
            unwindPercent,
            outputCoin,
            receiver,
            swapRewards
        );
    }

    function exitStrategyRewards(
        uint256 entryId,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IAlluoStrategy(executedEntries[entryId].strategyAddress).exitOnlyRewards(
            executedEntries[entryId].data,
            outputCoin,
            receiver,
            swapRewards
        );
    }


    /**
     * @dev function for calculating the total balance in USD
     * @return totalBalance total value of all entry stableoins on contract
     */
    function getTotalBalance() 
        public 
        view 
        returns(uint256 totalBalance)
    {
        for(uint256 i = 0; i < entryTokens.length(); i++){
            totalBalance += IERC20MetadataUpgradeable(entryTokens.at(i)).balanceOf(address(this)) * 
            10**(18 - IERC20MetadataUpgradeable(entryTokens.at(i)).decimals()); 
        }
    }

    /**
     * @dev function for getting list of entry tokens
     */
    function getListEntryTokens() external view returns (address[] memory) {
        return entryTokens.values();
    }

    /**
     * @dev admin function for changing entry token status
     * @param _tokenAddress address of token
     * @param _status will be token acceptable or not
     */
    function changeEntryTokenStatus(
        address _tokenAddress,
        bool _status
    ) public onlyRole(DEFAULT_ADMIN_ROLE){
        if(_status){
            entryTokens.add(_tokenAddress);
            IERC20MetadataUpgradeable(_tokenAddress).safeApprove(exchangeAddress, type(uint256).max);
        }
        else{
            entryTokens.remove(_tokenAddress);
            IERC20MetadataUpgradeable(_tokenAddress).safeApprove(exchangeAddress, 0);
        }
    }

    /**
     * @dev admin function for changing strategy status
     * @param _strategyAddress address of strategy
     * @param _status will be strategy available or not
     */
    function changeStrategyStatus(
        address _strategyAddress,
        bool _status
    ) public onlyRole(DEFAULT_ADMIN_ROLE){
        activeStrategies[_strategyAddress] = _status;
    }

    /**
     * @dev admin function for changing slippage for exchange
     * @param _slippage new slippage
     */
    function changeSlippage(
        uint32 _slippage
    ) external onlyRole(DEFAULT_ADMIN_ROLE){
        slippage = _slippage;
    }

    /**
     * @dev admin function for adding/changing exchange address
     * @param _exchangeAddress new exchange address
     */
    function addExchange(
        address _exchangeAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE){
        exchangeAddress = _exchangeAddress;
    }

    /**
     * @dev function for getting biggest amount in one token
     * between all stablecoins in contract
     * @param _entry entryToken for not including it in search
     * @return token_ address of biggest by funds in contract token 
     * @return amount_ amount of funds 
     */
    function findBiggest(address _entry) internal view returns(address token_, uint256 amount_){
        for(uint256 i = 0; i < entryTokens.length(); i++){

            if(entryTokens.at(i) != _entry){
                address token = entryTokens.at(i);
                uint256 newAmount = IERC20MetadataUpgradeable(token).balanceOf(address(this)) * 
                10**(18 - IERC20MetadataUpgradeable(token).decimals());
                if(amount_ < newAmount){
                    amount_ = newAmount;
                    token_ = token;
                }
            }
        }
    }

    /**
     * @dev admin function for removing funds from contract
     * @param _address address of the token being removed
     * @param _amount amount of the token being removed
     */
    function removeTokenByAddress(address _address, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address != address(0), "Wrong address");
        IERC20MetadataUpgradeable(_address).safeTransfer(msg.sender, _amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {
        require(upgradeStatus, "Upgrade !allowed");
        upgradeStatus = false;
    }

}

