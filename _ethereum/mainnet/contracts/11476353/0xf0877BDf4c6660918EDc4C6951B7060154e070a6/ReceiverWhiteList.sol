// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

struct WhiteRecord {
        bool transferEnabled;
        int128 minBalance;
    }

interface ISmartToken{
    // We nedd this function for access WhiteList functionality from base token
    function whiteList(address _maincontract) external returns (WhiteRecord memory);
    function commonMinBalance() external returns (int128);
    function whiteListEnable() external returns (bool);
    function transferApproved(address from, address to, uint256 amount) external returns (bool);

}

contract ReceiverWhiteList {
    
    //address of token with main WhiteList
    address public token=0xFcE94Fde7aC091c2F1dB00d62F15EeB82b624389;
    /**
     * @dev This function implement before transfer hook form OpenZeppelin ERC20.
     * This only function MUST be implement and return boolean in any `ITransferChecker`
     * smart contract
     */
    
    function transferApproved(address from, address to, uint256 amount) external  returns (bool) {
        //Call transferApproved from token contract
        require(
            ISmartToken(token).transferApproved(from, to, amount)
        );
        
        //Additional check for receiver
        if  (ISmartToken(token).whiteListEnable() == true) {
            WhiteRecord memory whiteListRec = ISmartToken(token).whiteList(to);
            require(whiteListRec.transferEnabled, "Receiver is not whitelist member!");
        }   
        return true;
    }

}
/**
* @dev for unit test
* please DONT DEPLOY IN production
*/
contract mockReceiverWL is ReceiverWhiteList {

    function setToken(address _token) external {
        token = _token;
    }
}