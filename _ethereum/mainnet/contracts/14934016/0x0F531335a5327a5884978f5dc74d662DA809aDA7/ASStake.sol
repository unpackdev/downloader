// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";

contract ASStake is Ownable, IERC721Receiver {
    mapping (uint => address) public ownership;
    mapping(uint => uint) public stakeTime;
    mapping (address => uint[]) private _qty;

    bool public paused = true;
    uint nullToken = 1 ether;
    IERC721 public NFT;

    modifier notPaused(){
        require(!paused, "PAUSED");
        _;
    }

    constructor() {}

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function setNFTAddress(address new_) external onlyOwner {
        NFT = IERC721(new_);
    }

    function getAssetsByHolder(address holder) public view returns (uint[] memory){
        return _qty[holder];
    }

    function stake(uint[] calldata tokenIds) public notPaused {
        for(uint i=0; i < tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            if(NFT.ownerOf(tokenId) == _msgSender()){
                stakeTime[tokenId] = block.timestamp;
                ownership[tokenId] = _msgSender();
                NFT.transferFrom(_msgSender(), address(this), tokenId);
                _qty[_msgSender()].push(tokenId);
            }
        }
    }

    function unstake(uint[] calldata tokenIds) public {
        for(uint i=0; i< tokenIds.length; i++){
            uint tokenId = tokenIds[i];
            recover(tokenId);
            removeToken(tokenId);
        }
    }

    function recover(uint tokenId) internal {
        require(ownership[tokenId] == _msgSender(), "ownership failed");
        ownership[tokenId] = address(0);
        NFT.transferFrom(address(this), _msgSender(), tokenId);
    }

    function removeToken(uint tokenId) internal {
        for(uint i=0;i<_qty[_msgSender()].length;i++){
            if(_qty[_msgSender()][i] == tokenId){
                _qty[_msgSender()][i] = nullToken;
                break;
            }
        }
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(address(NFT) == operator, "not allowed");
        return this.onERC721Received.selector;
    }

}