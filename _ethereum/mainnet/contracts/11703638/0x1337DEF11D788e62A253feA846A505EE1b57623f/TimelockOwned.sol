// Sources flattened with hardhat v2.0.8 https://hardhat.org

// File contracts/general/Ownable.sol

pragma solidity ^0.6.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * 
 * @dev We've added a second owner to share control of the timelocked owner contract.
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;
    
    // Second allows a DAO to share control.
    address private _secondOwner;
    address private _pendingSecond;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SecondOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initializeOwnable() internal {
        require(_owner == address(0), "already initialized");
        _owner = msg.sender;
        _secondOwner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        emit SecondOwnershipTransferred(address(0), msg.sender);
    }


    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @return the address of the owner.
     */
    function secondOwner() public view returns (address) {
        return _secondOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "msg.sender is not owner");
        _;
    }
    
    modifier onlyFirstOwner() {
        require(msg.sender == _owner, "msg.sender is not owner");
        _;
    }
    
    modifier onlySecondOwner() {
        require(msg.sender == _secondOwner, "msg.sender is not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner || msg.sender == _secondOwner;

    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyFirstOwner {
        _pendingOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == _pendingOwner, "only pending owner can call this function");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferSecondOwnership(address newOwner) public onlySecondOwner {
        _pendingSecond = newOwner;
    }

    function receiveSecondOwnership() public {
        require(msg.sender == _pendingSecond, "only pending owner can call this function");
        _transferSecondOwnership(_pendingSecond);
        _pendingSecond = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferSecondOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit SecondOwnershipTransferred(_secondOwner, newOwner);
        _secondOwner = newOwner;
    }

    uint256[50] private __gap;
}


// File contracts/general/TimelockOwned.sol

// SPDX-License-Identifier: (c) Armor.Fi DAO, 2021

pragma solidity ^0.6.6;

/**
 * @dev Simple timelock owner contract to be used until we implement a governance contract.
**/
contract TimelockOwned is Ownable {
    
    // Incremental counter of proposal IDs.
    uint256 id;
    
    // Amount of time that must pass before a proposal can be implemented. Change this to 2 days before public launch.
    uint256 public timelock;
    
    struct Proposal {
        uint128 id;
        uint128 ending;
        address target;
        uint256 value;
        bytes data;
    }
    
    // Mapping of proposal ID => proposal struct.
    mapping (uint256 => Proposal) proposals;

    event ProposalSubmitted(uint256 id, address target, uint256 value, bytes data, uint256 timestamp, uint256 execTimestamp);
    event ProposalExecuted(uint256 id, address target, uint256 value, bytes data, uint256 timestamp);

    constructor()
      public
    {
        Ownable.initializeOwnable();
    }

    /**
     * @dev External execution.
    **/
    function implementProposal(uint256 _id)
      external
      onlyOwner
    {
        Proposal memory proposal = proposals[_id];
        require(proposal.ending != 0 && proposal.ending <= block.timestamp);
        executeProposal(proposal.target, proposal.value, proposal.data);
        emit ProposalExecuted(_id, proposal.target, proposal.value, proposal.data, block.timestamp);
        delete proposals[_id];
    }
    
    function submitProposal(address _target, uint256 _value, bytes calldata _data)
      external
      onlyOwner
    {
        id++;
        Proposal memory proposal = Proposal(uint128(id), uint128(block.timestamp + timelock), _target, _value, _data);
        proposals[id] = proposal;
        emit ProposalSubmitted(id, proposal.target, proposal.value, proposal.data, block.timestamp, uint256(proposal.ending));
    }
    
    function deleteProposal(uint256 _id)
      external
      onlyOwner
    {
        delete proposals[_id];
    }
    
    function changeTimelock(uint256 _time)
      public
    {
        require(msg.sender == address(this), "Only this contract may change timelock.");
        timelock = _time;
    }
    
    function executeProposal(address _target, uint256 _value, bytes memory _data)
      internal
    {
        (bool success, ) = _target.call{value: _value}(_data);
        require(success, "Failed to execute proposal");
    }
    
}