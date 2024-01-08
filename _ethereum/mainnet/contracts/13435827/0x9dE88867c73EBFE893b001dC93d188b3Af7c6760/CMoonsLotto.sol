//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";

contract CMoonsLotto is VRFConsumerBase{

    address public owner;
    uint256 public winnerTokenId;
    address public CMoonsAddress;
    address payable public winnerAddress;

    bytes32 internal keyHash;
    uint256 internal fee;
    address public VRFCoordinator;
    address public LinkToken;
     modifier onlyOwner(){
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }
     

     constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash)
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
    {   
        VRFCoordinator = _VRFCoordinator;
        LinkToken = _LinkToken;
        keyHash = _keyhash;
        fee = 2 * 10**18; // 2 LINK
        owner = msg.sender;
    }

    

    function pickLottoWinner() public onlyOwner {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        requestRandomness(keyHash, fee);
    }

        receive() external payable {
        }

       function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        // Can only be picked once 
        if(winnerTokenId == 0){
            winnerTokenId = (randomNumber % 4) + 1;
            CMoonsNFT cMoon = CMoonsNFT(CMoonsAddress);
            winnerAddress = payable(cMoon.ownerOf(winnerTokenId));
        }
        
    }

    function sendWinnerFunds() public onlyOwner {
        if(winnerTokenId != 0 && winnerAddress != payable((address(0x0)))){
            winnerAddress.transfer(address(this).balance);
        }
    }

    function setContractAddress(address contractAddress) public onlyOwner {
        CMoonsAddress = contractAddress;
    }

}

abstract contract CMoonsNFT {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}