// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721URIStorage.sol";
import "./IMarket.sol";

contract PrismNFT is ERC721URIStorage, Ownable, Pausable {
    IMarket private _market;
    uint256 private _tokenIds;

    mapping(uint256 => address) private tokenToCreator;

    function creatorToken(uint256 tokenId) external view returns (address) {
        return tokenToCreator[tokenId];
    }

    function market() external view returns (address) {
        return address(_market);
    }

    function tokenIds() external view returns (uint256) {
        return _tokenIds;
    }

    constructor(address market_) ERC721("PRISM", "PRISM") {
        _market = IMarket(market_);
    }

    function mintNFT(address recipient, string memory tokenURI) external returns (uint256) {
        _tokenIds++;
        tokenToCreator[_tokenIds] = recipient;
        _mint(recipient, _tokenIds);
        _setTokenURI(_tokenIds, tokenURI);
        setApprovalForAll(owner(), true);
        return _tokenIds;
    }

    function pause() external onlyOwnerOrMarket returns (bool) {
        _pause();
        return true;
    }

    function unpause() external onlyOwnerOrMarket returns (bool) {
        _unpause();
        return true;
    }

    function setMarket(address newMarket) external onlyOwnerOrMarket returns (bool) {
        _market = IMarket(newMarket);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);
        bool result = _market.resolveDeal(tokenId, from, to);
        require(result, "Recipient not buyer");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(msg.sender.code.length == 0, "Sender is contract");
        require(to.code.length == 0, "Recipient is contract");
        require(!paused(), "Pausable: token transfer while paused");
    }

    modifier onlyOwnerOrMarket() {
        address sender = msg.sender;
        require(address(_market) == sender || owner() == sender, "Invalid sender");
        _;
    }
}
