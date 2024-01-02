// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./IProxyRegistry.sol";


contract TarsilaNft is Ownable, ERC721Enumerable {
    using Strings for uint256;

    uint256[] public metadataIds;
    string public baseUri = "https://api.zeitls.io/tarsila/variations/";
    uint256 public mintPrice = 0.3 ether;

    IProxyRegistry public immutable proxyRegistry;

    event TokensCreated(uint256[] tokenIds, address indexed owner);
    event TokenBurned(uint256 indexed tokenId);

    constructor(address owner, IProxyRegistry _proxyRegistry) ERC721("Tarsila Reimagined", "TDA") {
        _transferOwnership(owner);
        proxyRegistry = _proxyRegistry;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    function mint(address target, uint256[] calldata ids) payable external {
        require(ids.length > 0, "Invalid ids list");
        if (owner() != _msgSender()) {
            require(msg.value >= mintPrice * ids.length, "Not enough eth sent.");
        }
        require(totalSupply() + ids.length <= 225, "Invalid token count");
        for (uint i = 0; i < ids.length; i++) {
            _safeMint(target, ids[i]);
        }
        emit TokensCreated(ids, target);
    }

    function exists(uint tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (address(proxyRegistry) != address(0x0) && proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string memory newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }

    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        uint256 balance = _tokenContract.balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        _tokenContract.transfer(msg.sender, balance);
    }

    function withdrawETH(address _wallet, uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        require(balance >= amount, "Not enough funds");
        address payable to = payable(_wallet);
        to.transfer(amount);
    }

    function approveERC721(IERC721 _tokenContract) external onlyOwner {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }

    fallback() external payable {}

    receive() external payable {}
}