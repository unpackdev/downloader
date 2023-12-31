/*
@author Oleg Dubinkin <odubinkin@gmail.com>
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract GiftWraps is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Wrap {
        address tokenAddress;
        uint256 amount;
        string secondaryMetadata;
    }

    mapping(uint256 => Wrap) private wraps;

    uint256 public fee;
    address public feeReceiver;

    constructor() ERC721("GiftWraps", "GW") {
        feeReceiver = msg.sender;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function mint(
        address recipient,
        string memory primaryMetadata,
        string memory secondaryMetadata,
        address tokenAddress,
        uint256 amount
    ) external payable {
        require(msg.value == fee, "Incorrect fee amount");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Transfer of ERC20 tokens failed");

        payable(feeReceiver).transfer(fee);

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, primaryMetadata);

        wraps[newTokenId] = Wrap({
            tokenAddress: tokenAddress,
            amount: amount,
            secondaryMetadata: secondaryMetadata
        });
    }

    function claim(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only the owner can claim");

        Wrap memory wrap = wraps[tokenId];
        require(IERC20(wrap.tokenAddress).transfer(msg.sender, wrap.amount), "Transfer of ERC20 tokens failed");

        wraps[tokenId].amount = 0;
        if(bytes(wrap.secondaryMetadata).length > 0) {
            _setTokenURI(tokenId, wrap.secondaryMetadata);
        }
    }

    function getTokenInfo(uint256 tokenId) external view returns (address, uint256) {
        require(_exists(tokenId), "Token does not exist");
        Wrap memory wrap = wraps[tokenId];
        return (wrap.tokenAddress, wrap.amount);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    mapping(uint256 => string) private _tokenURIs;
}
