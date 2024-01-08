// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract Owned {
    
    /**
    * @dev Error constants.
    */
    string public constant NOT_CURRENT_OWNER = "0101";
    string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "0102";

    /**
    * @dev Current owner address.
    */
    address public owner;

    /**
    * @dev An event which is triggered when the owner is changed.
    * @param previousOwner The address of the previous owner.
    * @param newOwner The address of the new owner.
    */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event _msg(address deliveredTo, string msg);

    function isOwned() internal {
        owner = msg.sender;
        emit _msg(owner, "set owner" );
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        emit _msg(owner, "passed ownership requirement" );
        _;
    }

    /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {

    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function getOwner() public view returns (address){
    return owner;
  }
}