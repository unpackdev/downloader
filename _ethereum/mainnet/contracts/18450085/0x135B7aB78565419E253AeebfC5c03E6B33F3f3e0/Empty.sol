// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";

/**
 * Empty, mpty, mty, mt...
 * Join us: https://t.me/empty_token
 * Follow us: https://twitter.com/Empty_Token
 * Learn more: https://www.emptytoken.com
 */
contract Empty is ERC20, ERC20Permit, Ownable {
    uint256 public constant TOTAL_SUPPLY = 639740000 ether;
    uint256 public maxShareByWallet; 
    bool public isSwapEnabled = false;
    mapping(address => bool) public isExcludedFromRestrictions; // Exclude uniswap contracts from maxShareByWallet
    address public pool;

    error SwapIsNotEnabled();
    error MaxShareByWalletReached();
    constructor() ERC20("Empty", "EMPTY") ERC20Permit("Empty") {
        _mint(msg.sender, TOTAL_SUPPLY);
        maxShareByWallet = TOTAL_SUPPLY * 5 / 1000; // 0.5%
        isExcludedFromRestrictions[msg.sender] = true;
        isExcludedFromRestrictions[address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88)] = true; // Exclude Uniswap v3 NonfungiblePositionManager
        isExcludedFromRestrictions[address(0x1F98431c8aD98523631AE4a59f267346ea31F984)] = true; // Exclude Uniswap v3 PoolFactory
    }

    function _transfer(address from, address to, uint256 amount) internal override(ERC20)  {
        if (!isSwapEnabled && from != owner() && to != owner()) {
            revert SwapIsNotEnabled(); 
        }

        if(from != owner() && !isExcludedFromRestrictions[to] && super.balanceOf(to) + amount > maxShareByWallet){
            revert MaxShareByWalletReached(); 
        }

        super._transfer(from, to, amount);  
    }

    /**
     * Allow to exclude the owner and uniswap v3 contracts from maxShare restriction to allow us at the very begining to create the pool and lock the tokens. We will rennonce few minutes after launch.
     */
    function excludeFromMaxRestrictions(
        address _address,
        bool _isExclude
    ) public onlyOwner {
        isExcludedFromRestrictions[_address] = _isExclude;
    }

    /**
     * As soon as the pool is created, we will set it in the contract and exclude it for trading & maxShare restriction to prevent issue
     */
    function setPool(address _address) external onlyOwner {
        pool = _address;
        isExcludedFromRestrictions[_address] = true;
    }

    /**
     * 0.5% during launch, then can be update to 3%
     */
    function setMaxShareByWallet(uint256 _newShare) external onlyOwner {
        maxShareByWallet = _newShare;
    }

    /**
     * This will be called once at the very begining after liquidity added on uniswapv3. isSwapEnabled can never be put back to false
     */
    function enableSwap() external onlyOwner {
        isSwapEnabled = true;
    }
}