pragma solidity ^0.8.13;
// SPDX-License-Identifier: UNLICENSED
/*
 * (c) Copyright 2022 Masalsa, Inc., all rights reserved.
  You have no rights, whatsoever, to fork, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.
  By using this file/contract, you agree to the Customer Terms of Service at nftdeals.xyz
  THE SOFTWARE IS PROVIDED AS-IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  This software is Experimental, use at your own risk!
 */

import "./console.sol";
import "./EnumerableSet.sol";
import "./AccessControl.sol";
import "./Multicall.sol";
import "./Auction.sol";

contract AuctionFactory is AccessControl, Multicall {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private myAuctionsSet;
    EnumerableSet.AddressSet private bidderAddressesWithRewards;

    address public immutable wethAddress;
    address public immutable adminOneAddress;
    address public immutable adminTwoAddress;

    mapping(address => uint) public rewards;

    event RewardGiven(address to, uint rewardAmout);
    event RewardSet(address to, uint rewardAmout);
    event AuctionGenerated(address nftOwner, address auctionContractAddress);

    modifier youAreAnAuction(){
        require(myAuctionsSet.contains(msg.sender) == true, 'you are not an auction');
        _;
    }

    function giveReward(address to, uint reward) youAreAnAuction public {
        console.log('going to give reward');
        console.log(to);
        console.log(reward);
        rewards[to] += reward;
        bidderAddressesWithRewards.add(to);
        emit RewardGiven(to, reward);
    }

    constructor(address _addr, address _adminOneAddress, address _adminTwoAddress){
        wethAddress = _addr;
        adminOneAddress = _adminOneAddress;
        adminTwoAddress = _adminTwoAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, _adminOneAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _adminTwoAddress);
    }

    function createAuction(
        uint tokenId,
        address nftContract,
        uint startBidAmount,
        uint _auctionTimeIncrementOnBid,
        uint _minimumBidIncrement
    ) external{
        Auction auction = new Auction(
            nftContract, // _nftContractAddress
            tokenId,
            startBidAmount, // 1 eth // startBidAmount
            _auctionTimeIncrementOnBid, // 1 minute // _auctionTimeIncrementOnBid
            _minimumBidIncrement, // 0.1 eth // _minimumBidIncrement
            msg.sender, // chrome // nftOwner
            wethAddress, // address given to us when constructed per chain.
            adminOneAddress,
            adminTwoAddress,
            address(this)
        );
        _saveNewAuction(msg.sender, address(auction));
    }

    function _saveNewAuction(address nftOwner, address auctionAddress) private {
        myAuctionsSet.add(auctionAddress);
        emit AuctionGenerated(nftOwner, address(auctionAddress));
    }

    function setRewardBalance(address bidderAddress, uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rewards[bidderAddress] = amount;
        bidderAddressesWithRewards.add(bidderAddress);
        emit RewardSet(bidderAddress, amount);
    }

    function getAuction(uint index) public view returns(address){
        return  myAuctionsSet.at(index);
    }

    function removeAuction(address _auction) public onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        return myAuctionsSet.remove(_auction);
    }

    function addAuction(address[] memory _auctions) public onlyRole(DEFAULT_ADMIN_ROLE) {
        console.log('i am in addAuction');
        for(uint i=0;i<_auctions.length;i++){
            console.log('adding auction');
            console.log(_auctions[i]);
            Auction tempAuction = Auction(_auctions[i]);
            _saveNewAuction(tempAuction.nftOwner(), _auctions[i]);
        }
    }

    function auctions() public view returns(address[] memory){
        return myAuctionsSet.values();
    }

    function isAnAuction(address _auctionAddress) public view returns(bool) {
        return myAuctionsSet.contains(_auctionAddress);
    }

    function auctionsLength() public view returns(uint){
        return myAuctionsSet.length();
    }

    function numberOfBidderAddressesWithRewards() public view returns(uint){
        return bidderAddressesWithRewards.length();
    }

    function addressWithRewardAtIndex(uint index) public view returns(address){
        return bidderAddressesWithRewards.at(index);
    }

    function allAddressesWithRewards() public view returns(address[] memory){
        return bidderAddressesWithRewards.values();
    }

    function selfDestruct() onlyRole(DEFAULT_ADMIN_ROLE) external {
        selfdestruct(payable(msg.sender));
    }
}
