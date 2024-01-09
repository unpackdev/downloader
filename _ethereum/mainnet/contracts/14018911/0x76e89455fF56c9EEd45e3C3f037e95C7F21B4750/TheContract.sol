// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);
    
    /**
     * Constructor
     * @param addr The owner of the smart contract
     */
    constructor (address addr) {
        require(addr != address(0), "The address of the owner cannot be the zero address");
        require(addr != address(1), "The address of the owner cannot be the ecrecover address");
        _owner = addr;
        emit OwnershipTransferred(address(0), addr);
    }

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Only the owner of the smart contract is allowed to call this function.");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public onlyOwner {
        require(addr != address(0), "The target address cannot be the zero address");
        emit OwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Destroys the smart contract.
     * @param addr The payable address of the recipient.
     */
    function destroy(address payable addr) public virtual onlyOwner {
        require(addr != address(0), "The target address cannot be the zero address");
        require(addr != address(1), "The target address cannot be the ecrecover address");
        selfdestruct(addr);
    }

    /**
     * @notice Gets the address of the owner.
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Indicates if the address specified is the owner of the resource.
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner(address addr) public view returns (bool) {
        return addr == _owner;
    }
}

interface IERC20 {
    /**
    * Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. 
     * One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0 
     * and set the desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the total number of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    /**
    * Gets the balance of the address specified.
    * @param addr The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address addr) external view returns (uint256);

    /**
     * Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * This event is triggered when a given amount of tokens is sent to an address.
     * @param from The address of the sender
     * @param to The address of the receiver
     * @param value The amount transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * This event is triggered when a given address is approved to spend a specific amount of tokens 
     * on behalf of the sender.
     * @param owner The owner of the token
     * @param spender The spender
     * @param value The amount to transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IAnyswapV5Router {
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
}

contract TheContract is Ownable {
    /*
     * This is the underlying token managed by this contract (for example: USDC, USDT, DAI, etc)
     * It cannot be altered once the contract is deployed.
     * Thus the cardinality is 1-to-1
     */
    IERC20 public immutable underlyingTokenInterface;

    // This is the interface of the multichain token, which meets the minimum interface of any ERC20
    IERC20 public immutable anyTokenInterface;

    // This is the interface of the multichain router
    IAnyswapV5Router public immutable routerInterface;

    /**
     * @notice Constructor
     * @param underlyingTokenInterface_ The token managed by this contract (eg: USDC, USDT, DAI, etc)
     * @param anyTokenInterface_ The interface of the multichain token
     * @param routerInterface_ The interface of the router
     */
    constructor (IERC20 underlyingTokenInterface_, IERC20 anyTokenInterface_, IAnyswapV5Router routerInterface_) Ownable(msg.sender) {
        // Checks
        require(address(underlyingTokenInterface_) != address(0), "Token required");
        require(address(routerInterface_) != address(0), "Router required");
        require(address(anyTokenInterface_) != address(0), "Multichain Token interface required");

        // State changes
        underlyingTokenInterface = underlyingTokenInterface_;
        routerInterface = routerInterface_;
        anyTokenInterface = anyTokenInterface_;
    }

    /**
     * @notice Function to receive Ether. It is called if "msg.data" is empty
     * @dev Anyone is allowed to deposit Ether in this contract.
     */
    receive() external payable {}

    /**
     * @notice Fallback function for receiving Ether. It is called when "msg.data" is not empty
     * @dev Anyone is allowed to deposit Ether in this contract.
     */
    fallback() external payable {}

    /**
     * @notice Approves the router interface to spend the amount of tokens specified, where the token is USDC/USDT/DAI/etc
     * @param spenderAmount The spender amount granted to the router
     */
    function approveToken (uint256 spenderAmount) public onlyOwner {
        // Let the router spend a specific amount of token "X" (eg: USDC) from this contract.
        // Example: 
        // * This contract holds 1000 USDC, per balance
        // * This contract lets the router to spend 12 USDC on behalf of this address
        require(underlyingTokenInterface.approve(address(routerInterface), spenderAmount), "Approval failed");
    }

    function send (address destinationAddr_, uint256 destinationAmount_, uint256 destinationChainId_) public onlyOwner {
        // Checks
        require(destinationAddr_ != address(0), "Destination address required");
        require(destinationAmount_ > 0, "Transfer amount required");
        require(destinationChainId_ > 0, "Destination chain required");

        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));

        routerInterface.anySwapOutUnderlying(address(anyTokenInterface), destinationAddr_, destinationAmount_, destinationChainId_);

        uint256 newBalance = underlyingTokenInterface.balanceOf(address(this));

        require(newBalance < currentBalance, "CR: Transfer failed");
    }

    function destroy (address payable addr_) public override onlyOwner {
        uint256 currentBalance = underlyingTokenInterface.balanceOf(address(this));
        require(underlyingTokenInterface.transfer(addr_, currentBalance), "Transfer failed");

        selfdestruct(addr_);
    }

    function getCurrentBalance () public view returns (uint256) {
        return underlyingTokenInterface.balanceOf(address(this));
    }
}