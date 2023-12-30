pragma solidity 0.4.26;

contract CommonwealthNamingService {
    address public eWLTHDivies;
    
    uint recordsCreated;
    
    uint recordCreationPrice = (0.001 ether); // 0.001 ETH to register a name.
    
    mapping(address => bool) activatedCNS;
    mapping(address => string) addressNameMap;
    mapping(string => address) nameAddressMap;
    
    event NameRegistered(address _owner, string _name, uint _registrationFeePaid);
    event NameReassigned(address _owner, address _recipient);
    
    // Check availability
    function isAvailable(string memory name) public view returns (bool) {
        if (checkCharacters(bytes(name))) {return (nameAddressMap[name] == address(0));}
        return false;
    }
    
    constructor(address _divies) public {
        eWLTHDivies = _divies;
    }
    
    // Main Functions
    function buyRecord(string memory _name) public payable returns (bool, uint) {
        require(msg.value == recordCreationPrice);
        createRecord(_name, msg.sender);
        eWLTHDivies.transfer(msg.value);
        recordsCreated += 1;
        emit NameRegistered(msg.sender, _name, recordCreationPrice);
    }
    
    // User Functions
    function getRecordOwner(string memory name) public view returns (address) {
        return nameAddressMap[name];
    }
    
    function getRecordName(address addr) public view returns (string memory name) {
        return addressNameMap[addr];
    }
    
    // Record Functions
    function getRecordCount() public view returns (uint) {return recordsCreated;}
    
    // Internal Functions
    function createRecord(string memory name, address _owner) internal returns (bool) {
        require(bytes(name).length <= 32, "name must be fewer than 32 bytes");
        require(bytes(name).length >= 3, "name must be more than 3 bytes");
        require(checkCharacters(bytes(name)));
        require(nameAddressMap[name] == address(0), "name in use");
        string memory oldName = addressNameMap[_owner];
        if (bytes(oldName).length > 0) {nameAddressMap[oldName] = address(0);}
        addressNameMap[_owner] = name;
        nameAddressMap[name] = _owner;
        activatedCNS[_owner] = true;
        return true;
    }
    
    // Validation - Check for only letters and numbers, allow 9-0, A-Z, a-z only
    function checkCharacters(bytes memory name) internal pure returns (bool) {
        for(uint i; i<name.length; i++){
            bytes1 char = name[i];
            if(!(char >= 0x30 && char <= 0x39) && !(char >= 0x41 && char <= 0x5A) && !(char >= 0x61 && char <= 0x7A))
            return false;
        }
        return true;
    }
}