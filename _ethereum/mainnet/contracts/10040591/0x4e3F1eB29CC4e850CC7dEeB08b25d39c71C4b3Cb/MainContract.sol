/**
 * Version 3. 09 apr 2020 Chelbukhov A.
 * Add external storage for base data
 */

pragma solidity ^0.5.16;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address candidate;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);    
    _;
  }



  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    candidate = newOwner;
  }

  function confirmOwnership() public {
    require(candidate == msg.sender);
    emit OwnershipTransferred(owner, candidate);
    owner = candidate;
    delete candidate;
  }


}



contract KEDRON is StandardToken {
    string public name ='';
    string public symbol = '';
    uint32 public constant decimals = 0;
    uint256 public INITIAL_SUPPLY = 0;
    address public mainContract;
    address candidate;


    event Mint(address indexed to, uint256 amount, string comment);
    event Burn(address indexed burner, uint256 value, string comment);
    
    constructor(address _MainContract, string memory _name, string memory _symbol) public {
        mainContract = _MainContract;
        name = _name;
        symbol = _symbol;
    }
  
    modifier onlyOwner() {
        // only MainContract contract
        require(msg.sender == mainContract);
        _;
    }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    candidate = newOwner;
  }

  function confirmOwnership() public {
    require(candidate == msg.sender);
    mainContract = candidate;
    delete candidate;
  }



  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount, string memory _comment) onlyOwner public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount, _comment);
    emit Transfer(address(0), _to, _amount);
    return true;
  }     

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(address _investor, uint256 _value, string memory _comment) onlyOwner public {
        require(_value > 0);
        require(_value <= balances[_investor]);

        balances[_investor] = balances[_investor].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_investor, _value, _comment);
        emit Transfer(_investor, address(0), _value);
    }
     
    /**
     * @dev Override for restricted function
     */
    function transfer(address _to, uint256 _value) public onlyOwner returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Override for restricted function
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyOwner returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }


    function() external payable {
        // The token contract don`t receive ether
        revert();
    }  
}


contract ExternalStorage is Ownable {
    address public addrMainContract;
    //address public owner;
    uint public constant maxRecords = 100;

    struct RP {
        uint256 ID ;
        string name ;
        string location ;
        string description ;
        string site;
        string googlemap;
        string pathToPhoto;
        bool isWork ;
    }
    
    RP[] public rps;                                     //patrimonial settlement (родовые поселения)



    struct User {
        string login;
        string name;
        uint256 RPID;
        bool isRPAdmin;
        bool isUser;
        mapping(uint256 => uint256) projetcsDep;        // вложения в проекты: ProjectID => Amount
    }
    mapping (address => User) public users;
    mapping (string => address) public userAddress;             //string = login

    string[] public userArray;                                  // Array of login users
    mapping (string => bool) isUserInArray;                      // string = login - mapping for quick detect users in userArray
    
    struct Project {
        uint256 ID;
        string name;
        string description;
        uint256 RPID;
        address admin;
        uint256 profit;
        string site;
        string pathToPhoto;
        bool isWork;
    }
    Project[] public projects;

    constructor(address _owner) public {
        owner = _owner;
        addrMainContract = msg.sender;
    }
  
    modifier onlyOwner() {
        // only MainContract contract
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyMainContract() {
        // only MainContract contract
        require(msg.sender == addrMainContract);
        _;
    }     
     
        modifier isRPAdmin (address _addr) {
        require(users[_addr].isRPAdmin == true, "Only for project admins");
        _;
    }

    /**
     * internal functions 
     */
    function getNewRPID() internal view returns (uint256) {
        return rps.length +1;
    }
    
        function getNewProjectID() internal view returns (uint256) {
        return projects.length +1;
    }
    
    function getRPID(address _addr) internal view returns (uint256) {
        return users[_addr].RPID;
    }

    function getRPName(uint256 _RPID) internal view returns (string memory) {
        return rps[_RPID-1].name;
    }

    /**
     * Migrate functions
     */
    function changeAddrMainContract(address _newAddr) public onlyOwner {
        addrMainContract = _newAddr;
    }
    
    
    /**
     * Base functions
     */
    function isRPAdminF (address _addr) public view returns(bool) {
        return users[_addr].isRPAdmin;
        
    }

    function addRP(string memory _name, string memory _location, string memory _description) public onlyOwner {
        //get new ID
        uint256 myID = getNewRPID();
        
        RP memory newRP = RP({
            ID: myID,
            name: _name,
            location: _location,
            description: _description,
            site: '',
            googlemap: '',
            pathToPhoto: '',
            isWork: true
        });
        rps.push(newRP);
    }
    
    function addRPAdmin(uint256 _RPID, string memory _login, string memory _name, address _addr) public onlyOwner {
        require (_addr != address(0),"Only real address");
        User memory newUser = User ({
            login: _login,
            name: _name,
            RPID: _RPID,
            isRPAdmin: true,
            isUser: true
        });
        users[_addr] = newUser;
        if (isUserInArray[_login] == false) userArray.push(_login);
        userAddress[_login] = _addr;
        isUserInArray[_login] = true;
    }

    function cleareUser(string memory _login) public onlyOwner {
        address myAddr = userAddress[_login];
        User memory clearUser = User ({
            login: "",
            name: "",
            RPID: 0,
            isRPAdmin: false,
            isUser:false
        });
        users[myAddr] = clearUser;
        userAddress[_login]=address(0);
    }

    function addProject(string memory _name, string memory _description) public isRPAdmin(msg.sender) {
        uint256 newProjectID = getNewProjectID();
        uint256 myRPID = getRPID(address(msg.sender));
        Project memory newProject = Project ({
            ID: newProjectID,
            name: _name,
            description: _description,
            RPID: myRPID,
            admin: address(msg.sender),
            profit: 0,
            pathToPhoto: '',
            site: '',
            isWork: true
        });
        projects.push(newProject);
    }
    
    function editProjectProfit(uint256 _projectID, uint256 _newProfit) public isRPAdmin(msg.sender) {
        projects[_projectID-1].profit = _newProfit;
    }

    function editProjectPhoto(uint256 _projectID, string memory _newPhoto) public isRPAdmin(msg.sender) {
        projects[_projectID-1].pathToPhoto = _newPhoto;
    }

    function editProjectSite(uint256 _projectID, string memory _newSite) public isRPAdmin(msg.sender) {
        projects[_projectID-1].site = _newSite;
    }

    function addUser(string memory _login, string memory _name, address _addr) public isRPAdmin(msg.sender) {
        require (_addr != address(0),"Only real address");
        require(userAddress[_login] == address(0),"This login allready in base");
        require(users[_addr].isUser == false,"This address allready in base");
        User memory newUser = User ({
            login: _login,
            name: _name,
            RPID: getRPID(msg.sender),
            isRPAdmin: false,
            isUser:true
        });
        users[_addr] = newUser;
        if (isUserInArray[_login] == false) userArray.push(_login);
        userAddress[_login] = _addr;
        isUserInArray[_login] = true;

    }

    function changeUserLogin (string memory _oldLogin, string memory _newLogin) public isRPAdmin(msg.sender) {
        require(isUserInArray[_oldLogin] == true, 'User not found');
        uint32 x = 0;
        address myUserAddress;
        while (x < userArray.length) {
            if (keccak256(bytes(userArray[x])) == keccak256(bytes(_oldLogin))){
                myUserAddress = userAddress[_oldLogin];
                userArray[x] = _newLogin;
                users[myUserAddress].login = _newLogin;
                userAddress[_oldLogin] = address(0);
                userAddress[_newLogin] = myUserAddress;
                isUserInArray[_oldLogin] = false;
                isUserInArray[_newLogin] = true;
            }
            x++;
        }
    }
    function changeUserName (address _userAddress, string memory _newName) public isRPAdmin (msg.sender) {
        require (_userAddress != address(0), 'invalid address');
        users[_userAddress].name = _newName;
    }

     function getUserCount() public view returns(uint256) {
         return userArray.length;
     }

     function getRPCount() public view returns(uint256) {
         return rps.length;
     }

     function getProjectCount() public view returns(uint256) {
         return projects.length;
     }
     
     function getUserDeposit(address _addr, uint256 _projectID) public view returns (uint256) {
         return users[_addr].projetcsDep[_projectID];
     }


 /**
     * Main admin functions for patrimonial settlement control
     */


    function editRPName(uint256 _RPID, string memory _newName) public onlyOwner {
        rps[_RPID-1].name = _newName;
    }
    
    function editRPLocation(uint256 _RPID, string memory _newLocation) public onlyOwner {
        rps[_RPID-1].location = _newLocation;
    }
    
    function editRPDescription(uint256 _RPID, string memory _newDescription) public onlyOwner {
        rps[_RPID-1].description = _newDescription;
    }    

    function editRPsite(uint256 _RPID, string memory _newSite) public onlyOwner {
        rps[_RPID-1].site = _newSite;
    }    
    
    function editRPGoogleMap(uint256 _RPID, string memory _newGoogleMap) public onlyOwner {
        rps[_RPID-1].googlemap = _newGoogleMap;
    }    

    function editRPPhoto(uint256 _RPID, string memory _pathToPhoto) public onlyOwner {
        rps[_RPID-1].pathToPhoto = _pathToPhoto;
    }    

    function lockRP(uint256 _RPID) public onlyOwner {
        rps[_RPID-1].isWork = false;
    }
    
    function unlockRP(uint256 _RPID) public onlyOwner {
        rps[_RPID-1].isWork = true;
    }



    /**
     * Main admin functions for projects control
     */

    function editNameProject(uint256 _projectID, string memory _newName) public onlyOwner {
        projects[_projectID-1].name = _newName;
    }

    function editDescriptionProject(uint256 _projectID, string memory _newDescription) public onlyOwner {
        projects[_projectID-1].description = _newDescription;
    }
    
    
    function editAdminProject(uint256 _projectID, address _newAdmin) public onlyOwner {
        projects[_projectID-1].admin = _newAdmin;
    }
    
    function killProject(uint256 _projectID) public onlyOwner {
        projects[_projectID-1].RPID=0;
        projects[_projectID-1].name='';
        projects[_projectID-1].description='';
        projects[_projectID-1].admin=address(0);
        projects[_projectID-1].pathToPhoto='';
        projects[_projectID-1].site='';
        projects[_projectID-1].profit=0;
        projects[_projectID-1].isWork = false;
    }


    /**
     * RPadmin functions for projects control
     */


    function lockProject(uint256 _projectID) public isRPAdmin(msg.sender) {
        require (projects[_projectID-1].admin == msg.sender,"Is not your project");
        projects[_projectID-1].isWork = false;
    }
    
    function unlockProject(uint256 _projectID) public isRPAdmin(msg.sender) {
        require (projects[_projectID-1].admin == msg.sender,"Is not your project");
        projects[_projectID-1].isWork = true;
    }

    /**
     * RPadmin functions for deposit control
     */
    function addDeposit (address _investor, uint256 _projectID, uint256 _value, address _RPAdmin) public  onlyMainContract {
        require(projects[_projectID-1].admin == _RPAdmin, "Is not your project");
        users[_investor].projetcsDep[_projectID] += _value; 
    }    
     
    function revokeDeposit (address _investor, uint256 _projectID, uint256 _value, address _RPAdmin) public onlyMainContract {
        require (users[_investor].projetcsDep[_projectID] >= _value,"User deposit is smaller then you want revoke");
        require(projects[_projectID-1].admin == _RPAdmin, "Is not your project");
        users[_investor].projetcsDep[_projectID] -= _value; 
    }  


    /**
     * User functions
     * showDeposit - возвращает вкладчиков определенного проекта
     * showRPS - возвращает список поселений
     * showProjects - возвращает проекты определенного поселения
     * showUsers - отображает пользователей
     */ 



        function showUsers(uint256 _RPID) public view returns (bytes32[maxRecords] memory, bytes32[maxRecords] memory){
            //RPID = 0 - отображает всех пользователей
            //RPID > 0 - отображает пользователей определенного поселения
            uint32 x = 0;
            uint32 count = 0;
            bytes32[maxRecords] memory myRPSNameArray;
            bytes32[maxRecords] memory myUserNameArray;
            address myUserAddress;
            while (x < userArray.length) {
                myUserAddress = userAddress[userArray[x]];
                if (myUserAddress != address(0) && users[myUserAddress].isUser == true){
                    if (_RPID > 0) {
                        if (_RPID == users[myUserAddress].RPID){
                            myUserNameArray[count] = stringToBytes32(users[myUserAddress].name);
                            myRPSNameArray[count] = stringToBytes32(getRPName(users[myUserAddress].RPID));
                            count++;
                        }
                    } else {
                        myUserNameArray[count] = stringToBytes32(users[myUserAddress].name);
                        myRPSNameArray[count] = stringToBytes32(getRPName(users[myUserAddress].RPID));
                        count++;
                        
                    }
                }
                x++;
            }
            return (myUserNameArray, myRPSNameArray);
        }



        function showRPS() public view returns (bytes32[maxRecords] memory, uint256[maxRecords] memory){
            uint32 x = 0;
            uint32 count = 0;
            bytes32[maxRecords] memory myRPSNameArray;
            uint256[maxRecords] memory myRPSIDArray;
            while (x < rps.length) {
                if (rps[x].isWork == true) {
                    myRPSNameArray[count] = stringToBytes32(rps[x].name);
                    myRPSIDArray[count] = rps[x].ID;
                    count++;
                }
                x++;
            }
            return (myRPSNameArray, myRPSIDArray);
        }


        function showProjects(uint256 _RPID) public view returns (bytes32[maxRecords] memory, uint256[maxRecords] memory){
            uint32 x = 0;
            uint32 count = 0;
            bytes32[maxRecords] memory myProjectNameArray;
            uint256[maxRecords] memory myProjectIDArray;
            while (x < projects.length) {
                if (projects[x].RPID == _RPID && projects[x].isWork == true) {
                    myProjectNameArray[count] = stringToBytes32(projects[x].name);
                    myProjectIDArray[count] = projects[x].ID;
                    count++;
                }
                x++;
            }
            return (myProjectNameArray, myProjectIDArray);
        }

        function showDeposit(uint256 _projectID) public view returns (address[maxRecords] memory, uint256[maxRecords] memory, bytes32[maxRecords] memory, bytes32[maxRecords] memory){
        bytes32[maxRecords] memory myFIOArray;
        bytes32[maxRecords] memory myRPSNameArray;
        address[maxRecords] memory myAdresses;
        uint256[maxRecords] memory myDepo;
        string memory myCurrentLogin;
        address myCurrentAddress;
        uint256 myCurrentDeposit;
        uint32 x = 0;
        uint32 count = 0;
        
        while( x < userArray.length)
            {
                myCurrentLogin = userArray[x]; 
                myCurrentAddress = userAddress[myCurrentLogin];
                myCurrentDeposit = getUserDeposit(myCurrentAddress, _projectID); 
                if (myCurrentDeposit > 0) {
                    myAdresses[count] =myCurrentAddress;
                    myDepo[count] = myCurrentDeposit;
                    myFIOArray[count] = stringToBytes32(users[myCurrentAddress].name); 
                    myRPSNameArray[count] = stringToBytes32(getRPName(users[myCurrentAddress].RPID));
                    count++;
                }
                x++;
            }
        
        return (myAdresses, myDepo, myFIOArray, myRPSNameArray);
    }

/* function test(string memory source) public view returns (bytes32[maxRecords] memory) {
    bytes32[maxRecords] memory myArray;
    myArray[0] = stringToBytes32(source);
    return myArray;
} */


function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}



    function() external payable {
        // The token contract don`t receive ether
        revert();
    }  
}



contract MainContract is Ownable {
    using SafeMath for uint; 

    address myAddress = address(this);
    address myOwnerAddress = msg.sender;

    KEDRON public token = new KEDRON(myAddress, 'KERD Token', 'KEDR');
    ExternalStorage public exStorage = new ExternalStorage(myOwnerAddress);



    modifier isRPAdmin (address _addr) {
        require(exStorage.isRPAdminF(_addr) == true, "Access denied");
        _;
    }


    constructor() public {
        
    }



    function transferTokenOwnerShip(address _newOwnerContract)public onlyOwner {
        token.transferOwnership(_newOwnerContract);
    }

    function confirmTokenOwnerShip() public onlyOwner {
        token.confirmOwnership();
    }
    /**
     * RPadmin functions for deposit control
     */

    function transferTokens(address _addrInvestor, uint256 _projectID, uint256 _amount, string memory _comment) public isRPAdmin(msg.sender) {
        require (_addrInvestor != address(0));
        require (_amount >= 1);
        exStorage.addDeposit (_addrInvestor, _projectID, _amount, msg.sender) ;
        token.mint(_addrInvestor, _amount, _comment);
    }
    
    function revokeTokens(address _addrInvestor, uint256 _projectID, uint256 _amount, string memory _comment) public isRPAdmin(msg.sender) {
        // the function take tokens from _investor to contract
        // the sum is entered in whole tokens (1 = 1 token)
        require (_amount >= 1);
        exStorage.revokeDeposit (_addrInvestor, _projectID, _amount, msg.sender) ;
        token.burn(_addrInvestor, _amount, _comment);    
    }     
    
    function withdrawFunds (address payable _to, uint256 _value) public onlyOwner {
        require(_to != address(0),"Invalid address");
        require (myAddress.balance >= _value,"Value is more than balance");
        _to.transfer(_value);
    }


}