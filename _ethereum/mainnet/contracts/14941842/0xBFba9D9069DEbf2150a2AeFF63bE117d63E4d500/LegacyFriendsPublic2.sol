// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IERC721{
    function transferFrom(address,address,uint256) external;
}

contract BuyLegacyFriends is Ownable, ReentrancyGuard {
        uint256 public constant _buyPrice = 0.05 ether;
        address private _withdrawalWallet = 0xCa87b367554B1A92b41923F789d1ffc9DC2CCA3d; // admin wallet address
        address private _legacyContractAddress = 0x96Af517c414B3726c1B2Ecc744ebf9d292DCbF60; // LegacyFriends Alpha contract address
        uint256 public bullsLimit = 118;
        uint256 public miniLimit = 94;
        uint256 public badgeLimit = 115;
        uint256 public chefLimit = 157;
        uint256 public lastClaimedBull = 289;
        uint256 public lastClaimedMini = 642;
        uint256 public lastClaimedBadge = 1181;
        uint256 public lastClaimedChef = 1789;


        modifier onlyWithdrawalWalletOrOwner {
            require(msg.sender == _withdrawalWallet || msg.sender == owner());
            _;
        }

        function setWithdrawlWallet(address _newWithdrawlWallet) external onlyWithdrawalWalletOrOwner {
            _withdrawalWallet = _newWithdrawlWallet;
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

        function buyBadge() external payable nonReentrant returns(bool) {
            uint256 tokenId = --lastClaimedBadge;
            require(checkId(tokenId), "LegacyFriends: No NFT available");
            require(msg.value == _buyPrice, "LegacyFriends: Send more Ethers");
            IERC721(_legacyContractAddress).transferFrom(_withdrawalWallet, msg.sender, tokenId);
            return true;
        }

        function buyMini() external payable nonReentrant returns(bool) {
            uint256 tokenId = --lastClaimedMini;
            if(tokenId == 500) { 
                tokenId = 499; 
                lastClaimedMini = tokenId;
            }
            require(checkId(tokenId), "LegacyFriends: No NFT available");
            require(msg.value == _buyPrice, "LegacyFriends: Send more Ethers");
            IERC721(_legacyContractAddress).transferFrom(_withdrawalWallet, msg.sender, tokenId);
            return true;
        }

        function buyChef() external payable nonReentrant returns(bool) {
            uint256 tokenId = --lastClaimedChef;
            if(tokenId <= 1735 && tokenId >= 1728) { 
                tokenId = 1727; 
                lastClaimedChef = tokenId;
            }
            require(checkId(tokenId), "LegacyFriends: No NFT available");
            require(msg.value == _buyPrice, "LegacyFriends: Send more Ethers");
            IERC721(_legacyContractAddress).transferFrom(_withdrawalWallet, msg.sender, tokenId);
            return true;
        }

        function buyBull() external payable nonReentrant returns(bool) {
            uint256 tokenId = --lastClaimedBull;
            if(tokenId == 200) { 
                tokenId = 199;
                lastClaimedBull = tokenId; 
            }
            require(checkId(tokenId), "LegacyFriends: No NFT available");
            require(msg.value == _buyPrice, "LegacyFriends: Send more Ethers");
            IERC721(_legacyContractAddress).transferFrom(_withdrawalWallet, msg.sender, tokenId);
            return true;
        }

        function checkId(uint _tokenId) internal returns(bool){
                if(_tokenId >= 153 && _tokenId <= 288 && bullsLimit != 0){
                    unchecked{
                    bullsLimit--;
                    }
                    return true;
                }
                if(_tokenId >= 427 && _tokenId <= 641 && miniLimit != 0){
                    unchecked{
                    miniLimit--;
                    }
                    return true;
                }
                if(_tokenId >= 1044 && _tokenId <= 1180 && badgeLimit != 0){
                    unchecked{
                    badgeLimit--;
                    }
                    return true;
                }
                if(_tokenId >= 1602 && _tokenId <= 1788 && chefLimit != 0){
                    unchecked{
                    chefLimit--;
                    }
                    return true;
                }
                return false;
            }
}