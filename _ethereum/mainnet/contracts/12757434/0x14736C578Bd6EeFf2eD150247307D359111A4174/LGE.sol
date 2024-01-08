pragma solidity ^0.8.4;

contract LGEContract{
    
    event HarvestRequestApproval(uint request_id);

    event LiquidityCreated(address provider_address);
    
    address public _owner;
    
    mapping (address => bool) private harvesters;
    
    address[] harvesters_arr;
    
    bool public harvestersAdded = false;
    
    address[] liquidityProviders_arr;
    
    uint public _min_confirmation;
    
    mapping (address => uint) public liquidityProviders;
    
    mapping (uint => harvestRequest) public harvestRequests;
    
    //this maps the harvest request id to addresses that have confirmed request. Neccessary to ensure no address verifies a request more than once
    mapping(uint => mapping(address => bool)) confirmers;
    
   harvestRequest[] harvest_rqst_arr;
   
    struct harvestRequest{
        address initiator;
        address payable withdraw_addres;
        uint value;
        uint no_of_confirmations;
        bool executed;
        bool active;
        string harvest_purpose;
    }
    
    enum contractStateEnum {
        active,
        paused
    }
    
    contractStateEnum public _cState = contractStateEnum.active;
    

    modifier onlyOwner(){
        require(msg.sender == _owner, 'Not an owner');
        _;
    }
    
    modifier isActiveHarvestRequest(uint harvest_id){
        require(harvestRequests[harvest_id].active, "Supplied harvest request is currently not active");
        _;
    }
    
    modifier onlyHarvester(){
        require(harvesters[msg.sender], 'Invalid Harvester');
        _;
    }

    constructor (uint min_confirmation){
        _owner = msg.sender;
        harvesters[msg.sender] = true;
        harvesters_arr.push(msg.sender);
        _min_confirmation = min_confirmation;
    }
    
    function addHarvesters(address[] memory founders) public onlyOwner {
        require(!harvestersAdded, "Harvesters already supplied");
        require(founders.length <= 4, "Exceeded total number of required harvesters");
        uint i;
        for(i = 0; i < founders.length; i++){
            require(!harvesters[founders[i]], 'Founder is already added');
            harvesters[founders[i]] = true;
            harvesters_arr.push(founders[i]);
        }
        harvestersAdded = true;
    }
    
    function addLiquidity() payable public{
        require(msg.value > 0 wei, "Please provide minimum amount of 1 wei");
        require(_cState == contractStateEnum.active, "Not currently accepting liquidity, check back in a future time");
        if(liquidityProviders[msg.sender] == 0){
            liquidityProviders_arr.push(msg.sender);
        }
        liquidityProviders[msg.sender] += msg.value;

        //emit event 
        emit LiquidityCreated(msg.sender);
        return;
    }
    
    function getLiquidityProviders() public view returns(address[] memory){
        return liquidityProviders_arr;
    }
    
    function updateContractState(uint _status) public onlyHarvester{
        require(_status <= 1);
        _cState = contractStateEnum(_status);
        return;
    }
    
    function getHarvesters() external view returns(address[] memory){
        return harvesters_arr;
    }
    
    function createHarvestRequest(uint _value, address payable _withdraw_address, string memory _harvest_purpose ) public onlyHarvester{
        require(_value < address(this).balance, "Request amount above contract balance");
        require(_value > 0 wei, "Value of request should be above 0 wei");
        harvestRequests[harvest_rqst_arr.length] = harvestRequest({
            initiator: msg.sender,
            value: _value,
            no_of_confirmations: 0,
            executed: false,
            active: true,
            withdraw_addres: _withdraw_address,
            harvest_purpose: _harvest_purpose
        });
        
        harvest_rqst_arr.push(harvestRequests[harvest_rqst_arr.length]);
    }
    
    function approveHarvestRequest(uint harvest_id) public onlyHarvester isActiveHarvestRequest(harvest_id){
        //check that harvest id is within range
        require(harvest_id <= harvest_rqst_arr.length, "No such request");
        //verify that msg.sender doesn't have a prior approval 
        require(!confirmers[harvest_id][msg.sender], "Already confirmed request");
        //verify that harvest request is active
        require(harvestRequests[harvest_id].active, "Harvest request is currently not active");
        harvestRequests[harvest_id].no_of_confirmations += 1;
        
        //update the confirmers 
        confirmers[harvest_id][msg.sender] = true;
        
        //if the request has exceeded the applied threshhold, emit event
        if(harvestRequests[harvest_id].no_of_confirmations >= _min_confirmation){
            emit HarvestRequestApproval(harvest_id);
        }
    }
    
    function resetHarvestRequestStatus(uint harvest_id) public onlyHarvester{
        require(harvestRequests[harvest_id].initiator == msg.sender, "You can only update request created by you");
        harvestRequests[harvest_id].active = !harvestRequests[harvest_id].active;
    }
    
    function getHarvestRequest()public view onlyHarvester returns(harvestRequest[] memory){
        return harvest_rqst_arr;
    }
    
    function harvestLiquidity(uint harvest_request_id)public onlyHarvester isActiveHarvestRequest(harvest_request_id){
        require(!harvestRequests[harvest_request_id].executed, "Request already harvested");
        require(harvestRequests[harvest_request_id].no_of_confirmations >= _min_confirmation, "Harvest request confirmation below required minimum");
        require(harvestRequests[harvest_request_id].initiator == msg.sender, "Can only harvest self created requests");
        uint value = harvestRequests[harvest_request_id].value;
        harvestRequests[harvest_request_id].withdraw_addres.transfer(value);
        harvestRequests[harvest_request_id].executed = true;
    }
}