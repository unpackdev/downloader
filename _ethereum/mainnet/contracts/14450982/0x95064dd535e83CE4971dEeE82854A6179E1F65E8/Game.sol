// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol"; 

import "./IERC1155Receiver.sol";
import "./IERC721.sol";

import "./IERC1155.sol";
import "./Ownable.sol";

/// @author Santiago Del Valle <sdelvalle57@gmail.com>
contract Game is Ownable, IERC1155Receiver { 

    using SafeMath for uint256;

    event NewWinner(address indexed _winner, uint256 tokenId);

    IERC721 public groupies;
    IERC1155 public tokenERC1155;

    bytes32 private _solution;

    uint256 private _tokenId;
    uint8 private _x;
    uint8 private _y;

    bool private _paused;

    mapping(address => bool) public walletHasPlayed;

    constructor(address groupies_, address tokenERC1155_, address owner_) Ownable(owner_) {
        groupies = IERC721(groupies_);
        tokenERC1155 = IERC1155(tokenERC1155_);
    }

    /****************Setters****************** */
    function setGameParams(uint8 x_, uint8 y_, uint256 tokenId_, string memory solution_) external onlyOwner {
        _x = x_;
        _y = y_;
        _tokenId = tokenId_;
        _solution = sha256(abi.encode(solution_));
    }

    function setERC1155Address(address tokenERC1155_) external onlyOwner {
        tokenERC1155 = IERC1155(tokenERC1155_);
    }

    function pauseGame(bool pause_) external onlyOwner {
        _paused = pause_; 
    }

    /***************Getters *******************/
    function getGameParams() external view returns (uint8, uint8, uint256) {
        return (
            _x, 
            _y,
            _tokenId
        );
    }

    /**************Game Logic****************/
    function transferERC1155(address to_, uint256 tokenId_, uint256 amount_) external onlyOwner {
        tokenERC1155.safeTransferFrom(address(this), to_, tokenId_, amount_, "");
    }

    function claimTokenWithSolution(string memory incomingSolution_) public {
        require(!_paused, "Game is paused");
        require(groupiesBalanceOf(_msgSender()) > 0, "No groupies balance");
        require(!walletHasPlayed[_msgSender()], "Wallet has already played");

        require(_solution == sha256(abi.encode(incomingSolution_)), "Wrong solution");
        walletHasPlayed[_msgSender()] = true;

        tokenERC1155.safeTransferFrom(address(this), _msgSender(), _tokenId, 1, "");
        emit NewWinner(_msgSender(), _tokenId);
    }

    function groupiesBalanceOf(address account_) public view returns (uint256) {
        return groupies.balanceOf(account_);
    }

    /**********Support for TokenERC1155 when transfering a token to this contract */
    function onERC1155Received(
        address /* operator */,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    } 

    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external override pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4 /*interfaceId*/) external override pure returns (bool) {
        return false;
    }

}