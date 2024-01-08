// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
/**
* This contract was deployed by Ownerfy Inc. of Ownerfy.com
*
* MILK is made by Cash Cows NFTs 
* To make MILK you must be an owner of a Cash Cow
* Then trigger the startOneMilking or startManyMilking methods
* If a Cash Cow is transferred the last owner can still milk
* their milk. If the new owner begins milking it will send the 
* last MILK owed to the last owner first. This allows Cash Cows
* to be on sale without worrying about getting the MILK
* at the last minute. Certain attributes affect the amount of MILK
* produced
*
*/
import "./ERC20.sol";
import "./Ownable.sol";

interface ERC1155Interface {
    function balanceOf(address account, uint256 id) external view returns (uint);
}

contract CCMilk is ERC20, Ownable {
    
    uint256 public constant MAX_MILK = 1000000000000000000000000000;
    //uint public totalSupply = 0;

    address public cowContract = 0x1C2a94FF99221667A4b98B05C6Fe876080D749D0;

    ERC1155Interface ERC1155Contract = ERC1155Interface(cowContract);

    struct CowStatus {
      address recipient;
      uint startBlock;
    }
    mapping (uint256 => CowStatus) public cowStatusMap;
    mapping (uint256 => bool) public isLegendary;


    event StartedMilking(address indexed owner, uint256 indexed id, uint256 blockNumber);
    event Milk(address indexed recipient, uint256 indexed id, uint256 amount);

    constructor() ERC20("Cash Cow MILK", "CCMILK") {

    }

    /**
     * @dev Checks `ids` of Cows if they are owned by owner.
     *
     */
    function _ownsCow(uint256 id) internal virtual returns(bool owns){

        uint256 payload = ERC1155Contract.balanceOf(msg.sender, id);

        if(payload > 0) {
          return true;
        } else {
          return false;
        }

    }

     /**
     * @dev Checks `ids` of Cows if they are owned by owner.
     *
     */
    function _milk(uint256 id) internal virtual {
        require(totalSupply() < MAX_MILK, "Max Milk Reached");
        address lastRecipient = cowStatusMap[id].recipient;
        bool isCurrentOwner = _ownsCow(id);
        require(isCurrentOwner || lastRecipient == msg.sender, "Must be owner or past last");
      
        if(cowStatusMap[id].startBlock == 0) {
          cowStatusMap[id].startBlock = block.number;
          emit StartedMilking(msg.sender, id, block.number);
        }
        
        uint256 milkMade = _getMilkMade(id);

        if(isCurrentOwner == false) {
          // If milk is coming from last owner

          if(milkMade > 0) {
            _mint(lastRecipient, milkMade);
            emit Milk(lastRecipient, id, milkMade);
          }

          // New owner has to initialize
          // Last owner can't tell who new owner is
          cowStatusMap[id].recipient = address(0);
          
        } else {
          // For current owner

          // If milker is owner but old owner still has some milk and hasn't got it
          if(cowStatusMap[id].recipient != msg.sender && cowStatusMap[id].recipient != address(0)) {

            if(milkMade > 0) {
              _mint(lastRecipient, milkMade);
              emit Milk(lastRecipient, id, milkMade);
            }
            
          } else {
            // If owner is already recipient
            if(milkMade > 0) {
              _mint(msg.sender, milkMade);
              emit Milk(msg.sender, id, milkMade);
            }
             
          }

          // Set to new owner if it hasn't been
          cowStatusMap[id].recipient = msg.sender;
          
        }

        // Always trigger block reset
        cowStatusMap[id].startBlock = block.number;
        
    }

    // Milk Many Cows
    /**
     * @dev Milks list of cows.
     *
     */
    function milkManyCows(uint256[] memory ids) public virtual {

        for (uint i = 0; i < ids.length; i++) {
          _milk(ids[i]);
        }
    }

    // Milk Cow
    /**
     * @dev Milks 1 cow.
     *
     */
    function milkCow(uint256 id) public virtual {
        _milk(id);
    }

    // Check cow balance
    /**
     * @dev Check cow balance
     *
     */
    function checkCowBalance(uint256 id) public view returns (uint256 balance){
        if(cowStatusMap[id].startBlock != 0) {
          return _getMilkMade(id);
        }
        return 0;   
    }

    function setMilkContract(address _contract) public onlyOwner {
      cowContract = _contract;
    }

    /**
     * @dev Checks multiplication factor for milk
     *
     */
    function _getMilkMade(uint256 id) internal view returns(uint256 factor) {

      uint256 blockDistance = block.number - cowStatusMap[id].startBlock;
      uint bucketFactor;

      if (id % 12 == 0) {
        bucketFactor = 25;
      } else if (id % 6 == 0) {
        bucketFactor = 20;
      } else if (id % 3 == 0) {
        bucketFactor = 15;
      } else { 
        bucketFactor = 10;
      }
      return blockDistance * bucketFactor * 10**16;
    }

}