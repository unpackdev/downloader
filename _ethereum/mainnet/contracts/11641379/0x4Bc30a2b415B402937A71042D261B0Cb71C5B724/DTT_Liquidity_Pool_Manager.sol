/**---------------------------------------------------------------------------/
/**--------------------------------------------------********##########*******/
/**---************--**************--***************--*******###########*******/
/**---************--**************--***************--******####        *******/
/**---**     *****--    *****     --     *****     --*****####         *******/
/**---**     *****--    *****     --     *****     --****############# *******/
/**---**     *****--    *****     --     *****     --***############## *******/
/**---**     *****--    *****     --     *****     --**           #### *******/
/**---**     *****--    *****     --     *****     --**           #### *******/
/**---************--    *****     --     *****     --**############### *******/
/**---************------*****------------*****-------**############### *******/
/**--------------------------------------------------------------------------*/
/**--------------------------------------------------------------------------*/

pragma solidity ^0.7.5;

contract DTT_Liquidity_Pool_Manager {
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event Approval(
        address indexed provider1, 
        address indexed provider2
    );
    event Send(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event Receive(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    /*==============================
    ==============================*/
    
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }
    modifier onlyCreator(){
        address _customerAddress = msg.sender;
        require(_customerAddress == admin);
        _;
    }
    
    mapping(address => bool) internal administrators;
    mapping(address => uint256) internal provider1Approval;
    mapping(address => uint256) internal provider2Approval;
    
    address internal provider1;
    address internal provider2;
    address payable admin;
    address payable _liquidity;
    
    constructor()
    {
        admin = msg.sender;
        administrators[msg.sender] = true; 
    }
    
    receive() external payable
    {
        emit Receive(msg.sender,address(this),msg.value);
    }
    
    function setProvider1(address payable _provider) public onlyCreator()
    {
        provider1 = _provider;
        administrators[_provider] = true;
    }
    
    function setProvider2(address payable _provider) public onlyCreator()
    {
        provider2 = _provider;
        administrators[_provider] = true;
    }
    
    function setMainAddress(address payable _contract) public onlyCreator()
    {
        _liquidity = _contract;
    }
    
    function sendLiquidity(uint256 _amount) public onlyAdministrator()
    {
        require(!isContract(msg.sender),"Sending from contract is not allowed");
        require(msg.sender == provider1 || msg.sender == provider2, "Only Liquidity Provider Can Approve");
        if(msg.sender == provider1)
        {
            if(provider2Approval[_liquidity] == _amount)
            {
                _liquidity.transfer(_amount);
                provider2Approval[_liquidity] = 0;
                emit Send(address(this),_liquidity,_amount);
            }
            else
            {
                provider1Approval[_liquidity] = _amount;
            }
        }
        if(msg.sender == provider2)
        {
            if(provider1Approval[_liquidity] == _amount)
            {
                _liquidity.transfer(_amount);
                provider1Approval[_liquidity] = 0;
                emit Send(address(this),_liquidity,_amount);
            }
            else
            {
                provider2Approval[_liquidity] = _amount;
            }
        }
    }
    
    function sendMoreLiquidity(address payable _other, uint256 _amount) public onlyAdministrator()
    {
        require(!isContract(msg.sender),"Sending from contract is not allowed");
        require(msg.sender == provider1 || msg.sender == provider2, "Only Liquidity Provider Can Approve");
        if(msg.sender == provider1)
        {
            if(provider2Approval[_other] == _amount)
            {
                _other.transfer(_amount);
                provider2Approval[_other] = 0;
                emit Send(address(this),_other,_amount);
            }
            else
            {
                provider1Approval[_other] = _amount;
            }
        }
        if(msg.sender == provider2)
        {
            if(provider1Approval[_other] == _amount)
            {
                _other.transfer(_amount);
                provider1Approval[_other] = 0;
                emit Send(address(this),_other,_amount);
            }
            else
            {
                provider2Approval[_other] = _amount;
            }
        }
    }
    
    function isContract(address account) public view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function destruct() onlyCreator() public{
        selfdestruct(admin);
    }
    
}