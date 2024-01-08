pragma solidity 0.5.17;

import "./token.sol";
//Use provable.sol for testnet/Mainnet
import "./provable.sol";
import "./Initializable.sol";


interface IPool{
     function getpoollength() external returns(uint);
     function addNewList(address[] calldata _tokens, uint[] calldata _weights, uint _threshold,uint _rebalanceTime) external returns(bool);
     function updatePoolTokens(address[] calldata _tokens, uint[] calldata _weights, uint _poolIndex) external returns(bool); 
}

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }
    
        /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
    
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }
    
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
    
        /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    
    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }
}

contract DAAORacle is usingProvable, Initializable {
    using SafeMath for uint;
    using strings for *;
    address public whitelistmanager;
    address public _owner;
    address[] public tokenList;
    uint[] public weights;
    mapping(address => bool) public whitelistedaddress;

    mapping(uint256 => string) public PoolDatasource;
    
    struct PoolInfo {
        // Token in indices
        address[] tokens;  
        // weight of tokens  
        uint[]  weights;
        // Threshold amount
        uint threshold;
        // Next rebalance time
		uint rebalanceTime;
        // itoken Name
        string name;
        // itoken Symbol
		string symbol;
        // Description of pool
        string description;
    }
     
    PoolInfo[]  poolInfo;
    /**
     * @dev Modifier to check if the caller is whitelisted or not.
     */
    modifier whitelistedonly{
        require(whitelistedaddress[msg.sender] == true, "Only whitelistedaddress");
        _;
    }
    /**
     * @dev Modifier to check if the caller is owner or not.
     */
    modifier onlyOwner{
        require(msg.sender == _owner, "Only Owner");
        _;
    }
    	/**
     * @dev Modifier to check if the caller is manager or not
     */
    modifier whitelistmanagerOnly{
        require(msg.sender == whitelistmanager, "Only whitelistmanage");
        _;
    }
    function initialize() public initializer{
      _owner = msg.sender;
      whitelistmanager = msg.sender; 
	}
    // Save details of latest response from provable.
    string public tokens;
    event LogTokensUpdated(string tokens);
    event LogNewProvableQuery(string description);

    /**
     * @dev Called by the Provable contracts to return the data of the request. Only provble contract can call this function.
     */
   function __callback(bytes32 myid, string memory result) public{
       if (msg.sender != provable_cbAddress()) revert();
       tokens = result;
       updateValue(result);
       emit LogTokensUpdated(result);
   }

    /**
     * @dev Internal function to decrypt the data from response.
     * Here we send all the details in string seperate by ',' in this order.
     * First is token lenght -1 to calculate internally.
     * Tokens addreses seperated by ,
     * Weight of token
     * Threshold amount
     * Rebalance Time
     */

   function updateValue(string memory _callbackData)internal{
       // Using the string library from above
        strings.slice memory s;
        s = _callbackData.toSlice();
        uint[] memory buf1;
        address[] memory buf2;
        tokenList = buf2;
        weights = buf1;
        uint tokenLength;
        uint loopLenght;
        uint TotalTokens;
        uint _poolIndex;
        uint Threshold;
        uint RebalanceTime;
        // Get the length of token by splittin from first ','. parseInt is provide by provable initially.
        tokenLength = parseInt(s.split(",".toSlice()).toString());
        // Get the actuall in previous it tell based on index.
        TotalTokens = tokenLength.add(1);
        //Count how many time we need to call the loop to get the each value.
        loopLenght = tokenLength.mul(2).add(5);

        // Run the loop to get each field and parse them into required format.
        for(uint i=1;i<=loopLenght;i++){
            if(i<=TotalTokens ){
                address tmp = parseAddr(s.split(",".toSlice()).toString());
                tokenList.push(tmp);
            }else if(i<=2*TotalTokens ){
                uint inttmp = parseInt(s.split(",".toSlice()).toString());
                weights.push(inttmp);
                
            }else if(i==(loopLenght.sub(2))){
                _poolIndex = parseInt(s.split(",".toSlice()).toString());
            }
            else if(i==(loopLenght.sub(1))){
                Threshold = parseInt(s.split(",".toSlice()).toString());
            }
            else if(i==loopLenght){
                RebalanceTime = parseInt(s.split(",".toSlice()).toString());
            }

        }

        // check if returned confirguation is correct or not.
        require(tokenList.length >0,"updateValue: Not enough tokens from AI");
        require(tokenList.length == weights.length, "Invalid configurations");

        // Update the details in mappping after all details are fetched successfully.
        poolInfo[_poolIndex].tokens = tokenList;
        poolInfo[_poolIndex].weights = weights;
        poolInfo[_poolIndex].threshold = Threshold;
        poolInfo[_poolIndex].rebalanceTime = RebalanceTime;
    }

    /**
     * @dev Function to get the latest result from AI. This can be called by anyone. Caller must send enough gas fees so that provable can send response.
     */
   function updateTokens(uint256 _poolIndex)public payable {
       uint256 customFees =8000000;
       // Check if the contract has enough balance to make the response call
       if (provable_getPrice("URL") > address(this).balance) {
           emit LogNewProvableQuery("Error in sending query for Pool");
       } else {
           emit LogNewProvableQuery("Query sent successfully");
           // Query sent to provable. Here we need to send custom gas fees as initially very low gas is used by provable.
           provable_query("URL", PoolDatasource[_poolIndex],customFees);
        //    provable_query("URL", "json(https://run.mocky.io/v3/ef245352-c6ff-4fc6-a972-027906238417).tokens",customFees);
       }
   }

    /**
     * @dev Update the manager address who can control configuration. Manager has permission to whitelist addresses and only owner can update the addresses.
     */
	function updateManager(address _addr) public onlyOwner{
        require(_addr != address(0), "Zero Address"); 
	    require(_addr != whitelistmanager, "Already whitelist manager");
	    whitelistmanager = _addr;
	}

    /**
     * @dev Whitelist address who can control the configuration of pool. Whitelisted address has access to manage the pool details.
     */
	
	function whitelistaddress(address _addr) public whitelistmanagerOnly{
        require(_addr != address(0), "Zero Address");
          require(whitelistedaddress[_addr] == false, "ALready Whitelisted");
          whitelistedaddress[_addr] = true;
	}

   /**
     * @dev Remove user from whitelist.
     */
	function removewhitelist(address _addr) public whitelistmanagerOnly{
        require(_addr != address(0), "Zero Address");
	    require(whitelistedaddress[_addr] == true, "Not Whitelisted");
	    whitelistedaddress[_addr] = false;
	}

    /**
     * @dev Add new pool details. Initially first pool have to be entered manually with datasource.
     */

    function AddNewPoolTokens(address[] memory _tokens, uint[] memory _weights,uint _threshold,uint _rebalanceTime,string memory _name, string memory _symbol,string memory _datasource, string memory _description) public whitelistedonly returns(bool){
        require(_tokens.length == _weights.length, "Invalid configurations");	   
        poolInfo.push(PoolInfo({
            tokens: _tokens,
            weights: _weights,
            threshold:_threshold,
            rebalanceTime:_rebalanceTime,
            name: _name,
		    symbol: _symbol,
            description: _description
        }));

        // Get the added pool index to store datasource details
        uint256 _poolIndex = poolInfo.length.sub(1);
        PoolDatasource[_poolIndex] = _datasource;
	}

     /**
     * @dev Update the AI source of the pool. In case the  wrong datasource is updated then the manager has options to update index datasource.
     */

    function UpdatePoolDatasource(uint256 _poolIndex,string calldata _datasource)external whitelistedonly{
        require(_poolIndex<poolInfo.length, "UpdatePoolDatasource: Invalid Pool Index");
        PoolDatasource[_poolIndex] = _datasource;
    }

    /**
     * @dev Update the configuration mannually. In case details not came from the AI manager can manually update the pool.
     */
    function UpdatePoolConfiguration(address[] memory _tokens, uint[] memory _weights, uint _poolIndex,uint _threshold,uint _rebalanceTime) public whitelistedonly returns(bool){
	    require(_tokens.length == _weights.length, "Invalid configurations");
        poolInfo[_poolIndex].tokens = _tokens;
        poolInfo[_poolIndex].weights = _weights;
        poolInfo[_poolIndex].threshold = _threshold;
        poolInfo[_poolIndex].rebalanceTime = _rebalanceTime;
	}
    /**
     * @dev Get the Token details it used by DAA poolv1 at the time of creating/updating pool.
     */
    function getTokenDetails(uint _poolIndex) public view returns(address[] memory ,uint[] memory,uint,uint){
        return (poolInfo[_poolIndex].tokens,poolInfo[_poolIndex].weights,poolInfo[_poolIndex].threshold,poolInfo[_poolIndex].rebalanceTime);
    }
    /**
     * @dev Get the iToken details it used by DAA poolv1 at the time of creatingpool.
     */
    function getiTokenDetails(uint _poolIndex) public view returns(string memory, string memory,string memory){
        return (poolInfo[_poolIndex].name,poolInfo[_poolIndex].symbol,poolInfo[_poolIndex].description);
    }

}