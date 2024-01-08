//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./console.sol";
import "./base64.sol";

contract RapNameNFT is ERC721Enumerable, ERC721URIStorage, Ownable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;
    uint256 public constant MAX_SUPPLY = 256 ;
    uint256 public constant MAX_PURCHASE = 10;
    uint256 public constant PRICE = 0.02 * 10 ** 18;

    Counters.Counter private _tokenIdCounter;

    // private mapping from tokenId to rapName
    mapping (uint256 => string) private rapNames;

    bool public frozen = false;

    // mapping from ownerId to tokenId is done in _safeMint
    address internal yungmoneyAddr = 0x236BC95dd51B2C658701bf195699C8f30142CD42;
    address internal scriptkiddyAddr = 0x984C74D1eb9942736cA899fC33a3476bDa9BDBce;

    constructor() ERC721("RapNameNFT", "RNFT") {
        _tokenIdCounter.increment();
    }

    function mint(uint256 amount) public payable {
        require(totalSupply() < MAX_SUPPLY, "RapNameNFT: Sale has ended");
        require(amount > 0, "RapNameNFT: Cannot buy 0");
        require(amount <= MAX_PURCHASE, "RapNameNFT: You may not buy that many NFTs at once");
        require(totalSupply().add(amount) <= MAX_SUPPLY, "RapNameNFT: Exceeds max supply");
        require(PRICE.mul(amount) == msg.value, "RapNameNFT: Ether value sent is not correct");

        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, constructTokenURI(tokenId));
        }
    }

    function withdraw() public onlyOwner {
        uint256 balancePortion = address(this).balance / 2;

        Address.sendValue(payable(yungmoneyAddr), balancePortion);
        Address.sendValue(payable(scriptkiddyAddr), balancePortion);
    }

    function setRapName(uint256 tokenId, string memory name) public onlyOwner {
        require(bytes(rapNames[tokenId]).length == 0, "RapNameNFT: Already set rap name");
        rapNames[tokenId] = name;
    }

    function getRapName(uint256 tokenId) public onlyOwner view returns (string memory){
        return rapNames[tokenId];
    }

    function setRapNames(
        string [] memory names
    ) public onlyOwner {
        require(names.length <= MAX_SUPPLY, "Can't mint more than MAX_SUPPLY");
        uint256 i = 1;
        for (i = 1; i <= names.length; ++i) {
            setRapName(i, names[i - 1]);
        }
    }

    function getCurrentTokenId() public view returns (uint256 tokenId) {
        return _tokenIdCounter.current();
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function generateSvgImage(uint256 tokenId) internal view returns (string memory) {
        string memory rapName = rapNames[tokenId];
        require(bytes(rapName).length != 0, "RapNameNFT: rap name not found!");
        string memory prefix = "<svg viewBox=\"0 0 240 80\" xmlns=\"http://www.w3.org/2000/svg\">"
            "<style>.small { font: 12px monospace; }</style>"
            "<text x=\"20\" y=\"35\" class=\"small\">";
        string memory suffix = "</text></svg>";

        string memory svgBase64Encoded = Base64.encode(
            abi.encodePacked(prefix, rapName, suffix)
        );
        return string(svgBase64Encoded);
    }

    function constructTokenURI(uint256 tokenId) internal view returns (string memory) {
        string memory image = generateSvgImage(tokenId);
        string memory rapName = rapNames[tokenId];

        return
        string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            rapName,
                            '", "description":"',
                            'Every web3 rapper needs a web3 name.',
                            ' Rap Name NFT generates a random rap name for you on-chain.',
                            '", "image": "',
                            'data:image/svg+xml;base64,',
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
    internal
    override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
