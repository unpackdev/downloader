// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./Ownable.sol";
import "./IGSVESmartWrapper.sol";

/**
* @dev interface to allow gsve to be burned for upgrades
*/
interface IGSVEToken {
    function burnFrom(address account, uint256 amount) external;
}

contract GSVESmartWrapperFactory is Ownable{
    address payable public smartWrapperLocation;
    mapping(address => address) private _deployedWalletAddressLocation;
    address private GSVEToken;

  constructor (address payable _smartWrapperLocation, address _GSVEToken) public {
    smartWrapperLocation = _smartWrapperLocation;
    GSVEToken = _GSVEToken;
  }

    /**
    * @dev return the location of a users deployed wrapper
    */
    function deployedWalletAddressLocation(address creator) public view returns(address){
        return _deployedWalletAddressLocation[creator];
    }

    /**
    * @dev deploys a gsve smart wrapper for the caller
    * the ownership of the wrapper is transfered to the caller
    * a note is made of where the users wrapper is deployed
    * user pays gsve fee to invoke
    */
  function deployGSVESmartWrapper()  public {
        IGSVEToken(GSVEToken).burnFrom(msg.sender, 10*(10**18));
        address contractAddress = Clones.clone(smartWrapperLocation);
        IGSVESmartWrapper(payable(contractAddress)).init(address(this));
        Ownable(contractAddress).transferOwnership(msg.sender);
        _deployedWalletAddressLocation[msg.sender] = contractAddress;
    }
}