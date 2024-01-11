//SPDX-License-Identifier: MIT

//by : stormwalkerz ⭐️

pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface iOrigamasks {
    function mintGift(address to_) external;
}

contract LuckyGift is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable, ReentrancyGuard {
    // Project
    string public name;
    string public symbol;
    string public tokenUri;
    uint256 constant TOKEN_ID = 1;

    // Authorized
    address public origamasksAddress; 
    bool public claimActive = false;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) 
        ERC1155("")
    {
        name = name_;
        symbol = symbol_;
        tokenUri = uri_;
    }

    // MODIFIERS
    modifier isUser {
        require(msg.sender == tx.origin, "Disable from SC"); _;
    }

    // AIRDROP
    function airdropGift(address to_, uint256 amount_) external onlyOwner { 
        _mint(to_, TOKEN_ID, amount_, "");
    }
    function airdropManyGifts(address[] memory tos_, uint256[] memory amounts_) external onlyOwner { 
        require(tos_.length == amounts_.length, "Length mismatch!");
        for (uint256 i = 0; i < tos_.length; i++) {
            _mint(tos_[i], TOKEN_ID, amounts_[i], "");
        }
    }

    // CLAIM
    function setClaimStatus(bool bool_) external onlyOwner {
        claimActive = bool_;
    }
    function claimGift() external nonReentrant isUser {
        require(origamasksAddress != address(0x0), "Origamasks address not set yet");
        require(claimActive, "Claim is not enabled at this time");
        require(balanceOf(msg.sender, TOKEN_ID) > 0, "You don't own the token");
        burn(msg.sender, TOKEN_ID, 1);
        iOrigamasks origamasksContract = iOrigamasks(origamasksAddress);
        origamasksContract.mintGift(msg.sender);
    }

    // OWNER
    function setTokenUri(string calldata newUri_) public onlyOwner {
        tokenUri = newUri_;
    }
    function setOrigamasksAddress(address origamasksAddress_) external onlyOwner {
        origamasksAddress = origamasksAddress_;
    }
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    // OVERRIDE
    function uri(uint256) public view virtual override returns (string memory) {
        return tokenUri;
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
