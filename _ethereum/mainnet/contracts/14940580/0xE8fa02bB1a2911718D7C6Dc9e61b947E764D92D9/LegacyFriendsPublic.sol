// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IERC721A{
    function safeTransferFrom(address,address,uint256) external;
}

contract BuyLegacyFriends is Ownable, ReentrancyGuard {
        uint256 public constant _buyPrice = 0.05 ether;
        address private _withdrawalWallet = 0xCa87b367554B1A92b41923F789d1ffc9DC2CCA3d; // admin wallet address 
        address private _legacyContractAddress = 0x96Af517c414B3726c1B2Ecc744ebf9d292DCbF60; // LegacyFriends Alpha contract address
        uint256 public bullsLimit = 118;
        uint256 public miniLimit = 94;
        uint256 public badgeLimit = 115;
        uint256 public chefLimit = 157;
        modifier onlyWithdrawalWalletOrOwner {
            require(msg.sender == _withdrawalWallet || msg.sender == owner());
            _;
        }
        function setWithdrawlWallet(address _newWithdrawlWallet) external onlyWithdrawalWalletOrOwner {
            _withdrawalWallet = _newWithdrawlWallet;
        }
        function buyNft(uint256 _tokenId) external payable nonReentrant returns(bool) {
            require(calculateType(_tokenId), "LegacyFriends: Invalid Token Id");
            require(msg.value >= _buyPrice, "LegacyFriends: Send more Ethers");
            IERC721A(_legacyContractAddress).safeTransferFrom(_withdrawalWallet, msg.sender, _tokenId);
            require(payable(_withdrawalWallet).send(msg.value), "LegacyFriends: Transfer Failed");
            return true;
        }
        function setBullsLimit(uint _newLimit) external {
            require(msg.sender == _withdrawalWallet);
            bullsLimit = _newLimit;
        }
        function setMiniLimit(uint _newLimit) external {
            require(msg.sender == _withdrawalWallet);
            miniLimit = _newLimit;
        }
        function setBadgeLimit(uint _newLimit) external {
            require(msg.sender == _withdrawalWallet);
            badgeLimit = _newLimit;
        }
        function setChefLimit(uint _newLimit) external {
            require(msg.sender == _withdrawalWallet);
            chefLimit = _newLimit;
        }
        function withdrawAll() external {
            require(msg.sender == _withdrawalWallet);
            uint256 _each = address(this).balance;
            require(payable(_withdrawalWallet).send(_each), "Transfer Failed");
        }
        function calculateType(uint _tokenId) internal returns(bool){
                if(_tokenId <= 300 && bullsLimit != 0){
                    unchecked{
                    bullsLimit--;
                    }
                    return true;
                }
                if(_tokenId >= 301 && _tokenId <= 650 && miniLimit != 0){
                    unchecked{
                    miniLimit--;
                    }
                    return true;
                }
                if(_tokenId >= 651 && _tokenId <= 1188 && badgeLimit != 0){
                    unchecked{
                    badgeLimit--;
                    }
                    return true;
                }
                if(_tokenId >= 1189 && _tokenId <= 1788 && chefLimit != 0){
                    unchecked{
                    chefLimit--;
                    }
                    return true;
                }
                return false;
            }
}