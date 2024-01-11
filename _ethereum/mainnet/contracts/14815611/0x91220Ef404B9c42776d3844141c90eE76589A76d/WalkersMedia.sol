// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./ERC721A.sol";

abstract contract EWALKS is IERC721 {}

contract ETHWalkersSeasonOneMedia is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    address payable public payoutsAddress = payable(address(0x2608b7D6D6E7d98f1b9474527C3c1A0eD54bE399));

    EWALKS private ewalk;
    uint public publicSale = 1653015600;
    uint8 public saleState = 1;
    uint public maxMedia = 5000;
    mapping(uint256 => bool) walkerRedeemed;
    uint256 private _MediaPrice = 10000000000000000; // 0.01 ETH

    constructor() ERC721A("ETH Walkers Season One Media", "EWSOM") {
        address EwalksAddress = 0x4691b302c37B53c68093f1F5490711d3B0CD2b9C;
        ewalk = EWALKS(EwalksAddress);
    }

    function getMintRedeemed(uint256 _id) public view returns (bool){
        return walkerRedeemed[_id];
    }

    function setSaleTimes(uint[] memory _newTimes) external onlyOwner {
        require(_newTimes.length == 1, "You need to update all times at once");
        publicSale = _newTimes[0];
    }

    function mediaClaim(uint256[] memory ids) external {
        require(saleState >= 1, "Sale is off");
        require(block.timestamp >= publicSale, "Sale must be started");
        require(!isContract(msg.sender), "I fight for the user! No contracts");
        require((totalSupply() + ids.length) <= maxMedia, "Purchase exceeds max supply of S1 media!");

        for(uint i = 0; i < ids.length; i++) {
            require(ewalk.ownerOf(ids[i]) == msg.sender, "Must own a ETH Walker to mint free media");
            require(!walkerRedeemed[ids[i]], "This ETH Walker already redeemed for mint");
            walkerRedeemed[ids[i]] = true;
        }

        _mint(_msgSender(), ids.length);
    }

    function mintAdditionalMedia(uint numberOfTokens) external payable {
        require(saleState >= 1, "Sale is off");
        require(numberOfTokens > 0 && numberOfTokens <= 20, "20 Media per tx");
        require(msg.value >= (_MediaPrice * numberOfTokens), "Ether value is incorrect. Try again");
        require(!isContract(msg.sender), "I fight for the user! No contracts");
        require((totalSupply() + numberOfTokens) <= (maxMedia - 3720), "Purchase exceeds max supply of Additional Media");
        require(block.timestamp >= publicSale, "Public sale not started");

        _mint(_msgSender(), numberOfTokens);

        (bool sent, ) = payoutsAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with payoutsAddress");
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}