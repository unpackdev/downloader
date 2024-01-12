pragma solidity ^0.8.11;

// SPDX-License-Identifier: MIT
// Copyright (C) 2022 Simplr

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./CollectionA.sol";

contract BALMigration is Ownable, Pausable, IERC721Receiver {
    uint256 public constant MAX_LIMIT = 20;
    uint256 public constant MAX_PURCHASE_LIMIT = 10;
    uint256 public immutable NEW_SUPPLY;
    CollectionA public bal;

    mapping(address => uint256) public tokensMintedByUser;

    /// @notice contructor that will be invoked when the contract is deployed
    /// @param _bal address of BAL contract
    constructor(CollectionA _bal, uint256 _newSupply) {
        bal = _bal;
        NEW_SUPPLY = _newSupply;
    }

    /// @notice pause BlockApeLads sale (main sale and presale)
    /// @dev uses Openzeppelin's Pausable.sol
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause BlockApeLads sale (main sale and presale)
    /// @dev uses Openzeppelin's Pausable.sol
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice sets new BAL contract address
    /// @dev BAL contract address cannot be zero address
    /// @param _bal address of BAL
    function setBALAddress(CollectionA _bal) external onlyOwner {
        require(address(_bal) != address(0), "Cannot be zero address");
        bal = _bal;
    }

    /// @notice method to buy from main sale
    /// @param _buyer address of buyer
    /// @param _quantity number of tokens to be bought
    function buy(
        bytes32[] calldata _proofs,
        address _buyer,
        uint256 _quantity
    ) external whenNotPaused {
        require(_quantity >= 1, "usless transaction to mint zero");
        require(_quantity <= MAX_PURCHASE_LIMIT, "Purchase limit reached");
        unchecked {
            require(
                totalSupply() + _quantity <= NEW_SUPPLY,
                "Maximum supply reached"
            );
            require(
                tokensMintedByUser[_buyer] + _quantity <= MAX_LIMIT,
                "out of buying limit"
            );
        }
        tokensMintedByUser[_buyer] += _quantity;
        _mint(_proofs, _buyer, _quantity);
    }

    function _mint(
        bytes32[] calldata _proofs,
        address _receiver,
        uint256 _quantity
    ) private {
        for (uint256 minted; minted < _quantity; minted = minted + 2) {
            uint256 remaining = _quantity - minted;
            if (remaining == 1) {
                bal.presaleBuy(_proofs, address(this), 1);
                bal.safeTransferFrom(
                    address(this),
                    _receiver,
                    bal.totalSupply()
                );
            } else {
                bal.presaleBuy(_proofs, address(this), 2);
                bal.safeTransferFrom(
                    address(this),
                    _receiver,
                    bal.totalSupply() - 1
                );
                bal.safeTransferFrom(
                    address(this),
                    _receiver,
                    bal.totalSupply()
                );
            }
        }
    }

    receive() external payable {
        revert("Cannot Receive funds");
    }

    // Contract cannot receive any ERC721 Token
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        if (from == address(0)) {
            return this.onERC721Received.selector;
        } else {
            return 0x00000000;
        }
    }

    function totalSupply() public view returns (uint256) {
        return bal.totalSupply();
    }
}
