//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./IPaladinController.sol";
import "./PalPool.sol";
import "./IPalPool.sol";
import "./IPalLoan.sol";
import "./IERC20.sol";
import "./Admin.sol";

/** @title Paladin Controller contract  */
/// @author Paladin
contract PaladinController is IPaladinController, Admin {
    using SafeMath for uint;


    /** @notice List of current active palToken Pools */
    address[] public palTokens;
    address[] public palPools;

    bool private initialized = false;

    constructor(){
        admin = msg.sender;
    }

    //Check if an address is a valid palPool
    function isPalPool(address _pool) public view override returns(bool){
        //Check if the given address is in the palPools list
        address[] memory _pools = palPools;
        for(uint i = 0; i < _pools.length; i++){
            if(_pools[i] == _pool){
                return true;
            }
        }
        return false;
    }


    /**
    * @notice Get all the PalTokens listed in the controller
    * @return address[] : List of PalToken addresses
    */
    function getPalTokens() external view override returns(address[] memory){
        return palTokens;
    }


    /**
    * @notice Get all the PalPools listed in the controller
    * @return address[] : List of PalPool addresses
    */
    function getPalPools() external view override returns(address[] memory){
        return palPools;
    }

    /**
    * @notice Set the basic PalPools/PalTokens controller list
    * @param _palTokens array of address of PalToken contracts
    * @param _palPools array of address of PalPool contracts
    * @return bool : Success
    */ 
    function setInitialPools(address[] memory _palTokens, address[] memory _palPools) external override adminOnly returns(bool){
        require(!initialized, "Lists already set");
        require(_palTokens.length == _palPools.length, "List sizes not equal");
        palPools = _palPools;
        palTokens = _palTokens;
        initialized = true;
        return true;
    }
    
    /**
    * @notice Add a new PalPool/PalToken couple to the controller list
    * @param _palToken address of the PalToken contract
    * @param _palPool address of the PalPool contract
    * @return bool : Success
    */ 
    function addNewPool(address _palToken, address _palPool) external override adminOnly returns(bool){
        //Add a new address to the palToken & palPool list
        require(!isPalPool(_palPool), "Already added");

        palTokens.push(_palToken);
        palPools.push(_palPool);

        emit NewPalPool(_palPool, _palToken);

        return true;
    }

    
    /**
    * @notice Remove a PalPool from the list (& the related PalToken)
    * @param _palPool address of the PalPool contract to remove
    * @return bool : Success
    */ 
    function removePool(address _palPool) external override adminOnly returns(bool){
        //Remove a palToken & palPool from the list
        require(isPalPool(_palPool), "Not listed");

        address[] memory _pools = palPools;
        
        uint lastIndex = (_pools.length).sub(1);
        for(uint i = 0; i < _pools.length; i++){
            if(_pools[i] == _palPool){
                //get the address of the PalToken for the Event
                address _palToken = _pools[i];

                //Replace the address to remove with the last one of the array
                palPools[i] = palPools[lastIndex];
                palTokens[i] = palTokens[lastIndex];

                //And pop the last item of the array
                palPools.pop();
                palTokens.pop();

                emit RemovePalPool(_palPool, _palToken);
             
                return true;
            }
        }
        return false;
    }


    /**
    * @notice Check if the given PalPool has enough cash to make a withdraw
    * @param palPool address of PalPool
    * @param amount amount withdrawn
    * @return bool : true if possible
    */
    function withdrawPossible(address palPool, uint amount) external view override returns(bool){
        //Get the underlying balance of the palPool contract to check if the action is possible
        PalPool _palPool = PalPool(palPool);
        return(_palPool.underlyingBalance() >= amount);
    }
    

    /**
    * @notice Check if the given PalPool has enough cash to borrow
    * @param palPool address of PalPool
    * @param amount amount ot borrow
    * @return bool : true if possible
    */
    function borrowPossible(address palPool, uint amount) external view override returns(bool){
        //Get the underlying balance of the palPool contract to check if the action is possible
        PalPool _palPool = PalPool(palPool);
        return(_palPool.underlyingBalance() >= amount);
    }
    

    /**
    * @notice Check if Deposit was correctly done
    * @param palPool address of PalPool
    * @param dest address to send the minted palTokens
    * @param amount amount of palTokens minted
    * @return bool : Verification Success
    */
    function depositVerify(address palPool, address dest, uint amount) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");

        palPool;
        dest;
        amount;
        
        //Check the amount sent isn't null 
        return amount > 0;
    }


    /**
    * @notice Check if Withdraw was correctly done
    * @param palPool address of PalPool
    * @param dest address to send the underlying tokens
    * @param amount amount of underlying token returned
    * @return bool : Verification Success
    */
    function withdrawVerify(address palPool, address dest, uint amount) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");
        
        palPool;
        dest;
        amount;

        //Check the amount sent isn't null
        return amount > 0;
    }
    

    /**
    * @notice Check if Borrow was correctly done
    * @param palPool address of PalPool
    * @param borrower borrower's address 
    * @param amount amount of token borrowed
    * @param feesAmount amount of fees paid by the borrower
    * @param loanAddress address of the new deployed PalLoan
    * @return bool : Verification Success
    */
    function borrowVerify(address palPool, address borrower, address delegatee, uint amount, uint feesAmount, address loanAddress) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");
        
        palPool;
        borrower;
        delegatee;
        amount;
        feesAmount;
        loanAddress;
        
        //no method yet 
        return true;
    }

    /**
    * @notice Check if Expand Borrow was correctly done
    * @param loanAddress address of the PalLoan contract
    * @param newFeesAmount new amount of fees in the PalLoan
    * @return bool : Verification Success
    */
    function expandBorrowVerify(address palPool, address loanAddress, uint newFeesAmount) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");
        
        palPool;
        loanAddress;
        newFeesAmount;
        
        //no method yet 
        return true;
    }


    /**
    * @notice Check if Borrow Closing was correctly done
    * @param palPool address of PalPool
    * @param borrower borrower's address
    * @param loanAddress address of the PalLoan contract to close
    * @return bool : Verification Success
    */
    function closeBorrowVerify(address palPool, address borrower, address loanAddress) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");
        
        palPool;
        borrower;
        loanAddress;
        
        //no method yet 
        return true;
    }


    /**
    * @notice Check if Borrow Killing was correctly done
    * @param palPool address of PalPool
    * @param killer killer's address
    * @param loanAddress address of the PalLoan contract to kill
    * @return bool : Verification Success
    */
    function killBorrowVerify(address palPool, address killer, address loanAddress) external view override returns(bool){
        require(isPalPool(msg.sender), "Call not allowed");
        
        palPool;
        killer;
        loanAddress;
        
        //no method yet 
        return true;
    }

        
    
    //Admin function


    function setPoolsNewController(address _newController) external override adminOnly returns(bool){
        address[] memory _pools = palPools;
        for(uint i = 0; i < _pools.length; i++){
            IPalPool _palPool = IPalPool(_pools[i]);
            _palPool.setNewController(_newController);
        }
        return true;
    }


    function withdrawFromPool(address _pool, uint _amount, address _recipient) external override adminOnly returns(bool){
        IPalPool _palPool = IPalPool(_pool);
        _palPool.withdrawFees(_amount, _recipient);
        return true;
    }


}