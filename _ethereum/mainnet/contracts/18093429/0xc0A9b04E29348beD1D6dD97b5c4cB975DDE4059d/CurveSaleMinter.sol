// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SkyGazers.sol";

contract CurveSaleMinter is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    TimeToken public timeToken;

    constructor(
        SkyGazers _token,
        uint256 _offset, // offset where to start in the collection
        uint256 _amount, // how many to mint
        uint256 _c, // initial NFT batch size
        uint256 _dc, // delta
        uint256 _p, // initial NFT price
        uint256 _dp, // delta
        address _receiver // receiver of funds
    ) {
        c = _c;
        dc = _dc;
        p = _p;
        dp = _dp;
        amount = _amount;
        offset = _offset;
        token = _token;
        receiver = _receiver;
    }

    SkyGazers public token;
    uint256 public c;
    uint256 public dc;
    uint256 public p; // current mintprice
    uint256 public dp;
    uint256 public amount;
    uint256 public offset;
    address public receiver;
    uint256 public x;

    function setReceiver(address _receiver) public onlyOwner {
        receiver = _receiver;
    }

    function nextPrice() internal {
        if (x > (c >> 64)) {
            p = ((p * dp) >> 64);
            c = ((c * dc) >> 64);
            x = 0;
        }
        x++;
    }

    function currentIndex() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mintItems(uint256[] memory ids) public payable {
        uint256 paid;
        for (uint i = 0; i < ids.length; i++) {
            paid += mintItem(ids[i]);
        }
        // refund rest
        payable(msg.sender).transfer(msg.value - paid);
    }

    function mintItem(uint256 id) internal returns (uint256) {
        uint256 price = p;
        require(_tokenIds.current() <= amount, "All NFTs minted");
        require(id >= offset && id < offset + amount, "Id not in range");
        require(msg.value >= p, "Not enough ether sent");
        payable(receiver).transfer(p);
        token.mintItem(msg.sender, id);
        _tokenIds.increment();
        nextPrice();
        return price;
    }
}
