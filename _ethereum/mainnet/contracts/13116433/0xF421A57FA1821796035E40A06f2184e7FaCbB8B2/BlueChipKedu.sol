import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";

pragma solidity ^0.8.6;

contract BlueChipKedu is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    string private baseURI;
    
    // Mapping of tokenID to URI
    mapping(uint256 => string) public baseURIForID;
    mapping(uint256 => bool) public isRevealed;

    constructor () ERC721("Blue Chip Kedu", "BCK"){
        baseURI = "https://gateway.pinata.cloud/ipfs/QmYkgQMkRCJAAsFBjS9TPEEDAYUutqxLteboETP7AQc8Se/";
        transferOwnership(address(0x5c8FC210f2ccEC69e0a78A0Ce675fcDd39BF6ba8));
    }

    // Owner can mint up to 30 Custom Kedu
    function mint(address _to, uint256 _numMints) public onlyOwner {
        require(_tokenIds.current() + _numMints <= 30,  "Minting Maxed Out");
        require(_numMints > 0, "Cant give away nothing");
        for(uint256 i; i < _numMints; i++) {
            uint256 newItemId = _tokenIds.current();
            _safeMint(_to, newItemId);
            _tokenIds.increment();
        }
    }

    // Settors, onlyOwner access
    function setBaseURI(uint256 _tokenID, string memory _uri) public onlyOwner {
        baseURIForID[_tokenID] = _uri;
        isRevealed[_tokenID] = true;
    }

    // Gettors, view functions

    function _baseURI(uint256 _tokenID) internal view returns (string memory) {
        return baseURIForID[_tokenID];
    }

    function tokenURI(uint256 _tokenID) public view virtual override returns (string memory) {
        string memory URIRevealed = baseURIForID[_tokenID];
        require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");
        if(isRevealed[_tokenID]) {
            return URIRevealed;
        } else {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenID.toString(), ".json")) : "";
        }
    }

    // Returns array of tokenID's that input address _owner owns
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Utility Functions, onlyOwner access
    
    function withdrawEth() public onlyOwner {
        uint256 total = address(this).balance;
        require(payable(owner()).send(total));
    }

    // Rescue any ERC-20 tokens that are sent to contract mistakenly
    function withdrawToken(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transferFrom(address(this), owner(), _amount);
    }
}