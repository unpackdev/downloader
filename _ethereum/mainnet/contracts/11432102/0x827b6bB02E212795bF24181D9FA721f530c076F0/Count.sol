pragma solidity ^0.5.0;

contract Governance {

    address public _governance;
    bool  public isOpen;
    constructor() public {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}

contract Count is Governance{
    mapping(address=>bool) set_pool;
    mapping(address=>address) user_pool;
    mapping(address=>bool) isPlayaddress;
    mapping(string=>bool) name_set;
    modifier onlyPlayAddress(){
        require(isPlayaddress[msg.sender],"not Playaddress");
        _;
    }
    function is_Re(address user,string memory name) view public onlyPlayAddress returns(bool){
        return set_pool[user]||name_set[name];
    }
    
    function is_Re(address user) view public onlyPlayAddress returns(bool){
        return set_pool[user];
    }
    
    function add_PlyAddress(address ply) onlyGovernance public {
        isPlayaddress[ply] = true;
    }
    
    function remove_PlyAddress(address ply) onlyGovernance public {
        isPlayaddress[ply] = false;
    }
    
    
    function set_user_isRe(address user,address pool,string memory name) public onlyPlayAddress {
        user_pool[user] = pool;
        set_pool[user] = true;
        name_set[name] = true;
    }
    
    modifier is_open(){
        require(isOpen==true || msg.sender==_governance);
        _;
    }
    
    function Open_() public onlyGovernance{
        isOpen = !isOpen;
    }
    
    function get_Address_pool(address user) view public is_open returns(address){
        return user_pool[user];
    }
    
}