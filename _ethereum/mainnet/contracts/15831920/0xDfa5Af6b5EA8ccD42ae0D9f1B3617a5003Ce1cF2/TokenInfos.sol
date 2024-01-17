// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract TokenInfos {
    
    /* Fallback function, don't accept any ETH */
    receive() external payable {
        // revert();
        revert("TokenInfos does not accept payments");
    }
    
    function isContract(address token) public view returns(bool){
        // check if token is actually a contract
        uint256 tokenCode;
        assembly { tokenCode := extcodesize(token) } // contract code size
        return tokenCode > 0;
    }
    
    /**
     * get token symbols for multiple tokens
     */
    function getTokenSymbols(address[] memory tokens) external view returns(string[] memory){
        string[] memory symbols = new string[](tokens.length);
        for(uint32 i = 0; i < tokens.length; i ++){
            IERC20 t = IERC20(tokens[i]);
            try t.symbol() returns (string memory symbol){
                symbols[i] = symbol;
            }catch {
                symbols[i] = "";
            }
        }
        return symbols;
    } 
    
    /**
     * get token decimals for multiple tokens
     */
    function getTokenDecimals(address[] memory tokens) external view returns(uint8[] memory){
        uint8[] memory decimals = new uint8[](tokens.length);
        for(uint32 i = 0; i < tokens.length; i ++){
            IERC20 t = IERC20(tokens[i]);
            try t.decimals() returns (uint8 dec){
                decimals[i] = dec;
            }catch {
                decimals[i] = 0;
            }
        }
        return decimals;
    } 
    
    /**
     * check token allowances for multiple tokens to spenders
     */
    function getTokenAllowance(address[] memory tokens, address[] memory contracts, address account) external view returns(uint256[] memory){
        uint256[] memory allowances = new uint256[](tokens.length);
        for(uint32 i = 0; i < tokens.length; i ++){
            IERC20 t = IERC20(tokens[i]);
            try t.allowance(account, contracts[i]) returns (uint256 amount){
                allowances[i] = amount;
            }catch {
                allowances[i] = 0;
            }
        }
        return allowances;
    }
   
}