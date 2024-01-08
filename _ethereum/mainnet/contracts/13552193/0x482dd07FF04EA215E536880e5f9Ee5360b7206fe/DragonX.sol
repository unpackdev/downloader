pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./DAX.sol";

contract DragonX is AccessControl {
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    struct Campaign {
        uint256 engagements;
        uint256 balance;
    }
    
    DAX public DAX_TOKEN = DAX(0x77E9618179820961eE99a988983BC9AB41fF3112);
    
    uint256 public DAX_RATE = 1000000000000000000;
    
    mapping (address => Campaign[]) public campaigns;
    
    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    function setDAXToken(DAX _dax) public onlyRole(ADMIN_ROLE) {
        DAX_TOKEN = _dax;
    }
    
    function setDaxRate(uint256 _rate) public onlyRole(ADMIN_ROLE) {
        DAX_RATE = _rate;
    }
    
    function createCampaign(uint32 _engagements) public {
        uint256 funds = _engagements * DAX_RATE;
        DAX_TOKEN.burnFrom(msg.sender, funds);
        campaigns[msg.sender].push(Campaign(_engagements, funds));
    }
    
    function getCampaign(uint index) public view returns(Campaign memory) {
        return campaigns[msg.sender][index];
    }
    
    function campaignsLength() public view returns (uint) {
        return campaigns[msg.sender].length;
    }
    
    function fundCampaign(uint256 _id, uint256 _funds) public {
        DAX_TOKEN.burnFrom(msg.sender, _funds);
        campaigns[msg.sender][_id].balance += _funds;
    }
}