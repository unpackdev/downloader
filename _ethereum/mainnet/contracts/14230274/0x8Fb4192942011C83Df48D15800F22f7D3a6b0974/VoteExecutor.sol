// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Pausable.sol";
import "./AccessControl.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";

import "./UniversalCurveConvexStrategy.sol";

contract VoteExecutor is AccessControl {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Entry{
        // Percentage of the total contract balance
        // that goes to the exact strategy
        uint8 weight;
        // Preferred token for which most exchanges will be made
        address entryToken;
        // Address of the pool on curve
        address curvePool;
        // Token with which we enter the pool
        address poolToken;
        // How many tokens pool contains
        uint8 poolSize;
        // PoolToken index in pool
        uint8 tokenIndexInCurve;
        // Address of the pool on convex
        // zero address if not exist
        address convexPoolAddress;
        // special pool id on convex
        uint256 convexPoold;
    }

    // List of supported tokens as entry
    EnumerableSet.AddressSet private entryTokens;

    // Address of the contract that distributes
    // tokens to the right curve/convex pools 
    address public strategyDeployer;
    // Address of the contract responsible for each exchange
    address public exchangeAddress;
    // Acceptable slippage for stablecoin exchange 
    uint32 public slippage = 2;

    /**
     * @dev Contract constructor
     * @param _newAdmin gnosis address
     * @param _strategy strategy address
     * @param _exchange exchange address
     * @param _startEntryTokens list of supported entry tokens from the beginning
     */
    constructor(address _newAdmin, address _strategy, address _exchange, address[] memory _startEntryTokens)
    {
        strategyDeployer = _strategy;
        exchangeAddress = _exchange;

        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        for(uint256 i = 0; i < _startEntryTokens.length; i++){
            changeEntryTokenStatus(_startEntryTokens[i], true);
        }
    }

    /**
     * @dev Main function for executing votes
     * by providing enries
     * @param _entries full info about entry
     */
    function execute(Entry[] memory _entries) external onlyRole(DEFAULT_ADMIN_ROLE){
        uint8 totalWeight;
        for(uint256 i = 0; i < _entries.length; i++){
            totalWeight += _entries[i].weight;
            require(entryTokens.contains(_entries[i].entryToken), "There is no such entry token");
        }
        require(totalWeight <= 100, "Total weight more then 100");

        uint256 totalBalance = getTotalBalance();

        for(uint256 i = 0; i < _entries.length; i++){

            Entry memory entry = _entries[i];

            uint256 amount = entry.weight * totalBalance / 100;

            // Stablecoins have different decimals, so we need to have one base
            // (18 decimals) for calculation at each step
            uint256 entryDecimalsMult = 10**(18 - ERC20(entry.entryToken).decimals());
            uint256 poolDecimalsMult = 10**(18 - ERC20(entry.poolToken).decimals());

            uint256 actualAmount = IERC20(entry.entryToken).balanceOf(address(this)) * entryDecimalsMult;

            // if entry token not enough contact should exchange other stablecoins
            if(actualAmount < amount){
                uint256 amountLeft = amount - actualAmount;

                uint256 maxLoop = entryTokens.length();
                while(amountLeft > 0 && maxLoop != 0){
                    maxLoop--;
                    (address helpToken, uint256 helpAmount) = findBiggest(entry.entryToken);
                    if(amountLeft <= helpAmount){

                        uint256 exchangeAmountIn = amountLeft / 10**(18 - ERC20(helpToken).decimals());
                        uint256 exchangeAmountOut = amountLeft / entryDecimalsMult;

                        actualAmount += IExchange(exchangeAddress).exchange(
                            helpToken, 
                            entry.entryToken, 
                            exchangeAmountIn,
                            exchangeAmountOut * (100 - slippage) / 100
                        ) * entryDecimalsMult;
                        amountLeft = 0;
                    }
                    else{
                        uint256 exchangeAmountIn = helpAmount / 10**(18 - ERC20(helpToken).decimals());
                        uint256 exchangeAmountOut = helpAmount / entryDecimalsMult;

                        actualAmount += IExchange(exchangeAddress).exchange(
                            helpToken, 
                            entry.entryToken, 
                            exchangeAmountIn,
                            exchangeAmountOut * (100 - slippage) / 100
                        ) * entryDecimalsMult;
                        amountLeft -= helpAmount;
                    }
                }
                amount = actualAmount;
            }
            // final exchange before curve if needed
            if(entry.entryToken != entry.poolToken){

                amount = IExchange(exchangeAddress).exchange(
                    entry.entryToken, 
                    entry.poolToken, 
                    amount / entryDecimalsMult,
                    0
                );
                if(!entryTokens.contains(entry.poolToken)){
                    IERC20(entry.poolToken).safeIncreaseAllowance(strategyDeployer, amount);
                }
            }
            else{
                amount = amount / poolDecimalsMult;
            }
            uint256[4] memory arrAmounts;
            arrAmounts[entry.tokenIndexInCurve] = amount;
            
            IERC20[4] memory arrTokens;
            arrTokens[entry.tokenIndexInCurve] = IERC20(entry.poolToken);

            // entering curve with all amount of pool tokens
            IERC20(entry.poolToken).safeTransfer(strategyDeployer, amount);

            UniversalCurveConvexStrategy(strategyDeployer).deployToCurve(
                arrAmounts,
                arrTokens,
                entry.poolSize,
                entry.curvePool
            );

            // if convex pool was provided enteing convex with all lp from curve 
            if(entry.convexPoolAddress != address(0)){
                
                UniversalCurveConvexStrategy(strategyDeployer).deployToConvex(
                    entry.convexPoolAddress,
                    entry.convexPoold
                );
            }
        }
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
            totalBalance += IERC20(entryTokens.at(i)).balanceOf(address(this)) * 10**(18 - ERC20(entryTokens.at(i)).decimals()); 
        }
    }

    /**
     * @dev function for getting list of entry tokens
     */
    function getListEntryTokens() public view returns (address[] memory) {
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
            IERC20(_tokenAddress).safeApprove(exchangeAddress, type(uint256).max);
            IERC20(_tokenAddress).safeApprove(strategyDeployer, type(uint256).max);
        }
        else{
            entryTokens.remove(_tokenAddress);
            IERC20(_tokenAddress).safeApprove(exchangeAddress, 0);
            IERC20(_tokenAddress).safeApprove(strategyDeployer, 0);
        }
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
     * @dev admin function for adding/changing strategy address
     * @param _strategyAddress new strategy address
     */
    function addStrategy(
        address _strategyAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE){
        strategyDeployer = _strategyAddress;
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
                uint256 newAmount = IERC20(token).balanceOf(address(this)) * 10**(18 - ERC20(token).decimals());
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
        require(_address != address(0), "Invalid token address");
        IERC20(_address).safeTransfer(msg.sender, _amount);
    }

}

// interface for exchange
interface IExchange{
    function exchange(
        address from,
        address to,
        uint256 amountIn,
        uint256 minAmountOut
    ) external payable returns (uint256);
}
