// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./ERC721Holder.sol";


contract LuckyDrop is Ownable, ReentrancyGuard ,ERC1155Holder ,ERC721Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    struct luckyDropInfo {
        uint256 luckyDropId;
        address[] payees;
        uint256[] shareAmount;
        uint256 tokenId;
        uint256 luckyDropCategory;
        address tokenAddress;
        uint256 totalAmount;
        uint256 totalReleased;
    }

    mapping(uint256 => luckyDropInfo) internal luckyDropInfoMap;
    mapping(uint256 => mapping(address => uint256)) internal luckyDropIdToShareAmount;


    event PaymentReleased(address indexed tokenaddress, address indexed to, uint256 indexed amount, uint256 tokenaddressCategory, uint256 luckyDropId, uint256 tokenId);
    event PaymentReBackReleased(address indexed tokenaddress, address indexed to, uint256 indexed amount, uint256 tokenaddressCategory, uint256 luckyDropId, uint256 tokenId);
    event PaymentReceived(address from, uint256 amount);


  
    function creatLuckyDrop(uint256 tokenId, uint256 luckyDropCategory, address tokenAddress, uint256 totalAmount, uint256 luckyDropId) payable public {
        luckyDropInfo storage luckyDrop = luckyDropInfoMap[luckyDropId];
        require(luckyDrop.totalAmount == 0, "LuckyDrop:this LuckyDrop has been created!");
        if (luckyDropCategory == 1) {
            (bool os,) = payable(address(this)).call{value : totalAmount}('');
            require(os);
        }else if (luckyDropCategory == 2) {
            IERC20(tokenAddress).transferFrom(msg.sender,address(this), totalAmount);
        }else if (luckyDropCategory == 3) {
            IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);
        }else if (luckyDropCategory == 4) {
            IERC1155(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId, 1, abi.encode(msg.sender));
        }else{
            revert("LuckyDrop:luckyDropCategory is wrong!");
        }
        luckyDrop.luckyDropId = luckyDropId;
        luckyDrop.tokenAddress = tokenAddress;
        luckyDrop.totalAmount = totalAmount;
        luckyDrop.luckyDropCategory = luckyDropCategory;
        luckyDrop.tokenId = tokenId;
    }

    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }


    
    function releaseLuckyDrop(uint256 releaseLuckyDropId, address payable account, uint256 shareAmount) public {
        require(luckyDropIdToShareAmount[releaseLuckyDropId][account] == 0, "LuckyDrop: this account has releaseed!");
        luckyDropInfo storage releaseLuckyDrop = luckyDropInfoMap[releaseLuckyDropId];
        require(releaseLuckyDrop.totalAmount != 0, "LuckyDrop: this luckyDrop is non-existent");
        uint256 luckyDropCategory = releaseLuckyDrop.luckyDropCategory;
        address luckyDropTokenAddress = releaseLuckyDrop.tokenAddress;
        //releaseETH;
        if (luckyDropCategory == 1) {
            require(shareAmount > 0, "LuckyDrop: account is not due payment");
            Address.sendValue(account, shareAmount);
            releaseLuckyDrop.totalReleased = releaseLuckyDrop.totalReleased.add(shareAmount);
            releaseLuckyDrop.payees.push(account);
            releaseLuckyDrop.shareAmount.push(shareAmount);
            luckyDropIdToShareAmount[releaseLuckyDropId][account] = shareAmount;
            emit PaymentReleased(address(0), account, shareAmount, 1, releaseLuckyDropId, 0);
        }else if (luckyDropCategory == 2) {
            require(shareAmount > 0, "LuckyDrop: account is not due payment");
            IERC20(luckyDropTokenAddress).safeTransfer(account, shareAmount);
            releaseLuckyDrop.totalReleased = releaseLuckyDrop.totalReleased.add(shareAmount);
            releaseLuckyDrop.payees.push(account);
            releaseLuckyDrop.shareAmount.push(shareAmount);
            luckyDropIdToShareAmount[releaseLuckyDropId][account] = shareAmount;
            emit PaymentReleased(address(0), account, shareAmount, 2, releaseLuckyDropId, 0);
        } else if (luckyDropCategory == 3) {
            require(IERC165(luckyDropTokenAddress).supportsInterface(type(IERC721).interfaceId), "LuckyDrop:luckyDropTokenAddress must be ERC721");
            uint256 tokenId = releaseLuckyDrop.tokenId;
            IERC721(luckyDropTokenAddress).transferFrom(address(this), account, tokenId);
            releaseLuckyDrop.totalReleased = releaseLuckyDrop.totalReleased.add(shareAmount);
            releaseLuckyDrop.payees.push(account);
            releaseLuckyDrop.shareAmount.push(shareAmount);
            luckyDropIdToShareAmount[releaseLuckyDropId][account] = shareAmount;
            emit PaymentReleased(address(0), account, 1, 3, releaseLuckyDropId, tokenId);
        } else if (luckyDropCategory == 4) {
            require(IERC165(luckyDropTokenAddress).supportsInterface(type(IERC1155).interfaceId), "LuckyDrop:account must be ERC1155");
            uint256 tokenId = releaseLuckyDrop.tokenId;
            IERC1155(luckyDropTokenAddress).safeTransferFrom(address(this), account, tokenId, 1, abi.encode(msg.sender));
            releaseLuckyDrop.totalReleased = releaseLuckyDrop.totalReleased.add(shareAmount);
            releaseLuckyDrop.payees.push(account);
            releaseLuckyDrop.shareAmount.push(shareAmount);
            luckyDropIdToShareAmount[releaseLuckyDropId][account] = shareAmount;
            emit PaymentReleased(address(0), account, 1, 4, releaseLuckyDropId, tokenId);
        } else{
            revert("LuckyDrop:luckyDropCategory is wrong!");
        }
    }

    function reBackLuckyDrop(uint256 reBackLuckyDropId, address account) public {
        luckyDropInfo memory reBackLuckyDrop = luckyDropInfoMap[reBackLuckyDropId];
        require(reBackLuckyDrop.totalAmount != 0, "LuckyDrop: this luckyDrop is non-existent");
        require(reBackLuckyDrop.totalAmount >= reBackLuckyDrop.totalReleased, "LuckyDrop: this luckyDrop don't be reBack");
        address luckyDropTokenAddress = reBackLuckyDrop.tokenAddress;
        uint256 reBackluckyDropCategory = reBackLuckyDrop.luckyDropCategory;
        //reBackETH;
        if (reBackluckyDropCategory == 1) {
            uint256 reBackAmount = reBackLuckyDrop.totalAmount.sub(reBackLuckyDrop.totalReleased);
            require(reBackAmount != 0, "LuckyDrop: reBackAmount is not be zero");
            Address.sendValue(payable(account), reBackAmount);
            emit PaymentReBackReleased(address(0), account, reBackAmount, 1, reBackLuckyDropId, 0);
        }
        else if (reBackluckyDropCategory == 2) {
            uint256 reBackAmount = reBackLuckyDrop.totalAmount.sub(reBackLuckyDrop.totalReleased);
            require(reBackAmount != 0, "LuckyDrop: reBackAmount is not be zero");
            IERC20(luckyDropTokenAddress).safeTransfer(account, reBackAmount);
            emit PaymentReBackReleased(luckyDropTokenAddress, account, reBackAmount, 2, reBackLuckyDropId, 0);
        }
        else if (reBackluckyDropCategory == 3) {
            require(IERC165(luckyDropTokenAddress).supportsInterface(type(IERC721).interfaceId), "LuckyDrop:luckyDropTokenAddress must be ERC721!");
            uint256 tokenId = reBackLuckyDrop.tokenId;
            IERC721(luckyDropTokenAddress).transferFrom(address(this), account, tokenId);
            emit PaymentReBackReleased(luckyDropTokenAddress, account, tokenId, 3, reBackLuckyDropId, tokenId);
        }
        else if (reBackluckyDropCategory == 4) {
            require(IERC165(luckyDropTokenAddress).supportsInterface(type(IERC1155).interfaceId), "LuckyDrop:account must be ERC1155");
            uint256 tokenId = reBackLuckyDrop.tokenId;
            IERC1155(luckyDropTokenAddress).safeTransferFrom(address(this), account, tokenId, 1, abi.encode(msg.sender));
            emit PaymentReBackReleased(luckyDropTokenAddress, account, tokenId, 3, reBackLuckyDropId, tokenId);
        }else{
            revert("LuckyDrop:luckyDropCategory is wrong!");
        }

    }

    
    function getLuckyDropPayeeByIndex(uint256 LuckyDropIndex, uint256 index) public view returns (address) {
        return luckyDropInfoMap[LuckyDropIndex].payees[index];
    }

    function getLuckyDropShareAmountByAddress(uint256 LuckyDropIndex, address account) public view returns (uint256) {
        return luckyDropIdToShareAmount[LuckyDropIndex][account];
    }

    function getLuckyDropShareAmountByIndex(uint256 LuckyDropIndex, uint256 index) public view returns (uint256) {
        return luckyDropInfoMap[LuckyDropIndex].shareAmount[index];
    }

    function getLuckyDropTokenAddress(uint256 LuckyDropIndex) public view returns (address) {
        require(luckyDropInfoMap[LuckyDropIndex].luckyDropCategory != 0);
        return luckyDropInfoMap[LuckyDropIndex].tokenAddress;
    }

    function getLuckyDropTokenId(uint256 LuckyDropIndex) public view returns (uint256) {
        require(luckyDropInfoMap[LuckyDropIndex].luckyDropCategory != 0 || luckyDropInfoMap[LuckyDropIndex].luckyDropCategory != 1);
        return luckyDropInfoMap[LuckyDropIndex].tokenId;
    }

    function totalReleased(uint256 LuckyDropIndex) public view returns (uint256) {
        return luckyDropInfoMap[LuckyDropIndex].totalReleased;
    }

    function totalAmount(uint256 LuckyDropIndex) public view returns (uint256) {
        return luckyDropInfoMap[LuckyDropIndex].totalAmount;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os,) = payable(owner()).call{value : address(this).balance}('');
        require(os);
    }

    function kill() public onlyOwner{
        selfdestruct(payable(owner()));
    }

}