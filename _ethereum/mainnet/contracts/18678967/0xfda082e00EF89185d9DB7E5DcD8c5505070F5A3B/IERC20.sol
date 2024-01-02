// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/*
 *  @title Interface of the ERC20 standard as defined in the EIP,
 *         including EIP-2612 permit functionality.
 */
interface IERC20 {

    /**********************************************************************************************/
    /*** Events                                                                                 ***/
    /**********************************************************************************************/

    /**
     *  @dev   Emitted when one account has set the allowance of another account over their tokens.
     *  @param owner   Account that tokens are approved from.
     *  @param spender Account that tokens are approved for.
     *  @param amount  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     *  @dev   Emitted when tokens have moved from one account to another.
     *  @param owner     Account that tokens have moved from.
     *  @param recipient Account that tokens have moved to.
     *  @param amount    Amount of tokens that have been transferred.
     */
    event Transfer(address indexed owner, address indexed recipient, uint256 amount);

    /**********************************************************************************************/
    /*** External Functions                                                                     ***/
    /**********************************************************************************************/

    /**
     *  @dev    Function that allows one account to set the allowance of another account
     *          over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender Account that tokens are approved for.
     *  @param  amount  Amount of tokens that have been approved.
     *  @return success Boolean indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     *  @dev    Function that allows one account to decrease the allowance of another
     *          account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender          Account that tokens are approved for.
     *  @param  subtractedAmount Amount to decrease approval by.
     *  @return success          Boolean indicating whether the operation succeeded.
     */
    function decreaseAllowance(address spender, uint256 subtractedAmount)
        external returns (bool success);

    /**
     *  @dev    Function that allows one account to increase the allowance of another
     *          account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender     Account that tokens are approved for.
     *  @param  addedAmount Amount to increase approval by.
     *  @return success     Boolean indicating whether the operation succeeded.
     */
    function increaseAllowance(address spender, uint256 addedAmount)
        external returns (bool success);

    /**
     *  @dev   Approve by signature.
     *  @param owner    Owner address that signed the permit.
     *  @param spender  Spender of the permit.
     *  @param amount   Permit approval spend limit.
     *  @param deadline Deadline after which the permit is invalid.
     *  @param v        ECDSA signature v component.
     *  @param r        ECDSA signature r component.
     *  @param s        ECDSA signature s component.
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     *  @dev    Moves an amount of tokens from `msg.sender` to a specified account.
     *          Emits a {Transfer} event.
     *  @param  recipient Account that receives tokens.
     *  @param  amount    Amount of tokens that are transferred.
     *  @return success   Boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) external returns (bool success);

    /**
     *  @dev    Moves a pre-approved amount of tokens from a sender to a specified account.
     *          Emits a {Transfer} event.
     *          Emits an {Approval} event.
     *  @param  owner     Account that tokens are moving from.
     *  @param  recipient Account that receives tokens.
     *  @param  amount    Amount of tokens that are transferred.
     *  @return success   Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address owner, address recipient, uint256 amount)
        external returns (bool success);

    /**********************************************************************************************/
    /*** View Functions                                                                         ***/
    /**********************************************************************************************/

    /**
     *  @dev    Returns the allowance that one account has given another over their tokens.
     *  @param  owner     Account that tokens are approved from.
     *  @param  spender   Account that tokens are approved for.
     *  @return allowance Allowance that one account has given another over their tokens.
     */
    function allowance(address owner, address spender) external view returns (uint256 allowance);

    /**
     *  @dev    Returns the amount of tokens owned by a given account.
     *  @param  account Account that owns the tokens.
     *  @return balance Amount of tokens owned by a given account.
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     *  @dev    Returns the decimal precision used by the token.
     *  @return decimals The decimal precision used by the token.
     */
    function decimals() external view returns (uint8 decimals);

    /**
     *  @dev    Returns the signature domain separator.
     *  @return domainSeparator The signature domain separator.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);

    /**
     *  @dev    Returns the name of the token.
     *  @return name The name of the token.
     */
    function name() external view returns (string memory name);

    /**
      *  @dev    Returns the nonce for the given owner.
      *  @param  owner  The address of the owner account.
      *  @return nonce The nonce for the given owner.
     */
    function nonces(address owner) external view returns (uint256 nonce);

    /**
     *  @dev    Returns the permit type hash.
     *  @return permitTypehash The permit type hash.
     */
    function PERMIT_TYPEHASH() external view returns (bytes32 permitTypehash);

    /**
     *  @dev    Returns the symbol of the token.
     *  @return symbol The symbol of the token.
     */
    function symbol() external view returns (string memory symbol);

    /**
     *  @dev    Returns the total amount of tokens in existence.
     *  @return totalSupply The total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 totalSupply);

}
