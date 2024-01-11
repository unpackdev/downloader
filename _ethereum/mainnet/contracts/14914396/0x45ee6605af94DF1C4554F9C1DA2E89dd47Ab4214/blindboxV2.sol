// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract BearHoodInterface {
    function openBox(address to) public virtual returns(uint256);
}

abstract contract OldBoxInterface{
    function balanceOf(address account, uint256 id) public view virtual returns (uint256);
    function burn(address account, uint256 id, uint256 value) public virtual;
}


contract BoxOpenTool is Ownable{
    using SafeMath for uint256;

    string public name;
    string public symbol;

    uint256 tokenId = 0;
    address bearhoodContractAddress;
    address oldBoxContractAddress;
                                

    constructor(
        address _oldBoxContract,
        address _bearhoodContract
    ) {
        oldBoxContractAddress = _oldBoxContract;
        bearhoodContractAddress = _bearhoodContract;
    }

    function setBearContract(address contractAddress) public onlyOwner {
        bearhoodContractAddress = contractAddress;
    }

    function setOldBoxContract(address contractAddress) public onlyOwner {
        oldBoxContractAddress = contractAddress;
    }

    function batchReveal(uint256 amount) public {
        OldBoxInterface oldBoxContract = OldBoxInterface(oldBoxContractAddress);
        uint256 oldBalance = oldBoxContract.balanceOf(msg.sender, tokenId);
        require(oldBalance >= amount, "Doesn't own the token");
        oldBoxContract.burn(msg.sender, tokenId, amount);
        
        BearHoodInterface bearhoodContract = BearHoodInterface(bearhoodContractAddress);
        for (uint256 i=0; i<amount; i++) {
            bearhoodContract.openBox(msg.sender);
        }
    }
    
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}
    