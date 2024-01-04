pragma solidity 0.8.0;
contract owned {
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }
}
contract NotariaTimeStamped is owned{
   
    struct Document {
        string name;
        uint256 timestamp;
    }
    
    mapping(string => Document) public db;
    
    function newHash(string memory hash, string memory name) public {
         db[hash] = Document(name,block.timestamp);
    }
   
    function getData(string memory hash) public view returns (Document memory) {
        return db[hash];
    }
    
}