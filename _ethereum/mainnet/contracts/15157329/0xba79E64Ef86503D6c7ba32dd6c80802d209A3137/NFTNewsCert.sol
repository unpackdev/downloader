// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./base64.sol";
import "./console.sol";

contract NFTNewsCert is ERC721, Ownable{
    uint256 private currentTokenId = 0;
    bool sw = false;
    uint256 totalNumer = 100;
    uint256 limit = 1;
    uint256 mintPrice = 0.003 ether;

    enum Color {Black, Red, Blue, Green, Yellow, White, Pink}
    string[] colorArray;
    mapping(Color => string) colorString;

    mapping(uint256 => Color) tokenColor;
    mapping(uint256 => string) tokenSignature;
    mapping(address => uint256) numOfMinted;
    mapping(bytes32 => bool) mintedParameterHash;

    event Mint(address indexed minter, string indexed color,string signature);
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {

        colorString[Color.Black] = "black";
        colorString[Color.Red] = "red";
        colorString[Color.Blue] = "blue";
        colorString[Color.Green] = "green";
        colorString[Color.Yellow] = "yellow";
        colorString[Color.White] = "white";
        colorString[Color.Pink] = "pink";
        colorArray = ["black","red", "blue", "green", "yellow", "white", "pink"];
    }

    // internal functions
    function xPosition(uint256 _tokenId) private pure returns (uint256){
        return (_tokenId- 1) % 10 * 24 + 12 + 30 + 10;
    }
    function yPosition(uint256 _tokenId) private pure returns (uint256){
        return (_tokenId- 1) / 10 * 24 + 12 + 60 + 10;
    }
    function _getNextTokenId() private view returns (uint256) {
        return currentTokenId+1;
    }
    function _incrementTokenId() private {
        currentTokenId++;
    }
    function isTokenExist(uint256 _tokenId) private view returns (bool) {
        if(_tokenId < 1 || currentTokenId < _tokenId){return false;}
        return tokenColor[_tokenId] != Color.Black;
    }

    // external functions
    function getNumberOfAccountMinted(address _address) public view returns (uint256) {
        return numOfMinted[_address];
    }
    function getNumberOfMinted() public view returns (uint256) {
        return currentTokenId ;
    }
    function getMintStatus() public view returns (bool) {
        return sw;
    }
    function setMintStatus(bool _sw) onlyOwner public {
        sw = _sw;
    }
    function getLimit() public view returns (uint256) {
        return limit;
    }
    function setLimit(uint256 _limit) onlyOwner public {
        limit = _limit;
    }
    function getSignature(uint256 _tokenId) public view returns (string memory) {
        return tokenSignature[_tokenId];
    }
    function setSignature(uint256 _tokenId, string memory _signature) public {
        require(ownerOf(_tokenId) == msg.sender, "Only owner can set signature");
        tokenSignature[_tokenId] = _signature;
    }
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if(balance > 0){
            Address.sendValue(payable(owner()), balance);
        }
    }

    function isMintableCombination(string memory _color, string memory _signature) public view returns (bool) {
        bytes32 convination = keccak256(abi.encodePacked( _color, _signature));
        return mintedParameterHash[convination] == false;
    }
    function isInLimit() public view returns (bool) {
        return numOfMinted[msg.sender] < limit || msg.sender == owner();
    }

    function mintRed( string memory yourName) public payable {
        mintTo( Color.Red, yourName);
    }
    function mintBlue(string memory yourName) public payable {
        mintTo(Color.Blue, yourName);
    }
    function mintGreen(string memory yourName) public payable {
        mintTo(Color.Green, yourName);
    }
    function mintYellow(string memory yourName) public payable {
        mintTo(Color.Yellow, yourName);
    }
    function mintWhite(string memory yourName) public payable {
        mintTo(Color.White, yourName);
    }
    function mintPink(string memory yourName) public payable {
        mintTo(Color.Pink, yourName);
    }
    function mintTo(Color _color,string memory _name) private{
        address _to = msg.sender;
        bytes32 convination = keccak256(abi.encodePacked( colorString[_color], _name));
        require(sw || msg.sender == owner(), "Minting window is not open");
        require(currentTokenId < totalNumer, "Token amount is full)");
        require(numOfMinted[_to] < limit || msg.sender == owner(), "You reached mint limit");
        require(mintPrice <= msg.value, "Ether value is not correct");
        require(mintedParameterHash[convination] == false, "unacceptable");
        uint256 newTokenId = _getNextTokenId();
        _safeMint(_to, newTokenId);
        
        tokenSignature[newTokenId] = _name;
        tokenColor[newTokenId] = _color;
        numOfMinted[_to]++;
        mintedParameterHash[convination] = true;
        Address.sendValue(payable(msg.sender), mintPrice);
        emit Mint(_to, colorString[_color], _name);
        _incrementTokenId();
    }
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(isTokenExist(_tokenId), "tokenId must be exist");
        
        string[6] memory p;
        p[0] = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 320 320">',
            '<style>.base { fill: white; font-family: serif; font-size: 14px;}</style>',
            '<defs><filter id="f"><feGaussianBlur in="SourceGraphic" stdDeviation="3" /></filter>'
        ));

        for(uint256 i = 0; i< colorArray.length; i++){
            string memory color = colorArray[i];
            p[1] = string(abi.encodePacked(
                p[1],
                '<linearGradient id="', color, 'LG"><stop offset="0%" stop-color="',color,'"/><stop offset="100%"/>',
                '</linearGradient><circle id="',color, '" cx="0" cy="0" r="10" fill="url(#', color, 'LG)"/>'
            ));
        }

        p[2] = '</defs><rect width="100%" height="100%" fill="#222" rx="15" ry="15"/>';
        
        string memory xo = Strings.toString(xPosition(_tokenId));
        string memory yo = Strings.toString((yPosition(_tokenId)));
        p[3] = string(abi.encodePacked(
            '<circle id="F" cx="', xo, '" cy="', yo, '" r="21" fill="#ddd" filter="url(#f)"/>',
            '<circle id="F" cx="', xo, '" cy="', yo, '" r="14" fill="#aaa" filter="url(#f)"/>'
        ));

        for(uint256 i = 1; i <= 100; i++){
            if(tokenColor[i] == Color.Black){continue;}
            string memory ref = colorString[tokenColor[i]];
            string memory x = Strings.toString(xPosition(i));
            string memory y = Strings.toString(yPosition(i));
            p[4] = string(abi.encodePacked(p[4],'<use href="#',ref,'" x="',x,'" y="', y,'"/>'));
        }

        p[5] = string(abi.encodePacked(
            '<text x="30" y="25" class="base">NFT News Certification #76</text>',
            '<text x="30" y="45" class="base">ID: ',
            Strings.toString(_tokenId),
            '</text><text x="30" y="65" class="base"> Minter: ',
            tokenSignature[_tokenId],
            '</text></svg>'
        ));
        string memory svg = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5]));
        
        string memory meta = string(abi.encodePacked(
            '{"name": "NFTNewsCertification #',
            Strings.toString(_tokenId),
            '","description": "NFT News Reading Certification.",',
            '"attributes": [{"trait_type":"Color","value":"',
            colorString[tokenColor[_tokenId]],
            '"}],',
            '"image": "data:image/svg+xml;base64,'
        ));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(meta, Base64.encode(bytes(svg)), '"}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
}