//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./IERC20.sol";
import "./Ownable.sol";

import "./AlbumBuyoutManager.sol";
import "./AlbumNftManager.sol";
import "./AlbumTokenSaleManager.sol";

contract Album is
    Ownable,
    ERC721Holder,
    AlbumBuyoutManager,
    AlbumNftManager,
    AlbumTokenSaleManager
{
    // The token for this album.
    IERC20 public token;

    constructor(
        address governance,
        address _token,
        address creator,
        TokenSaleParams memory tokenSaleParams,
        address[] memory _nftAddrs,
        uint256[] memory _nftIds,
        uint256 _minReservePrice
    ) AlbumTokenSaleManager(creator, tokenSaleParams) {
        transferOwnership(governance);
        token = IERC20(_token);
        _addNfts(_nftAddrs, _nftIds);
        _setMinReservePrice(_minReservePrice);
    }

    function addNfts(address[] memory _nfts, uint256[] memory _ids)
        public
        onlyOwner
    {
        _addNfts(_nfts, _ids);
    }

    function sendNfts(address to, uint256[] memory idxs) public onlyOwner {
        _sendNfts(to, idxs);
    }

    function setTimeout(uint256 _timeout) public onlyOwner {
        _setTimeout(_timeout);
    }

    function sendAllToSender() internal override {
        address[] memory nfts = getNfts();
        uint256[] memory ids = getIds();
        bool[] memory sent = getSent();
        for (uint256 i = 0; i < nfts.length; i++) {
            if (!sent[i]) {
                IERC721(nfts[i]).safeTransferFrom(
                    address(this),
                    msg.sender,
                    ids[i]
                );
            }
        }
    }

    function setMinReservePrice(uint256 _minReservePrice) public onlyOwner {
        _setMinReservePrice(_minReservePrice);
    }

    function setBuyout(address _buyer, uint256 _cost) public onlyOwner {
        _setBuyout(_buyer, _cost);
    }

    function checkOwedAmount(uint256 _amount, uint256 buyoutCost)
        internal
        override
        returns (uint256 owed)
    {
        token.transferFrom(msg.sender, address(this), _amount);
        owed = (_amount * buyoutCost) / token.totalSupply();
    }

    function getToken() public view override returns (IERC20) {
        return token;
    }
}
