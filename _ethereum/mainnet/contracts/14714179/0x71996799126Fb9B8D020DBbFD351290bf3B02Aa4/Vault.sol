// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";
import "./Pausable.sol";
import "./EnumerableSet.sol";
import "./IERC1155Receiver.sol";
import "./ERC1155Holder.sol";
import "./ReentrancyGuard.sol";

contract Champs_Staking is Ownable, Pausable, ERC1155Holder, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;


    address public erc1155Address = 0x38a6fd7148c4900338e903258B5E289Dfa995E2E;

    mapping(address=>uint256) public amountDeposited;

    constructor() {   

    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }



    function depositERC1155(uint256 id,uint256 amount) external whenNotPaused nonReentrant  {

        IERC1155(erc1155Address).safeTransferFrom(msg.sender,address(this),id,amount,'');
        amountDeposited[msg.sender]+=amount;
    }

    


        function withdrawERC1555(uint256 id, uint256 amount) external whenNotPaused nonReentrant  {
        require(amountDeposited[msg.sender]>=amount,"You Don't Have This Amount Staking");
        amountDeposited[msg.sender]-=amount;
        IERC1155(erc1155Address).safeTransferFrom(address(this),msg.sender,id,amount,'');
        
    }

    function setERC1155Address(address newERC1155Address) external whenNotPaused onlyOwner nonReentrant {
        erc1155Address = newERC1155Address;

    }

    function checkAuth(address _address) public view  returns(bool){

        if(amountDeposited[_address] >0){
            return true;
        }
        return false;
    }

       function checkAuth2() public view  returns(bool){

        if(amountDeposited[msg.sender] >0){
            return true;
        }
        return false;
    }

    
}
interface IERC1155  {
     function balanceOf(address account, uint256 id) external view   returns (uint256);
     function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function setApprovalForAll(address operator, bool approved) external;


}