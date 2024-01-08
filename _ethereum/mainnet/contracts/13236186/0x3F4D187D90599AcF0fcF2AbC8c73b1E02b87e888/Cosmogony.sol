// SPDX-License-Identifier: None
pragma solidity >=0.8.4;

import "./ERC721.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./KeeperCompatibleInterface.sol";

/** 
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

 ___      ___   _______     ______    _______   ___       __   ___  ___________  __     __   ___   ______    
|"  \    /"  | /" _   "|   /    " \  /" _   "| |"  |     |/"| /  ")("     _   ")|" \   |/"| /  ") /    " \   
 \   \  //   |(: ( \___)  // ____  \(: ( \___) ||  |     (: |/   /  )__/  \\__/ ||  |  (: |/   / // ____  \  
 /\\  \/.    | \/ \      /  /    ) :)\/ \      |:  |     |    __/      \\_ /    |:  |  |    __/ /  /    ) :) 
|: \.        | //  \ ___(: (____/ // //  \ ___  \  |___  (// _  \      |.  |    |.  |  (// _  \(: (____/ //  
|.  \    /:  |(:   _(  _|\        / (:   _(  _|( \_|:  \ |: | \  \     \:  |    /\  |\ |: | \  \\        /   
|___|\__/|___| \_______)  \"_____/   \_______)  \_______)(__|  \__)     \__|   (__\_|_)(__|  \__)\"_____/ 

xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*/



contract Cosmogony is ERC721, KeeperCompatibleInterface, Ownable{
    using Strings for uint256;
    using SafeMath for uint256;

    string public baseURI;
    uint256 public URI_ID;
    uint256 public interval;
    uint256 public lastTimeStamp;
    uint256 public MAX_ID;


    event BaseURIChanged(string _baseURI);
    event TokenURIChanged(string _tokenURI);
    event IntervalTimeChanged(uint256 _interval);
    event MaxLimitChanged(uint256 _MAX_ID);

    constructor(string memory _baseURI, uint256 _interval, uint256 _MAX_ID) ERC721("COSMOGONY", "MGOGLKTKO") {
        baseURI = _baseURI;
        interval = _interval;
        MAX_ID = _MAX_ID;
        lastTimeStamp = block.timestamp;

        _safeMint(msg.sender, 1);
        emit BaseURIChanged(_baseURI);
        emit IntervalTimeChanged(_interval);
        emit TokenURIChanged(bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, "/1/", URI_ID.toString(), ".json")) : "");
        emit MaxLimitChanged(_MAX_ID);
    }

    function checkUpkeep(bytes calldata)
    external
    override
    returns(bool upkeepNeeded, bytes memory){
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata)
    external
    override{
        require((block.timestamp - lastTimeStamp) > interval, "Not yet.");
        lastTimeStamp = block.timestamp;
        URI_ID = (URI_ID.add(1)).mod(MAX_ID);
        emit TokenURIChanged(bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, "/1/", URI_ID.toString(), ".json")) : "");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, "/1/", URI_ID.toString(), ".json")) : "";
    }

    function changeBaseURI(string memory _baseURI)
    onlyOwner
    public{
        require(bytes(_baseURI).length > 0, "Empty BaseURI.");
        baseURI = _baseURI;
        emit BaseURIChanged(_baseURI);
    }

    function changeIntervalTime(uint256 _interval)
    onlyOwner
    public{
        require(_interval >= 1 days, "Invalid Interval.");
        interval = _interval;
        emit IntervalTimeChanged(_interval);
    }

    function changeMaxURIID(uint256 _MAX_ID)
    onlyOwner
    public{
        MAX_ID = _MAX_ID;
        emit MaxLimitChanged(_MAX_ID);
    }

    function setURI_ID(uint256 _URI_ID)
    onlyOwner
    public{
        require( _URI_ID <= MAX_ID, "invalid URI_ID");
        URI_ID = _URI_ID;
        emit TokenURIChanged(bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, "/1/", URI_ID.toString(), ".json")) : "");
    }
}