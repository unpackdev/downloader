/**
 *Submitted for verification at Etherscan.io on 2020-06-17
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/BancorHelper.sol

pragma solidity ^0.5.0;


interface IBancorConverterRegistry {
    function getLiquidityPools() external view returns (address[] memory);
}

interface IOwned {
    function owner() external view returns (IConverter);
}

contract ISmartToken is IOwned, IERC20 {
}


contract IConverter {
    function connectorTokens(uint) external view returns (IERC20);
}

contract BancorHelper {

    IBancorConverterRegistry public registry = IBancorConverterRegistry(0x06915Fb082D34fF4fE5105e5Ff2829Dc5e7c3c6D);

    function getConverters() public view returns (IConverter[] memory goodPools) {

        address[] memory smartTokens = registry.getLiquidityPools();

        IConverter[] memory converters = new IConverter[](smartTokens.length);
        uint goodPoolsCount;
        
        for (uint i = 0; i < smartTokens.length; i++) {
            converters[i] = ISmartToken(smartTokens[i]).owner();
            IERC20 firstToken = converters[i].connectorTokens(0);
            if (firstToken.balanceOf(address(converters[i])) > 0) {
                goodPoolsCount++;
            } else {
                converters[i] = IConverter(address(0));
            }
        }
        
        goodPools = new IConverter[](goodPoolsCount);
        uint counter;
          for (uint i = 0; i < smartTokens.length; i++) {
            if (converters[i] == IConverter(address(0))) {
                continue;
            }
            goodPools[counter] = converters[i];
            counter++;
        }
    }
    
    
}