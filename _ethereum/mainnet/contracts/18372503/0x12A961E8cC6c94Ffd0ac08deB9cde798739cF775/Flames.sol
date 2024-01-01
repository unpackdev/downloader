// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Strings.sol";

contract Flames is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 1000;

    IERC20 public immutable paymentToken;
    address public feeAddress;
    uint256 public fee = 100000 * 10 ** 18;
    uint256 public batchLimit = 2;
    uint256 public maxPerWallet = 2;

    uint256 private _totalMinted;
    string private _baseTokenURI;

    constructor(
        address initialOwner,
        address initialFeeAddress,
        address tokenAddress
    ) ERC721("Flames", "FLAME") Ownable(msg.sender) {
        require(
            initialFeeAddress != address(0),
            "Fee address cannot be zero address"
        );
        feeAddress = initialFeeAddress;
        paymentToken = IERC20(tokenAddress);
        _setBaseURI(
            "ipfs://bafybeieokkbwo2hp3eqkfa5chypmevxjii275icwxnuc7dmuexi3qsuvu4/"
        );
        _transferOwnership(initialOwner);
    }

    // set base uri
    function _setBaseURI(string memory baseURI) private {
        _baseTokenURI = baseURI;
    }

    // retrieve base uri
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // mint
    function mint(uint256 quantity) external {
        require(msg.sender == tx.origin, "Caller is contract");
        require(quantity > 0, "Quantity cannot be zero");
        require(quantity <= batchLimit, "Exceeds batch limit");
        require(_totalMinted + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(
            balanceOf(msg.sender) + quantity <= maxPerWallet,
            "Exceeds max per wallet"
        );

        uint256 tokenId;
        for (uint256 index = 0; index < quantity; index++) {
            tokenId = _totalMinted++;
            _mint(msg.sender, tokenId);
            _setTokenURI(tokenId, Strings.toString(tokenId));
        }

        bool success = paymentToken.transferFrom(
            msg.sender,
            feeAddress,
            fee * quantity
        );
        require(success, "Token transfer failed");
    }

    // total supply minted
    function totalSupply() public view returns (uint256) {
        return _totalMinted;
    }

    // set fee (only owner)
    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    // set the receiver address (only owner)
    function setFeeAddress(address newFeeAddress) external onlyOwner {
        require(
            newFeeAddress != address(0),
            "Fee address cannot be zero address"
        );
        feeAddress = newFeeAddress;
    }

    // set the maximum number of nfts per wallet (only owner)
    function setMaxPerWallet(uint256 newMaxMint) external onlyOwner {
        require(
            newMaxMint < MAX_SUPPLY,
            "Max mint per wallet exceeds max supply"
        );
        maxPerWallet = newMaxMint;
    }

    // set batch limit (only owner)
    function setBatchLimit(uint256 newLimit) external onlyOwner {
        require(
            newLimit <= 100,
            "Batch limit exceeds maximum allowed"
        );
        require(newLimit <= maxPerWallet, "Batch limit exceeds max mint per wallet");
        batchLimit = newLimit;
    }

    // withdraw tokens from contract (only owner)
    function withdrawTokens(
        address tokenAddress,
        address receiverAddress
    ) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        return tokenContract.transfer(receiverAddress, amount);
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
