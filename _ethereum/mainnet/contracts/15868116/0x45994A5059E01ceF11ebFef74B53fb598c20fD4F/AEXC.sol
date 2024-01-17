// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

/** 
@title AEXC Smart Contract With Burning Requests Approval
@author CubeLab
**/

contract AEXC is ERC20, Ownable {
    uint256 constant _maxSupply = 25000000 ether;
    uint256 public _currentRequest;

    struct Requests {
        uint256 _burnAmount;
        address _burnAddress;
        bool isSecondTierApproved;
        bool isThirdTierApproved;
    }

    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isSecondTier;
    mapping(address => bool) public isThirdTier;
    mapping(uint256 => Requests) public _requests;

    event BurnRequestCreated(address _burnAddress, uint256 _burnAmount);
    event BurnRequestFulFilled(uint256 _requestId);

    /** 
       
        @param name The Name of the Token
        @param symbol The Symbol of the Token
    */
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {}

    modifier onlyAdmins() {
        require(
            isAdmin[_msgSender()] || _msgSender() == owner(),
            "Unauthorized Call"
        );
        _;
    }

    /** 
        mint tokens to specific address 
        Only Callable by Owner/Admins

        @param to Address that needs to receive tokens.
        @param amount Number of tokens to mint
        
    */

    function mint(address to, uint256 amount) public onlyAdmins {
        require(totalSupply() + amount <= _maxSupply, "Exceeds Max Supply");
        _mint(to, amount);
    }

    /** 
        createBurnRequest is used to Initiate The Request to Burn the Token from any address .
        After Request has been opened , 2ndTier and 3rdTier users need to approve it inorder to burn it.

        @dev every request has its own request id stored in _requests.
        
    */
    function createBurnRequest(address _burnAddress, uint256 _burnAmount)
        public
        onlyAdmins
    {
        _requests[_currentRequest + 1] = Requests(
            _burnAmount,
            _burnAddress,
            false,
            false
        );
        _currentRequest += 1;
        emit BurnRequestCreated(_burnAddress, _burnAmount);
    }

    function fulfillBurn(
        address _from,
        uint256 _burnAmount,
        uint256 requestId
    ) internal {
        _burn(_from, _burnAmount);
        emit BurnRequestFulFilled(requestId);
    }

    /** 
        fulfillBurnRequest needs to be executed by both the 2ndTier and 3rdTier users
        @dev Actual Burn is initiated by the Late Tier Approve. For example if 2ndTier User has approved the burn request then when third tier approves it will burn it.
        @param _tier _tier represents in which tier to add user. 2 = 2nd tier , 3= 3rd Tier
    */

    function fulfillBurnRequest(uint256 requestId, uint256 _tier) public {
        require(authorizedTierUser(_msgSender(), _tier), "Unauthorized Call");
        require(_tier == 2 || _tier == 3, "Unauthorized Tier ID");
        Requests memory _req = _requests[requestId];
        require(_req._burnAddress != address(0), "Invalid Request ID");

        if (_tier == 2) {
            _requests[requestId].isSecondTierApproved = true;
            if (_req.isThirdTierApproved) {
                fulfillBurn(_req._burnAddress, _req._burnAmount, requestId);
            }
        } else {
            _requests[requestId].isThirdTierApproved = true;
            if (_req.isSecondTierApproved) {
                fulfillBurn(_req._burnAddress, _req._burnAmount, requestId);
            }
        }
    }

    function authorizedTierUser(address user, uint256 tier)
        internal
        view
        returns (bool)
    {
        if (tier == 2) {
            return isSecondTier[user];
        } else if (tier == 3) {
            return isThirdTier[user];
        }
        return false;
    }



    function addAdmin(address[] memory _users, bool status) public onlyOwner {
        require(_users.length <=20,"Can perform operation on 20 Address at a time");
        for(uint256 i=0;i<_users.length;i++){
            isAdmin[_users[i]] = status;
        }
    }

    /** 
        Owner can use this function to add users to tiers.
        @param _users List of User Address to Edit
        @param _tier In which Tier to Edit
        @param _status true or false, false to remove , true to add.
    */
    function editTierUser(
        address[] memory _users,
        uint256 _tier,
        bool _status
    ) public onlyOwner {
        require(_users.length <=20,"Can perform operation on 20 Address at a time");
        require(_tier == 2 || _tier == 3, "Invalid Tier User");
        for (uint256 i = 0; i < _users.length; i++) {
            if (_tier == 2) {
                isSecondTier[_users[i]] = _status;
            } else {
                isThirdTier[_users[i]] = _status;
            }
        }
    }
}
