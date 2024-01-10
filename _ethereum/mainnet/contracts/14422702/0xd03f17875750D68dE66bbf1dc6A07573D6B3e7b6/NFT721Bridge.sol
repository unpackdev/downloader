// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

import "./INFT721Bridge.sol";
import "./IERC721Mintable.sol";
import "./IERC721Receiver.sol";

contract NFT721Bridge is Ownable, Pausable, ReentrancyGuard, INFT721Bridge, IERC721Receiver {
    using SafeMath for uint256;

    address[] nft721List;
    mapping(address => NFT721FeeInfo) nft721Fee;
    mapping(address => mapping(bytes32 => bool)) nft721Vault;
    
    constructor () {
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        require(_nft721TokenRegistered(msg.sender), "token not registered");
        require(IERC721Mintable(msg.sender).ownerOf(tokenId) == address(this), "token not received");

        bytes32 tokenSig = keccak256(abi.encodePacked(_getChainId(), msg.sender, tokenId));
        require(tokenSig == keccak256(data), "token sig should be the same");

        nft721Vault[msg.sender][tokenSig] = true;

        return this.onERC721Received.selector;
    }

    function addNFT721Token(address token, NFT721FeeInfo memory feeInfo) external override onlyOwner {
        require(!_nft721TokenRegistered(token), "token registered");

        nft721List.push(token);
        nft721Fee[token] = feeInfo;

        emit NFT721TokenAdded(token);
        emit NFT721FeeUpdated(token, feeInfo.feeAmount, feeInfo.volatilityCoefficient);
    }

    function updateNFT721TokenFee(address token, NFT721FeeInfo memory feeInfo) external override onlyOwner {
        require(_nft721TokenRegistered(token), "token not registered");

        nft721Fee[token] = feeInfo;
        emit NFT721FeeUpdated(token, feeInfo.feeAmount, feeInfo.volatilityCoefficient);
    }

    function removeNFT721Token(address token) external override onlyOwner {
        require(_nft721TokenRegistered(token), "token not registered");

        uint8 index = 0;
        for (uint8 i = 0; i < nft721List.length; i++) {
            if (nft721List[i] == token) {
                index = i;
            }
        }
        address[] memory newNFT721List = new address[](nft721List.length-1);
        for (uint8 j = 0; j < newNFT721List.length; j++) {
            if (j < index) {
                newNFT721List[j] = nft721List[j];
            } else {
                newNFT721List[j] = nft721List[j + 1];
            }
        }
        nft721List = newNFT721List;

        emit NFT721TokenRemoved(token);
    }

    function estimateFee(address token) public view override returns (uint256) {
        require(_nft721TokenRegistered(token), "token not registered");

        return nft721Fee[token].feeAmount.mul(nft721Fee[token].volatilityCoefficient).div(100);
    }

    function estimateFee(address token, uint256 amount) public view override returns (uint256) {
        return estimateFee(token).mul(amount);
    }


    function attachNFT721(address token, uint256 tokenId) public payable override whenNotPaused {
        require(msg.value >= estimateFee(token), "not enough fee");

        _attachNFT721(token, tokenId);
        payable(address(this)).transfer(msg.value);

        emit NFT721Attached(token, msg.sender, tokenId);
    }

    function attachNFT721Batch(address token, uint256[] memory tokenIds) public payable override whenNotPaused {
        require(msg.value >= estimateFee(token, tokenIds.length), "not enough fee");
        require(tokenIds.length > 0, "should provide tokenIds");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _attachNFT721(token, tokenIds[i]);
        }
        payable(address(this)).transfer(msg.value);

        emit NFT721AttachedBatch(token, msg.sender, tokenIds);
    }

    function detachNFT721(address token, address to, uint256 tokenId) external override onlyOwner whenNotPaused {
        _detachNFT721(token, to, tokenId);

        emit NFT721Detached(token, to, tokenId);
    }
    
    function detachNFT721Batch(address token, address to, uint256[] memory tokenIds) external override onlyOwner whenNotPaused {
        require(tokenIds.length > 0, "should provide tokenIds");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _detachNFT721(token, to, tokenIds[i]);
        }

        emit NFT721DetachedBatch(token, to, tokenIds);
    }

    function _nft721TokenRegistered(address token) private view returns (bool registered) {
        for (uint8 i = 0; i < nft721List.length; i++) {
            if (nft721List[i] == token) {
                registered = true;
            }
        }
    }

    function _attachNFT721(address token, uint256 tokenId) private nonReentrant {
        require(_nft721TokenRegistered(token), "token contract not registered");
        require(IERC721Mintable(token).isApprovedForAll(msg.sender, address(this)) || IERC721Mintable(token).getApproved(tokenId) == address(this), "should approve first");
        require(IERC721Mintable(token).ownerOf(tokenId) == msg.sender, "sender should own the token");

        bytes memory data = abi.encodePacked(
            _getChainId(),
            token,
            tokenId
        );
        IERC721Mintable(token).safeTransferFrom(msg.sender, address(this), tokenId, data);
        require(nft721Vault[token][keccak256(data)], "nft attach in vault failure");
    }

    function _detachNFT721(address token, address to, uint256 tokenId) private nonReentrant {
        require(_nft721TokenRegistered(token), "token contract not registered");

        try IERC721Mintable(token).ownerOf(tokenId) returns (address owner) { 
            require(owner == address(this), "vault should own the token");
            IERC721Mintable(token).safeTransferFrom(address(this), to, tokenId);
        } catch(bytes memory) {
            IERC721Mintable(token).mint(to, tokenId);
        }
        // delete nft721Vault[token][keccak256(abi.encodePacked(_getChainId(), token, tokenId))];
    }

    function _getChainId() private view returns (uint256) {
        uint256 chainId = block.chainid;
        // assembly {
        //     chainId := chainid()
        // }
        return chainId;
    }

    function emergencyWithdrawNFT(address token, uint256 tokenId) public override onlyOwner {
        IERC721Mintable(token).transferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawFee(address settler) public override onlyOwner {
        payable(settler).transfer(address(this).balance);
    }

    receive() external payable {}
}