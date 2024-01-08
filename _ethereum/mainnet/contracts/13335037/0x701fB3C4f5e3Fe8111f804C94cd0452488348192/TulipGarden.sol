// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC721.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract TulipGarden is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_PLOTS = 2500;

    uint256 public constant PLOT_PRICE_GEN_0_1 = 0.01 ether;
    uint256 public constant PLOT_PRICE_GEN_2021 = 0.025 ether;
    uint256 public constant PLOT_PRICE_EMPTY = 0.04 ether;

    mapping(uint256 => uint256) public plotToNftId;
    mapping(uint256 => address) public plotToNftAddress;
    mapping(uint256 => string) public plotData;
    mapping(address => mapping(uint256 => bool)) public nftPlanted;

    address public ethertulipsAddress;
    IERC721 private EtherTulips;
    mapping(uint256 => bool) public tulipRedeemed;

    mapping(address => bool) public allowedNfts;
    bool public salesStarted = false;

    constructor(address _ethertulipsAddress) ERC721("EtherTulipGardenPlots", "TULIP-PLOT") {
        ethertulipsAddress = _ethertulipsAddress;
        allowedNfts[ethertulipsAddress] = true;
        EtherTulips = IERC721(ethertulipsAddress);
    }

    function claim(uint256 _tokenId) payable external {
        require(salesStarted, 'Sales have not been started');
        require(plotValid(_tokenId), 'Invalid token ID');
        require(msg.value == PLOT_PRICE_EMPTY, 'Incorrect ether amount sent');

        _safeMint(_msgSender(), _tokenId);
    }

    function claimWithTulip(uint256 _tokenId, uint256 _tulipId) payable external {
        require(salesStarted, 'Sales have not been started');
        require(plotValid(_tokenId), 'Invalid token ID');
        require(_tulipId < 12345, 'Invalid tulip ID');
        require(!nftPlanted[ethertulipsAddress][_tulipId], 'Tulip already planted');
        require(!tulipRedeemed[_tulipId], 'Tulip already redeemed');
        require(EtherTulips.ownerOf(_tulipId) == _msgSender(), 'Tulip not owned by sender');

        if (_tulipId <= 7250) {
            // gen 0/1
            require(msg.value == PLOT_PRICE_GEN_0_1, 'Incorrect ether amount sent');
        } else {
            // gen 2021
            require(msg.value == PLOT_PRICE_GEN_2021, 'Incorrect ether amount sent');
        }

        _safeMint(_msgSender(), _tokenId);
        _plant(_tokenId, _tulipId, ethertulipsAddress);
        tulipRedeemed[_tulipId] = true;
    }

    function plant(uint256 _tokenId, uint256 _nftId, address _nftAddress) public {
        require(allowedNfts[_nftAddress], 'NFT not allowed by admin');
        require(ownerOf(_tokenId) == _msgSender(), 'Plot not owned by sender');
        require(IERC721(_nftAddress).ownerOf(_nftId) == _msgSender(), 'NFT not owned by sender');
        require(!nftPlanted[_nftAddress][_nftId], 'NFT already planted');

        nftPlanted[plotToNftAddress[_tokenId]][plotToNftId[_tokenId]] = false;
        _plant(_tokenId, _nftId, _nftAddress);
    }

    function uproot(uint256 _tokenId) public {
        require(!plotEmpty(_tokenId), 'Plot is empty');
        require(
            ownerOf(_tokenId) == _msgSender() || IERC721(plotToNftAddress[_tokenId]).ownerOf(plotToNftId[_tokenId]) == _msgSender(),
            'Plot or token must be owned by sender'
        );

        nftPlanted[plotToNftAddress[_tokenId]][plotToNftId[_tokenId]] = false;
        plotToNftAddress[_tokenId] = address(0);
    }

    function setPlotData(uint256 _tokenId, string memory _data) public {
        require(ownerOf(_tokenId) == _msgSender(), 'Plot not owned by sender');
        plotData[_tokenId] = _data;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), 'plot/', _tokenId.toString(), '.json'));
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "garden-meta.json"));
    }

    /* State checking */

    function plotValid(uint256 _tokenId) public pure returns (bool) {
        return _tokenId < MAX_PLOTS;
    }

    function plotEmpty(uint256 _tokenId) public view returns (bool) {
        return plotToNftAddress[_tokenId] == address(0);
    }

    function plotClaimed(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /* Internal */

    function _plant(uint256 _tokenId, uint256 _nftId, address _nftAddress) internal {
        plotToNftId[_tokenId] = _nftId;
        plotToNftAddress[_tokenId] = _nftAddress;
        nftPlanted[_nftAddress][_nftId] = true;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        super._beforeTokenTransfer(_from, _to, _tokenId);

        plotToNftAddress[_tokenId] = address(0);
        plotData[_tokenId] = '';
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://tokens.ethertulips.com/meta/";
    }

    /* Owner only */

    function startSales() external onlyOwner {
        salesStarted = true;
    }

    function reserve(uint256 _tokenId) external onlyOwner {
        require(plotValid(_tokenId), 'Invalid token ID');

        _safeMint(_msgSender(), _tokenId);
    }

    function allowNft(address _nftAddress) external onlyOwner {
        require(IERC721(_nftAddress).supportsInterface(type(IERC721).interfaceId), 'Must support ERC721');
        allowedNfts[_nftAddress] = true;
    }

    function withdrawBalance(uint256 _amount) external onlyOwner {
        require(_amount <= address(this).balance);
        payable(msg.sender).transfer(_amount);
    }
}
