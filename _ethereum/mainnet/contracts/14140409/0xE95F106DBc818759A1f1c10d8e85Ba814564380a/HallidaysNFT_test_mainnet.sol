// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract HallidaysNFTTestMainnet is
    ERC721,
    ERC721Enumerable,
    Ownable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => string) _tokenIdToTokenURI;
    uint public InfiniteSounds = 1;
    uint public PureFrequency = 101;
    uint public HigherReverb = 201;
    string private pu1 = 'https://kr.object.ncloudstorage.com/nft-cdn/test_metadata/TEST_pu1.json';
    string private pu2 = 'https://kr.object.ncloudstorage.com/nft-cdn/test_metadata/TEST_pu2.json';
    string private pu3 = 'https://kr.object.ncloudstorage.com/nft-cdn/test_metadata/TEST_pu3.json';
    uint256 constant feePercentage = 100;
    address constant ADDRESS_NULL = address(0);
    address recipient;

    constructor(
        string memory _name,
        string memory _symbol,
        address _recipient
    ) ERC721(_name, _symbol) {
        _tokenIdCounter.increment();
        recipient = _recipient;
    }

    modifier valueChk() { 
        require(msg.value==0.01 ether, "Please check the price.");
        _; 
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );
        return _tokenIdToTokenURI[tokenId];
    }

    //sub_nft1 mint
    function InfiniteSoundsMint() public payable valueChk returns (uint256) {
        require(InfiniteSounds < 2, "InfiniteSounds all sold out.");
        uint256 _tId = InfiniteSounds;
        InfiniteSounds += 1;
        _tokenIdToTokenURI[_tId] = pu1;
        payable(recipient).transfer(msg.value);
        _safeMint(msg.sender, _tId);
        return _tId;
    }

    //sub_nft2 mint
    function PureFrequencyMint() public payable valueChk returns (uint256) {
        require(PureFrequency < 104, "PureFrequency all sold out.");
        uint256 _tId = PureFrequency;
        PureFrequency += 1;
        _tokenIdToTokenURI[_tId] = pu2;
        payable(recipient).transfer(msg.value);
        _safeMint(msg.sender, _tId);
        return _tId;
    }

    //sub_nft3 mint
    function HigherReverbMint() external payable valueChk returns (uint256) {
        require(HigherReverb < 206, "HigherReverb all sold out.");
        uint256 _tId = HigherReverb;
        HigherReverb += 1;
        _tokenIdToTokenURI[_tId] = pu3;
        payable(recipient).transfer(msg.value);
        _safeMint(msg.sender, _tId);
        return _tId;
    }


    // nomal mint
    function safeMint(string memory _tokenURI) public onlyOwner returns(uint256){
        uint256 _tId = 300 + _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _tokenIdToTokenURI[_tId] = _tokenURI;
        _safeMint(msg.sender, _tId);
        return _tId;
    }


    function burn(uint256 tokenId) public onlyOwner {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721Burnable: caller is not owner nor approved'
        );

        delete _tokenIdToTokenURI[tokenId];
        _burn(tokenId);
    }
}
