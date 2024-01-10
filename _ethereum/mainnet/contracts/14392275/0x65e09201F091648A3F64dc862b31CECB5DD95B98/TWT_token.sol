pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


//import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";

import "./recovery.sol";
import "./IRNG.sol";

import "./console.sol";




contract theWorldToday is 
    ERC721, 
    Ownable, 
    IERC2981,
    recovery
{
    using Strings  for uint256;

    IRNG                        immutable   public  _iRnd;
    mapping (address => bool)               public  permitted;

    string                                          _tokenPreRevealURI;
    uint256                             constant    _maxSupply = 13800;
    uint256                                         _rand;

    bytes32                                         _reqID;
    bool                                            _randomReceived;
    uint256                                         _revealPointer;
    mapping(uint=>string)                           _tokenRevealedBaseURI;  
    uint                                            current;

    address payable                                 _twtAddress;
    uint256                                         _royalty = 10;

    mapping (uint256 => uint256)             public allTokens;

    mapping (uint256 => string)                     uris;


    event Allowed(address,bool);
    event RandomProcessed(uint256 randomNumber);

    modifier onlyAllowed() {
        //console.log("only allowed",msg.sender);
        require(permitted[msg.sender] || (msg.sender == owner()),"Unauthorised");
        _;
    }


    constructor(
        IRNG _rng, 
        string memory _name, 
        string memory _symbol,
        string memory __tokenPreRevealURI,
        address payable _wallet
         
    ) ERC721(_name,_symbol) recovery(_wallet) {
        _tokenPreRevealURI = __tokenPreRevealURI;
        _iRnd = _rng;
        _twtAddress = _wallet;
    }

    receive() external payable {

    }

    function setAllowed(address _addr, bool _state) external  onlyAllowed {
        permitted[_addr] = _state;
        emit Allowed(_addr,_state);
    }


    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token does not exist");
        uint256 _royaltyAmount = (salePrice * _royalty) / 100;
        return (_twtAddress, _royaltyAmount);
    }


    function mintCards(uint256 numberOfCards, address recipient) external  onlyAllowed {
        //console.log("mint cards");
        _mintCards(numberOfCards,recipient);
    }

    function yesterday(uint256 serial) public pure returns (uint256) {
        return ((serial + (serial%10)*100) % _maxSupply) + 1;
    }

    function _mintCards(uint256 numberOfCards, address recipient) internal {
        require(!_randomReceived,"no minting after RNG invoked");
        uint256 supply = current;
        require(supply+numberOfCards <= _maxSupply,"This would exceed the number of cards available");
        for (uint j = 0; j < numberOfCards; j++) {
            uint256 tokenId = yesterday(supply+j+1);
            _mint(recipient,tokenId);
            allTokens[supply+j+1] = tokenId;
        }
        current += numberOfCards;
    }

    // RANDOMISATION --cut-here-8x------------------------------

    function setRevealedBaseURI(string calldata revealedBaseURI) external onlyAllowed {
        _tokenRevealedBaseURI[_revealPointer += 1] = revealedBaseURI;
        if (!_randomReceived) _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd),"Unauthorised RNG");
        require (_reqID == reqID,"Incorrect request ID sent"); 
        require(!_randomReceived, "Random N already received");
        _rand = (random % 300) * 100;
        _randomReceived = true;
        emit RandomProcessed(_rand);       
    }

    function setPreRevealURI(string memory _pre) external onlyAllowed {
        _tokenPreRevealURI = _pre;
    }

    function setFolderURI(uint256 folderID, string calldata _fURI) external onlyAllowed {
        uris[folderID] = _fURI;
    }

 
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        if (!_randomReceived) return _tokenPreRevealURI;
        
        string memory revealedBaseURI = _tokenRevealedBaseURI[_revealPointer];

        uint256 folderNo = ((((tokenId / 100) + _rand) % 100) + 1);
        string memory folder     = folderNo.toString();
        string memory file     = (tokenId % 100) .toString();
        //
        if (bytes(uris[folderNo]).length != 0) {
            return string(abi.encodePacked(uris[folderNo],file)) ;
        }

        return string(abi.encodePacked(revealedBaseURI,folder,"/",file)) ;
        //
    }

    function oldTokenURI(uint256 tokenId, uint256 version) public view returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        require(version > 0 ,"Versions start at 1");
        require(version <= _revealPointer,"Version does not exist");
        if (!_randomReceived) return _tokenPreRevealURI;
        
        string memory revealedBaseURI = _tokenRevealedBaseURI[version];
        uint256 folderNo = ((((tokenId / 100) + _rand) % 100) + 1);
        string memory folder     = folderNo.toString();
        string memory file     = (tokenId % 100).toString();
        //
        if (bytes(uris[folderNo]).length != 0) {
            return string(abi.encodePacked(uris[folderNo],file)) ;
        }
        return string(abi.encodePacked(revealedBaseURI,folder,"/",file)) ;

    }


    // Add lock until sellout or unlocked
    function tokenPreRevealURI() external view  returns (string memory) {
        return _tokenPreRevealURI;
    }

    function totalSupply() external view returns (uint256) {
        return current;
    }



}
