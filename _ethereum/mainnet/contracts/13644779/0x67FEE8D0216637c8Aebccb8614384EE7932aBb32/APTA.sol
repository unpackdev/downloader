

pragma solidity ^0.6.0;

import "./ChainlinkClient.sol";
import "./ERC721.sol";
import "./Ownable.sol";

/*                                               

 ⣿⣿⣿⣿⣿⣿⣿   ⣿⣿⣿⣿⣿⣿   ⣿⣿⣿⣿⣿⣿⣿   ⣿⣿⣿⣿⣿⣿⣿
⣿⣿      ⣿⣿   ⣿⣿    ⣿⣿    ⣿⣿     ⣿⣿       ⣿⣿
 ⣿⣿⣿⣿⣿⣿⣿   ⣿⣿⣿⣿⣿⣿      ⣿⣿      ⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿      ⣿⣿  ⣿⣿            ⣿⣿     ⣿⣿       ⣿⣿

Welcome to A Portal To Adelaide...
Love from Mr Untitled
                                                    */

contract APTA is ERC721, ChainlinkClient, Ownable {
    
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    uint256 public conditionid = 0;
    string private API;
    uint256 public lastUpdateTime;
    
    
    uint8 public Mode;
    bool private AutoScrambled;
    bool public Powered;
    bool public isAuto = true;
    
    
    address constant LINK_address = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address payable RefundAddress = 0x4a9FbC166742B472839bcC93772aec0830d36a5c;
    
    LinkTokenInterface public link;
    
    /* variables for Owner Alias Utility */
    string private NFTownerAlias;
    address NFTownerAddress;
    
    /* Weather Metadata Structure */
    struct WeatherMetadata {
        string ArweaveHash_Image;
        string Weather;
    }
    
    
    /* CurrentMetadata */
    WeatherMetadata public CurrentMetadata;
    
    /* Mappings of WeatherMetadata */
    mapping(uint256 => WeatherMetadata) private WeatherMetadataMappings;
    
    /* Mapping WeatherGroups */
    mapping(uint256 => uint256) private WeatherGroups;
    
    event Received(address indexed sender, uint256 amount);
    
    constructor(string memory _name, string memory _symbol) public ERC721(_name, _symbol) {
        setPublicChainlinkToken();
        fee = 0.1 * 10 ** 18;
        link = LinkTokenInterface(LINK_address);
        
        /* Grouping all valid weather ids */
        WeatherGroups[200] = 200;
        WeatherGroups[201] = 200;
        WeatherGroups[202] = 200;
        WeatherGroups[210] = 200;
        WeatherGroups[211] = 200;
        WeatherGroups[212] = 200;
        WeatherGroups[221] = 200;
        WeatherGroups[230] = 200;
        WeatherGroups[231] = 200;
        WeatherGroups[232] = 200;
        
        WeatherGroups[300] = 300;
        WeatherGroups[301] = 300;
        WeatherGroups[302] = 300;
        WeatherGroups[310] = 300;
        WeatherGroups[311] = 300;
        WeatherGroups[312] = 300;
        WeatherGroups[313] = 300;
        WeatherGroups[314] = 300;
        WeatherGroups[332] = 300;
        
        WeatherGroups[500] = 500;
        WeatherGroups[501] = 500;
        WeatherGroups[502] = 500;
        WeatherGroups[503] = 500;
        WeatherGroups[504] = 500;
        WeatherGroups[511] = 500;
        WeatherGroups[520] = 500;
        WeatherGroups[521] = 500;
        WeatherGroups[522] = 500;
        WeatherGroups[531] = 500;
        
        WeatherGroups[701] = 701;
        WeatherGroups[711] = 721;
        WeatherGroups[721] = 721;
        WeatherGroups[731] = 721;
        WeatherGroups[741] = 701;
        WeatherGroups[751] = 721;
        WeatherGroups[761] = 721;
        WeatherGroups[762] = 721;
        
        WeatherGroups[800] = 800;
        WeatherGroups[801] = 801;
        WeatherGroups[802] = 802;
        WeatherGroups[803] = 803;
        WeatherGroups[804] = 804;
        
        /* Weather Metadata for each Mapping */
        WeatherMetadataMappings[200].ArweaveHash_Image = "OD9VFtL_28-3ZH4luLciZU-qMrHRiXoLwbBEFZT3tko";
        WeatherMetadataMappings[200].Weather = "Thunderstorm";
        
        WeatherMetadataMappings[300].ArweaveHash_Image = "p9XfoGasHSEjQBE1dgzRuq64Tuxwxn6JcRWulK5ysd0";
        WeatherMetadataMappings[300].Weather = "Drizzle";
        
        WeatherMetadataMappings[500].ArweaveHash_Image = "ElfvWv0zwz7KUc6JxHxpuSPFBo5CKtiznFrbTSpHFV8";
        WeatherMetadataMappings[500].Weather = "Rain";
        
        WeatherMetadataMappings[701].ArweaveHash_Image = "Jl_NqQZiiDj6LjP3oW4Likj7Ah2HDYQsabWRDtbYJPU";
        WeatherMetadataMappings[701].Weather = "Misty";
        
        WeatherMetadataMappings[721].ArweaveHash_Image = "g7Gl1Qlc_VkOevt-sJbPhYHKLG0ThfVSN9Pmaq0KKNI";
        WeatherMetadataMappings[721].Weather = "Hazey";
        
        WeatherMetadataMappings[800].ArweaveHash_Image = "kN2ddkWAr5-tjGTUkS4RVD-WdJ7oSLMSoxaU1uP0GJM";
        WeatherMetadataMappings[800].Weather = "Clear";
        
        WeatherMetadataMappings[801].ArweaveHash_Image = "CTJePAmrBcBuD_eaW772NHSYs0UWMuJ-FmOgqIILzSo";
        WeatherMetadataMappings[801].Weather = "Few Clouds";
        
        WeatherMetadataMappings[802].ArweaveHash_Image = "Rp432hxnNFWW_Ix4vieUfTVFNy8zJcvJC3f_RTONnx4";
        WeatherMetadataMappings[802].Weather = "Scattered Clouds";
        
        WeatherMetadataMappings[803].ArweaveHash_Image = "_F1gMc_jzte9gZTCxTL3xHjLcFe2WjFyjVRTUXYuB7k";
        WeatherMetadataMappings[803].Weather = "Broken Clouds";
        
        WeatherMetadataMappings[804].ArweaveHash_Image = "6V-hJZ54gPQowKEeDyfSRkwhDbY_C6vwLeN6eSOzdlQ";
        WeatherMetadataMappings[804].Weather = "Overcast";
        
         _mint(msg.sender, 1);
    }
    
    receive() external payable {
    emit Received(msg.sender, msg.value);
  }

    /*                */
    /*   Modifiers    */
    /*                */  
    
    /* Gas Refund Modifier */  
    modifier refundGasCost()
    {
        uint remainingGasStart = gasleft();
        _;
        uint remainingGasEnd = gasleft();
        uint usedGas = remainingGasStart - remainingGasEnd;
        // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
        usedGas += 21000 + 9700;
        // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
        uint gasCost = usedGas * tx.gasprice;
        // Refund gas cost
        (bool success, ) = RefundAddress.call{value:gasCost}("");
        require(success);
    }
    
    /* NFT Owner Modifier */
    modifier NFTOwner () {
      require(balanceOf(msg.sender) >= 1);
      _;
    }
    
    /* Caller Address Modifier */
    modifier CallerAddress () {
      require(msg.sender == RefundAddress);
      _;
    }
    
    /*                    */
    /* Metadata Functions */
    /*                    */
    
    /* GeneralUpdater Function that gets called automatically, updates metadata and refunds gas to caller from contract */
    function GeneralUpdater() public CallerAddress refundGasCost {
    
        require(block.timestamp > lastUpdateTime + 24 hours, "Once update a day");
        //greater than 100gwei for safetymeasure
        require(address(this).balance > 100000000000, "Make sure this contract has atleast 100 gwei");
        require(isAuto = true, "Auto Mode is not on");
    
        //if not enough link or eth, set mode to Frozen. less than fee and less than 100 gwei
        
        //if specifically AutoScrambled mode then only do that
        if (AutoScrambled == true && address(this).balance > 100000000000) {
            
            randomisedWeatherConditionID();
        } else {
            
            if (link.balanceOf(address(this)) < fee && address(this).balance < 100000000000) {
                Mode = 3; //Out of Order mode
                Powered = false;
                isAuto = false;
            } else if (link.balanceOf(address(this)) < fee && address(this).balance > 100000000000) {
                Mode = 2; //Scrambled Mode
                Powered = true;
                randomisedWeatherConditionID();
            } else {
                Mode = 1; //Locked on Mode
                Powered = true;
                requestWeatherConditionID();
            }
        }
        
        lastUpdateTime = block.timestamp;
            
        } 
        
    /* Request weather Conditions -- Locked On Mode */
    function requestWeatherConditionID() private {
        require(getLinkBalance() >= fee, "Error, not enough LINK - fill contract with faucet");
        
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillWeatherConditionID.selector);
        req.add("get", API);
        req.add("path", "weather.0.id");
        sendChainlinkRequestTo(oracle, req, fee);
    }
    
    /* Callback function from Chainlink */
    function fulfillWeatherConditionID(bytes32 _requestId, uint256 _result) public recordChainlinkFulfillment(_requestId) {
        uint256 previousConditionid = conditionid;
        
        if (previousConditionid != _result) {
            conditionid = _result;
            
            UpdateMetadata(_result);
        }
    }
    
    /* Selects random weather to update metadata with -- Scrambled Mode */
    function randomisedWeatherConditionID() private returns (uint8 randomNumber, uint16 _WeatherConditionID) {
        uint256 previousConditionid = conditionid;
        uint16[10] memory _ConditionArray = [200,300,500,701,721,800,801,802,803,804];
            
        randomNumber = uint8(uint256(keccak256(abi.encodePacked(isAuto, block.timestamp, Powered, block.difficulty, Mode, block.number)))%10);
        
        _WeatherConditionID = _ConditionArray[randomNumber];
        
        if (previousConditionid != _WeatherConditionID) {
            conditionid = _WeatherConditionID;
            //add in other updates that need to be done i.e. metadata changes
            UpdateMetadata(_WeatherConditionID);
            }
    }
    
    /* Updates the metadata to specific weather */
    function UpdateMetadata(uint256 _result) private {
        CurrentMetadata = WeatherMetadataMappings[WeatherGroups[_result]];
    }
    
    /*                  */
    /* Public Functions */
    /*                  */
    
    /* Retrieves Current Metadata */
    function getCurrentMetadata() public view returns (
        string memory _Weather,
        string memory _ArweaveHash_Image,
        uint8  _Mode,
        bool  _Powered,
        bool  _isAuto,
        string memory _NFTownerAlias,
        address _NFTownerAddress,
        uint256 _lastUpdateTime) 
        {
        _Weather = CurrentMetadata.Weather;
        _ArweaveHash_Image = CurrentMetadata.ArweaveHash_Image;
        _Mode = Mode;
        _Powered = Powered;
        _isAuto = isAuto;
        _NFTownerAlias = NFTownerAlias;
        _NFTownerAddress = NFTownerAddress;
        _lastUpdateTime = lastUpdateTime;
    }
    
    /* Get Contract Link Balance */
    function getLinkBalance() public view returns(uint) {
        uint balance = link.balanceOf(address(this));
        return balance;
        
    }
    
    /*                              */
    /* NFT Owner Specific Functions */
    /*                              */
    
    /* Manually updates metadata depending on mode chosen */
    function ManualUpdate (uint8 _Mode) public NFTOwner {
    require(_Mode == 1 || _Mode == 2, "Can't update a broken portal");
    
    if (_Mode == 1) {
        requestWeatherConditionID();
    } else {
        randomisedWeatherConditionID();
    }
    
    lastUpdateTime = block.timestamp;
        
    }
    
    /* Sets to specific mode of operation */
    function setModeIsAuto (uint8 _Mode, bool _isAuto) public NFTOwner {
    Mode = _Mode;
    isAuto = _isAuto;
    
    if (_Mode == 2 && _isAuto == true) {
        AutoScrambled = true;
    } else {
        AutoScrambled = false;
    }
        
    }
    
    /* Sets new Alias for NFT Owner */
    function setNFTOwnerAlias(string memory _alias) public NFTOwner {
        NFTownerAlias = _alias;
        NFTownerAddress = msg.sender;
    }
    
    /*                          */
    /* Contract Owner Functions */
    /*                          */

    /* Update BaseURI */
    function setTokenURI(string memory tokenURI) public onlyOwner {
        _setTokenURI(1, tokenURI);
    }
    
    /* Update Oracle, if current node longer available */
    function updateOracleJob(address _oracle, string memory _jobID, uint256 _fee) public onlyOwner {
        oracle = _oracle;
        jobId = stringToBytes32(_jobID);
        fee = _fee;
    }
    
    /* Update API, if compromised */
    function updateAPIRequestChange(string memory _api) public onlyOwner {
        API = _api;
    }
    
    /* Helper function for string to bytes32 */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
}