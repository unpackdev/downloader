// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";

/**
* @dev interface to allow gas tokens to be burned from the wrapper
*/
interface IFreeUp {
    function freeUpTo(uint256 value) external returns (uint256 freed);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

/**
* @dev interface to allow gsve to be burned for upgrades
*/
interface IToken {
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


/**
* @dev The v1 smart wrapper is the core gas saving feature
* it can interact with other smart contracts
* it burns gas to save on the transaction fee
* only the owner/deployer of the smart contract can interact with it
* only the owner can send tokens from the address (smart contract)
* only the owner can withdraw tokens of any type, and this goes directly to the owner.
*/
contract GSVESmartWrapper {
    using Address for address;
    address private _owner;

    constructor () public {
        init(msg.sender);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     * also sets the GSVE token reference
     */
    function init (address initialOwner) public {
        require(_owner == address(0), "This contract is already owned");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    /**
    * @dev allow the contract to recieve funds. 
    * This will be needed for dApps that check balances before enabling transaction creation.
    */
    receive() external payable{}

    /**
    * @dev GSVE moddifier that burns gas tokens if the sender wants to burn them
    * burning them if the sender wants to burn them
    */
    modifier discountGas(address gasToken, uint256 tokenFreeValue, bool sender) {
        if(gasToken != address(0)){
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;

            if(tokenFreeValue == 0 || gasSpent < 48000){
                return;
            }

            if(sender){
                IFreeUp(gasToken).freeFromUpTo(msg.sender, (gasSpent + 16000) / tokenFreeValue);
            }
            else{
                IFreeUp(gasToken).freeUpTo((gasSpent + 16000) / tokenFreeValue);
            }
        }
        else {
            _;
        }
    }
    
    /**
    * @dev the wrapTransaction function interacts with other smart contracts on the users behalf
    * this wrapper works for any smart contract
    * as long as the dApp/smart contract the wrapper is interacting with has the correct approvals for balances within this wrapper
    * if the function requires a payment, this is handled too and sent from the wrapper balance.
    */
    function wrapTransaction(bytes calldata data, address contractAddress, uint256 value, address gasToken, uint256 tokenFreeValue, bool sender) external discountGas(gasToken, tokenFreeValue, sender) payable onlyOwner{
        if(!contractAddress.isContract()){
            return;
        }

        if(value > 0){
            contractAddress.functionCallWithValue(data, value, "GS: Error forwarding transaction");
        }
        else{
            contractAddress.functionCall(data, "GS: Error forwarding transaction");
        }
    }

    /**
    * @dev function that the user can trigger to withdraw the entire balance of their wrapper back to themselves.
    */
    function withdrawBalance() public onlyOwner{
        owner().call{value: address(this).balance, gas:gasleft()}("");
    }

    /**
    * @dev function that the user can trigger to withdraw an entire token balance from the wrapper to themselves
    */
    function withdrawTokenBalance(address token) external onlyOwner{
        IToken tokenContract = IToken(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), balance);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
