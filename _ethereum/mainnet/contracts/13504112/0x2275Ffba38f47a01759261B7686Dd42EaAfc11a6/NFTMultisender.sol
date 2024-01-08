// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC721.sol";
import "./SafeMath.sol";

contract NFTMultisender is Ownable{
    using SafeMath for uint256;
    uint256 public fee;
    address payable public withdrawalWallet;

    event FeeChanged(uint256 _fee);
    event TransferComplete(address[] _addresses, uint256[] _tokenIds);
    event WithdrawalWalletChanged(address payable _withdrawalWallet);


    constructor(uint256 _fee, address payable _withdrawalWallet){
        fee = _fee;
        withdrawalWallet = _withdrawalWallet;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit FeeChanged(_fee);
    }

    function setWithdrawalWallet(address payable _withdrawalWallet) external onlyOwner {
        withdrawalWallet = _withdrawalWallet;
        emit WithdrawalWalletChanged(withdrawalWallet);
    }

    function multisend(address _tokenAddress, address[] memory _addresses, uint256[] memory _tokenIds) external payable {
        require(IERC721(_tokenAddress).isApprovedForAll(_msgSender(), address(this)), "NFTMultisender::multisend: NFTs are not Approved.");
        require(_addresses.length == _tokenIds.length, "NFTMultisender::multisend: Addresses and TokenIds length is not Matching.");
        require(msg.value >= fee.mul(_tokenIds.length), "NFTMultisender::multisend: Insufficient funds.");
        
        for(uint256 i=0; i < _addresses.length; i++){
            IERC721(_tokenAddress).safeTransferFrom(_msgSender(), _addresses[i], _tokenIds[i]);
        }
        
        emit TransferComplete(_addresses, _tokenIds);
        withdrawalWallet.transfer(address(this).balance);
    }

    receive() external payable {}


}