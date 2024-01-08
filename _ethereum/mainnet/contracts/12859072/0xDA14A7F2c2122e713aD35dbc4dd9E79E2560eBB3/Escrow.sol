//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract Escrow is Ownable{
    address public constant charity = 0xb5bc62c665c13590188477dfD83F33631C1Da0ba;
    IERC20 public immutable shelterToken;

    uint public timeLockBuffer;
    uint public timeLock;
    uint private boutiesIndex = 0;

    struct bounty{
        uint amount;
        uint timestamp;
        address sponsor;
    }

    bounty[] bounties;

    constructor(address _shelter){
        shelterToken = IERC20(_shelter);
    }

    event NewBounty(uint);

    /// @dev create a new charity bounty
    function newBounty(uint _amount)external{
        require(_amount != 0, "cannot set a bounty of 0");
        shelterToken.transferFrom(msg.sender, address(this), _amount);

        bounties.push(
            bounty({
                amount: _amount,
                timestamp: block.timestamp,
                sponsor: msg.sender
            })
        );
        emit NewBounty(bounties.length - 1);
    }

    /// @dev closeBounty callable by a bounty's creator
    function closeBounty(uint _i, address _recipient)external{
        require(bounties[_i].amount != 0, "there is no bounty");
        require(bounties[_i].sponsor == msg.sender, "Must be the sponsor to close");
        uint temp = bounties[_i].amount;
        bounties[_i].amount = 0;
        shelterToken.transfer(_recipient, temp);
    }

    /// @dev owner to change the timelock expiration date on bounties
    function changeTimeLock(uint _timeLock) external onlyOwner{
        //If you are decreasing timelock, then update the buffer
        //Must wait to liquidate until people who are instantly eligible for liquidation becaues of a time lock change
        //have waited long enough to be eligible for a liquidation based on the old time lock.
        if(_timeLock < timeLock){
            timeLockBuffer = block.timestamp + timeLock;
        }
        timeLock = _timeLock;
    }

    /// @dev liquidate all the bounties that are expired
    function liquidate()external{
        require(block.timestamp > timeLockBuffer, "There is a buffer in place due to a recent decrease in the time lock period. You must wait to liquidate");
        uint liquidations = 0;
        //Starting from the oldest non-liquidated bounty loop
        for(uint i = boutiesIndex; i < bounties.length; i++){
            //If bounty expired
            if(block.timestamp + timeLock > bounties[i].timestamp){
                //if outstanding balance still
                if(bounties[i].amount > 0){
                    uint temp = bounties[i].amount;
                    bounties[i].amount = 0;
                    liquidations += temp;
                }
            //Once we get to a non-expired bounty
            }else{
                //update the bounties index and break
                boutiesIndex = i;
                break;
            }
        }
        //send liquidated balance to charity
        shelterToken.transfer(charity, liquidations);
    }
}