// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

//----Important Imports----//
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
//----End Important Imports----//
 



//Create Contract That Is Ownable, Pausable, And Has ReentrancyGuard For Security Purposes
contract PhantasmaMigrator is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    


//----Initializers and Globals----//

    //Keeping That Math Safe
    using SafeMathUpgradeable for uint; 

    //User Balance Storage Struct
    struct UserAccount{
        uint soulBalance;
        uint kcalBalance;
    }

    //Mapping Between Address And User Balance Struct
    mapping(address => UserAccount) public claimableBalance;

    //Useful Metrics For Debt
    uint public totalUnclaimedSOUL;
    uint public totalUnclaimedKCAL;
    
    //Previous ERC20 Contracts
    IERC20Upgradeable public addressSOUL;
    IERC20Upgradeable public addressKCAL;
    
    //Easy Identifiers
    enum TokenType{ SOUL, KCAL }
    enum MathOperation{ Addition, Deduction}

    //Main Initializer
    function initialize() public initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }


//----End Initializers and Globals----//




//----Administrator Functions----//

    //Sets The Balance For A Single Token Using Address Arrays
    function batchUpload(TokenType _token, address[] calldata _addressList, uint[] calldata _tokenAmount) public onlyOwner returns (bool){
        //Checks if Amount Array Length equals Address Array Length *Important
        require(_addressList.length == _tokenAmount.length, "Array Missmatch");
        for (uint i = 0; i < _addressList.length; i++) {
            //Checks For Duplicate Additions
            require((claimableBalance[_addressList[i]].soulBalance == 0) || (claimableBalance[_addressList[i]].kcalBalance == 0), "Data Already Given For Address ");
            
            //Sets The Address Balance For Specified Token
            require(_modifyBalance(_token, MathOperation.Addition, _addressList[i], _tokenAmount[i]), "Math Failed");
        }
        return true;
    }

    //Sets Global ERC20 Token Variables So Contract Can Transfer Tokens
    function setTokenContracts(IERC20Upgradeable _contractSOUL, IERC20Upgradeable _contractKCAL) public onlyOwner returns (bool){
        addressSOUL = _contractSOUL;
        addressKCAL = _contractKCAL;
        return true;
    }

    //Allows Owner To Toggle Contract Pause
    function togglePause() public onlyOwner returns (bool){
        if(paused() == false){
            _pause();
        }else{
            _unpause();
        }
        return true;
    }

//----End Administrator Functions----//




//----User Functions----//

    //Allows User To Claim Thier Rightful Balance
    function claimTokens() public whenNotPaused nonReentrant returns (bool){
        //Require That There Is A Balance To Be Claimed
        require((claimableBalance[msg.sender].soulBalance > 0) || (claimableBalance[msg.sender].kcalBalance > 0), "No Balance To Claim");

        //Claims Tokens
        require(_claimTokens(msg.sender) == true, "Token Claim Failed");
        return true;
    }

//----End User Functions----//




//----Internal Helper Functions----//

    function _modifyBalance(TokenType _token, MathOperation _operation, address _userAddress, uint _tokenAmount) private returns (bool){
        //Adding To Balance
        if(_operation == MathOperation.Addition){
            //Adding To SOUL Balance
            if(_token == TokenType.SOUL){
                //Increase Account Balance
                claimableBalance[_userAddress].soulBalance = claimableBalance[_userAddress].soulBalance.add(_tokenAmount);
               
                //Increase Unclaimed Debt Value
                totalUnclaimedSOUL = totalUnclaimedSOUL.add(_tokenAmount);
                return true;
               
                //Adding To KCAL Balance
            } else if(_token == TokenType.KCAL){
                //Increase Account Balance
                claimableBalance[_userAddress].kcalBalance = claimableBalance[_userAddress].kcalBalance.add(_tokenAmount);

                //Increase Unclaimed Debt Value
                totalUnclaimedKCAL = totalUnclaimedKCAL.add(_tokenAmount);
                return true;
            }
            return false;

            //Subtracting From Balance
        } else if(_operation == MathOperation.Deduction){
            //Subtracting SOUL Balance
            if(_token == TokenType.SOUL){
                //Check If User has Enough Balance To Deduct Amount
                require(claimableBalance[_userAddress].soulBalance >= _tokenAmount, "Too much to Deduct");
                
                //Check If This Makes Sense Compared To Unclaimed Metric
                require(totalUnclaimedSOUL >= _tokenAmount, "Not Enough Unclaimed");
                
                //Subtract From Unclaimed Debt Value
                totalUnclaimedSOUL = totalUnclaimedSOUL.sub(_tokenAmount);
                
                //Safe Subtract From User Balance
                claimableBalance[_userAddress].soulBalance = claimableBalance[_userAddress].soulBalance.sub(_tokenAmount);
                return true;

                //Subtracting KCAL Balance
            } else if(_token == TokenType.KCAL){
                //Check If User has Enough Balance To Deduct Amount
                require(claimableBalance[_userAddress].kcalBalance >= _tokenAmount, "Too much to Deduct");
                
                //Check If This Makes Sense Compared To Unclaimed Metric
                require(totalUnclaimedKCAL >= _tokenAmount, "Not Enough Unclaimed");
                
                //Subtract From Unclaimed Debt Value
                totalUnclaimedKCAL = totalUnclaimedKCAL.sub(_tokenAmount);
                
                //Safe Subtract From User Balance
                claimableBalance[_userAddress].kcalBalance = claimableBalance[_userAddress].kcalBalance.sub(_tokenAmount);
                return true;
            }
            return false;
        }
        return false;
    }

    function _claimTokens(address _userAddress) private returns (bool){
        //If There Is Claimable SOUL 
        if(claimableBalance[_userAddress].soulBalance > 0){
            //Sets Temp Value
            uint tempBalance = claimableBalance[_userAddress].soulBalance;
            
            //Requires That There Is Enough SOUL ERC-20 Balance In Smart Contract
            require(addressSOUL.balanceOf(address(this)) >= totalUnclaimedSOUL, "Not Enough Balance");
            
            //Requires That Transaction Makes Sense
            require(totalUnclaimedSOUL >= tempBalance, "Not Enough Unclaimed");

            //Modifies User Balance
            require(_modifyBalance(TokenType.SOUL, MathOperation.Deduction, _userAddress, tempBalance), "Math Failed");
            
            //Logs Transaction
            emit TokenClaim(msg.sender, "SOUL", tempBalance);

            //Transfers ERC-20 Safely
            SafeERC20Upgradeable.safeTransfer(addressSOUL, _userAddress, tempBalance);
        }
        //If There Is Claimable KCAL 
        if(claimableBalance[_userAddress].kcalBalance > 0){
            //Sets Temp Value
            uint tempBalance = claimableBalance[_userAddress].kcalBalance;

            //Requires That There Is Enough KCAL ERC-20 Balance In Smart Contract
            require(addressKCAL.balanceOf(address(this)) >= totalUnclaimedKCAL, "Not Enough Balance");

            //Requires That Transaction Makes Sense
            require(totalUnclaimedKCAL >= tempBalance, "Not Enough Unclaimed");

            //Modifies User Balance
            require(_modifyBalance(TokenType.KCAL, MathOperation.Deduction, _userAddress, tempBalance), "Math Failed");

            //Logs Transaction
            emit TokenClaim(msg.sender, "KCAL", tempBalance);

            //Transfers ERC-20 Safely
            SafeERC20Upgradeable.safeTransfer(addressKCAL, _userAddress, tempBalance);
        }
        return true;
    }

//----End Internal Helper Functions----//




//----Custom Public Events----//
    event TokenClaim(address indexed _walletAddress, string indexed _tokenName, uint _amount);
//----End Custom Public Events----//

}
