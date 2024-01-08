// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./Ownable.sol";

import "./console.sol";


interface IPunkBodiesLike {
    function mint(address _to, uint256 _id) external;
}

contract NFTDistributor is Ownable {

    address public immutable token;

    // My storage
    mapping(uint256 => bool) public minted;

    uint256 public startTime;
    uint256 public nextId = 10000;
    uint256 public basePrice = 0.05 ether; 

    uint256 public maxOwnerMinter = 800;
    uint256 public ownerMinted; 

    address payable public ownerWallet = payable(0x4dB3ce00D5F784733d3e1F7E8bE19631fAA57958);


    event Purchased(address account, uint256 startingId, uint256 amount, uint256 cost);

    constructor(address _token) {
        token = _token;
    }

    //Owner functions
    function setBasePrice(uint256 newPrice) external onlyOwner {
        basePrice =  newPrice;
    }

    function setOwnerWallet(address payable newWallet) external onlyOwner {
        ownerWallet = newWallet;
    }

    function startSale() external onlyOwner {
        require(startTime == 0, "alredy started");
        startTime = block.timestamp;
    }

    function withdraw() external onlyOwner {
        require(ownerWallet != address(0));
        ownerWallet.transfer(address(this).balance);
    }

    function mintReserved(address to, uint256 amount) external onlyOwner {
        require(ownerMinted + amount <= maxOwnerMinter, "NFTDistributor: minted too many");

        uint _nxtId = nextId;
        for (_nxtId; _nxtId < nextId + amount; _nxtId ++) {
            _mint(to, _nxtId);
        }
        nextId = _nxtId;
    }

    function purchase(uint256 amount) payable external {
        require(startTime > 0, "NFTDistributor: Not started.");

        _purchase(amount);
    }

    function _purchase(uint256 amount) internal {
        require(amount <= 20, "NFTDistributor: Cannot purchase more than 20 at once.");
        require(msg.value == getPrice() * amount, "NFTDistributor: Amount not correct.");

        uint _nxtId = nextId;
        for (_nxtId; _nxtId < nextId + amount; _nxtId ++) {
            _mint(msg.sender, _nxtId);
        }
        nextId = _nxtId;
        emit Purchased(msg.sender, _nxtId - amount,amount, msg.value);
    }

    function _mint(address _to, uint256 _tokenId) internal {
        minted[_tokenId] = true;
        IPunkBodiesLike(token).mint(_to, _tokenId);
    }

    function getPrice() public view returns(uint256) {
        return basePrice;
    }

}