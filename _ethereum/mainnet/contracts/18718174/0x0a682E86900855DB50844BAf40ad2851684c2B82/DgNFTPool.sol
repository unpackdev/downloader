// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./INFTPoolInterface.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./ERC721Burnable.sol";

contract DgNFTPool is INFTPoolInterface, ERC721Holder, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    address private tokenAddress;
    address private nftAddress;

    EnumerableSet.UintSet private nftIds;
    uint256 constant public rate = 1E18;

    bool private isNFT2Token = true;
    bool private isToken2NFT = true;

    uint256 private unlocked = 1;

    event NFT2Token(
        address token,
        address user,
        uint256 amount
    );

    event Token2NFT(
        address nft,
        address user,
        uint256[] nfts
    );

    constructor(address _tokenAddress, address _nftAddress) {
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
    }

    modifier lock() {
        require(unlocked == 1, 'NFTPool: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function addNftIds(uint256[] memory ids) public onlyOwner {
        require(ids.length > 0, 'Error: ids');
        IERC721 nft = IERC721(nftAddress);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (!nftIds.contains(id) && nft.ownerOf(id) == address(this)) {
                nftIds.add(id);
            }
        }
    }

    function addNfts(uint256[] memory ids) public onlyOwner {
        require(ids.length > 0, 'Error: ids');
        IERC721 nft = IERC721(nftAddress);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (!nftIds.contains(id) && nft.ownerOf(id) == msg.sender) {
                nft.safeTransferFrom(msg.sender, address(this), id);
                nftIds.add(id);
            }
        }
    }

    function setNFT2Token(bool _isNFT2Token) onlyOwner public {
        isNFT2Token = _isNFT2Token;
    }

    function setToken2NFT(bool _isToken2NFT) onlyOwner public {
        isToken2NFT = _isToken2NFT;
    }

    function burnBatch(uint256[] memory ids) onlyOwner lock public {
        ERC721Burnable nft = ERC721Burnable(nftAddress);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (nft.ownerOf(id) == address(this)) {
                nft.burn(id);
                nftIds.remove(id);
            }
        }
    }

    function withdrawNFTs(uint256[] memory ids) onlyOwner lock public {
        require(ids.length > 0,'Error: ids length 0');
        IERC721 nft = ERC721(nftAddress);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (nft.ownerOf(id) == address(this)) {
                nft.safeTransferFrom(address(this), _msgSender(), id);
                nftIds.remove(id);
            }
        }
    }

    function withdrawToken(uint256 amount) onlyOwner lock public {
        require(amount > 0, 'Error: amount 0');
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, 'Error: balance 0');
        if (balance < amount) amount = balance;
        token.safeTransfer(_msgSender(), amount);
    }

    function nftList() public view returns (uint256[] memory nfts) {
        nfts = new uint256[](nftIds.length());
        for (uint256 i = 0; i < nftIds.length(); ++i) {
            nfts[i] = nftIds.at(i);
        }
    }

    function token2Nft(uint256 amount, uint256[] memory nfts) lock override external returns (uint256[] memory) {
        require(isToken2NFT, 'Paused');
        require(amount <= rate.mul(50) && amount >= rate, '50 >= amt >= 1');
        require(amount.mod(rate) == 0, 'amt decimal');
        uint256 nftCount = amount.div(rate);
        require(nftCount <= nftIds.length(), 'Insufficient');

        IERC721 nft = IERC721(nftAddress);
        uint256[] memory ids = new uint256[](nftCount);
        if (nfts.length > 0) {
            require(nftCount == nfts.length, 'amt != nfts');
            for (uint256 i = 0; i < nftCount; i++) {
                require(nftIds.remove(ids[i] = nfts[i]), 'Not exist');
                nft.safeTransferFrom(address(this), msg.sender, ids[i]);
            }
        } else {
            for (uint256 i = nftCount.sub(1);; i--) {
                nftIds.remove(ids[i] = nftIds.at(i));
                nft.safeTransferFrom(address(this), msg.sender, ids[i]);
                if (i == 0) {
                    break;
                }
            }
        }
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        require(token.balanceOf(address(this)) - balance >= amount, 'amount error');
        emit Token2NFT(nftAddress, msg.sender, ids);
        return ids;
    }

    function nft2Token(uint256[] memory nfts) lock override external returns (uint256 amount) {
        require(isNFT2Token, 'Paused');
        require(nfts.length > 0 && nfts.length <= 50, '0 < nfts <= 50');
        IERC20 token = IERC20(tokenAddress);
        amount = rate.mul(nfts.length);
        require(token.balanceOf(address(this)) >= amount, 'Insufficient tokens');
        IERC721 nft = IERC721(nftAddress);
        for (uint256 i = 0; i < nfts.length; i++) {
            nft.safeTransferFrom(msg.sender, address(this), nfts[i]);
            nftIds.add(nfts[i]);
        }
        token.safeTransfer(msg.sender, amount);
        emit NFT2Token(tokenAddress, msg.sender, amount);
    }

}
