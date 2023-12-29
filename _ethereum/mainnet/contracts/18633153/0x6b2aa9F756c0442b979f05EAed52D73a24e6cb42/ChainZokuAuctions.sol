// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ReentrancyGuard.sol";
import "./Initialize.sol";
import "./ERC721AManager.sol";
import "./ShareProxy.sol";
import "./AuctionMulti.sol";
import "./Pause.sol";

contract ChainZokuAuctions is AuctionMulti, ERC721AManager, Initialize, ShareProxy, Pause, ReentrancyGuard {

    event EndAuction(uint256 auctionId, uint256 count);

    function init(address _resolverAddress, address _zokuByChainZoku, address _shareContract, address _multiSigContract) public onlyOwner isNotInitialized {
        AuctionMulti.setResolverAddress(_resolverAddress);
        ERC721AManager._setERC721Address(_zokuByChainZoku);
        ShareProxy._setShareContract(_shareContract);
        MultiSigProxy._setMultiSigContract(_multiSigContract);
    }

    function SendBid(uint256 _auctionId, uint256 _count) public payable override notPaused nonReentrant {
        super.SendBid(_auctionId, _count);
    }

    function ResolveAuction(uint256 _currentAuctionId) public onlyOwnerOrAdminsOrResolver {
        AuctionMulti.closeAuction(_currentAuctionId);

        uint256 count = 0;
        for(uint256 i = 0; i < auctions[_currentAuctionId].count; i++){
            if(bids[_currentAuctionId][i].bidder != address(this)){
                ERC721AManager._mint(bids[_currentAuctionId][i].bidder, 1);
                count += 1;
            }
        }

        ShareProxy.withdraw();

        emit EndAuction(_currentAuctionId, count);
    }

}
