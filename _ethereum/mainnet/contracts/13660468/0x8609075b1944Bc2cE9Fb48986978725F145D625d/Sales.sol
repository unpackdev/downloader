// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC721.sol";
import "./TIMELESS.sol";

contract NFTSaleContract is Ownable {

    address public FounderPlotNFT;
    address public NftTreeNFT;
    address public TimelessNFT;

    uint256 public price = 0.222 ether;

    bool isOpenPeriod = false;
    bool isSaleActive = false;

    event ExchangeEvent(address indexed from, uint256 tokenId, Commons.ExchangeType e);
    event ExchangeEventBatch(address indexed from, uint256[] tokenId, Commons.ExchangeType[] e);

    constructor(address _FounderPlotNFT, address _NftTreeNFT, address _TimelessNFT) {
        FounderPlotNFT = _FounderPlotNFT;
        NftTreeNFT = _NftTreeNFT;
        TimelessNFT = _TimelessNFT;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _exchange(uint256 _tokenId, Commons.ExchangeType e) internal view {
        if (isOpenPeriod) {
            require(
                IERC721(NftTreeNFT).balanceOf(msg.sender) > 0 ||
                IERC721(FounderPlotNFT).balanceOf(msg.sender) > 0 ||
                IERC721(TimelessNFT).balanceOf(msg.sender) > 0,
                "Does not have the required NFTs"
            );
            return;
        }

        require(e != Commons.ExchangeType.founder || IERC721(FounderPlotNFT).ownerOf(_tokenId) == msg.sender, "Does not own founder plot");

        require(e != Commons.ExchangeType.nftTree || IERC721(NftTreeNFT).ownerOf(_tokenId) == msg.sender, "Does not own nftTree");

        // Can't use None exchange type during first two weeks
        require(e != Commons.ExchangeType.none, "Exchange type is none");
    }

    function exchange(uint256 _tokenId, Commons.ExchangeType e) external payable  {
        require(isSaleActive, "Sale is not active yet");

        // The msg.value should be price, UNLESS it's an nft tree AND the sale is NOT open.
        require(msg.value == (e == Commons.ExchangeType.nftTree && !isOpenPeriod ? 0 : price), "NFTSaleContract: Incorrect funds sent");

        _exchange(_tokenId, e);

        Timeless(TimelessNFT).issueToken(msg.sender, _tokenId, e);

        emit ExchangeEvent(msg.sender, _tokenId, e);
    }

    function exchangeBatch(uint256[] memory  _tokenIds, Commons.ExchangeType[] memory es) external payable {
        require(isSaleActive, "Sale is not active yet");
        uint256 numberOfTokens = _tokenIds.length;

        require(_tokenIds.length > 0, "Cannot mint with zero length");
        require(_tokenIds.length == es.length, "Length mismatch");

        uint256 numberOfNftTreeTokens = 0;

        for (uint256 index = 0; index < _tokenIds.length; index++){
            if (es[index] == Commons.ExchangeType.nftTree){
                numberOfNftTreeTokens++;
            }
        }

        // The msg.value should be price * numberOfTokens, and numberOfNftTreeTokens is only subtracted if the sale is NOT open.
        require(msg.value == (price * (numberOfTokens - (isOpenPeriod ? 0 : numberOfNftTreeTokens))), "NFTSaleContract: Incorrect funds sent");

        for (uint256 index = 0; index < _tokenIds.length; index++) {
            _exchange(_tokenIds[index], es[index]);
        }

        Timeless(TimelessNFT).issueBatch(msg.sender, _tokenIds, es);

        emit ExchangeEventBatch(msg.sender, _tokenIds, es);
    }

    function setOpenPeriod(bool value) external onlyOwner {
        isOpenPeriod = value;
    }

    function setSaleActive(bool value) external onlyOwner {
        isSaleActive = value;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}
