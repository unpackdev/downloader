pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";

import "Strings.sol";

import "Counters.sol";

import "0xmusic.sol";

contract OxmusicStaticSong is ERC721, Ownable {

    string private baseURLAnimation;
    Oxmusic private _oxmusic;
    mapping(uint32 => string) private djToNameIndex;
    mapping(uint256 => Trait) private tokenIdToTrait;
    mapping(uint256 => string) public tokenIdToAnimationUrl;
    Counters.Counter public _counter;
    bool public saleIsActive = false;
    mapping(uint => string) private bgIdToHex;
    mapping(uint256 => uint256) public tokenIdToStaticSongsMinted;
    mapping(string => uint256) public nameMapping;


    struct TokenDetails {
        string name;
        string master;
        string hexColor;
        string intro;
        string animationUrl;
        string args;
        string length;
    }

    struct Trait {
        string args;
        string name;
        uint256 parentTokenId;
    }

    constructor(string memory baseURLAnimationInput, address oxmusic)
 
    ERC721("Herbert", "karajan")
    {
        baseURLAnimation = baseURLAnimationInput;
        _oxmusic = Oxmusic(oxmusic);

        bgIdToHex[3] = "2B2727";
        bgIdToHex[6] = "192F20";
        bgIdToHex[27] = "2B192F";
    }


    function mint(uint256 tokenId, string memory staticArgs, string memory staticSongName) external payable {
        require(saleIsActive, "This feature is not yet available");
        require(_oxmusic.ownerOf(tokenId) == msg.sender, "you are not eligible for this feature");
        require(nameMapping[staticSongName] == 0, "song mame taken");

        (uint32 dj, uint id, uint len, uint staticSongsLimit) = _oxmusic.getImageDetails(tokenId);
        require(tokenIdToStaticSongsMinted[tokenId] < staticSongsLimit, "maximum static songs reached");

        uint mintIndex = Counters.current(_counter);
        
        Trait memory tmint = Trait(staticArgs, staticSongName, tokenId);

        tokenIdToTrait[mintIndex] = tmint;

        Counters.increment(_counter);
        tokenIdToStaticSongsMinted[tokenId] = tokenIdToStaticSongsMinted[tokenId] + 1;
        nameMapping[staticSongName] = 1;

        _safeMint(msg.sender, mintIndex);        
    }

    function setSaleIsActive(bool isActive) external onlyOwner {
        saleIsActive = isActive;
    }

    function songName(uint256 tokenId) public view returns (string memory) {
        return tokenIdToTrait[tokenId].name;
    }

    function args(uint256 tokenId) public view returns (string memory) {
        return tokenIdToTrait[tokenId].args;
    }

    function parentTokenId(uint256 tokenId) public view returns (uint256) {
        return tokenIdToTrait[tokenId].parentTokenId;
    }

    function updateAnimationUrl(uint256 tokenId, string memory url) public onlyOwner {
        tokenIdToAnimationUrl[tokenId] = url;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        
        Trait memory t = tokenIdToTrait[tokenId];

        (uint32 dj, uint id, uint len, uint bg) = _oxmusic.getImageDetails(t.parentTokenId);

        TokenDetails memory details = TokenDetails(        
            string(abi.encodePacked('{"trait_type": "Name", "value": "', t.name, '"}')),
            _oxmusic.getMasterFromTokenId(t.parentTokenId),
            bgIdToHex[bg],
            string(abi.encodePacked('{"name": "', t.name, '", "description": "Your eternalized slice of the 0xDJ playlist" , "image":  "', 
            _oxmusic.getImageURL(t.parentTokenId))),
            string(abi.encodePacked('"animation_url": "', baseURLAnimation, Strings.toString(dj), "&id=", Strings.toString(id),"&len=", 
            Strings.toString(len))),
            string(abi.encodePacked("&bg=", Strings.toString(bg), "&static=1&ss=", t.args)),
            string(abi.encodePacked('{"trait_type": "Cycle length", "value": "', len == 2 ? "short" : len == 3 ? "medium" : "long", '"},{"trait_type": "Name", "value": "', t.name, '"}'))
        );

        string memory animationUrlOverride = bytes(tokenIdToAnimationUrl[tokenId]).length == 0 ? string(abi.encodePacked(details.animationUrl,details.args))  : string(abi.encodePacked('"animation_url": "', tokenIdToAnimationUrl[tokenId]));
                    
        return string(abi.encodePacked('data:application/json,',details.intro,',', animationUrlOverride, '"', ',"external_url": "https://www.0xmusic.com", "background_color": "',details.hexColor,'" ,', 
                '"attributes": [{"trait_type": "Parent", "value": "', details.master, '"}, ', details.length,']}'));
        
    } 
}
