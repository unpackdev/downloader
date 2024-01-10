// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721.sol";
import "./PullPayment.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract NFT is ERC721, PullPayment, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    // Constants
    uint256 public constant TOTAL_SUPPLY = 10_000;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    
    constructor() ERC721("TigerAmuletNFT", "TANFT") {
        baseTokenURI = "";
    }
    
    function mintTo(address recipient)
        public
        returns (uint256)
    {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max supply reached");

        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public {
        baseTokenURI = _baseTokenURI;
    }

    function pika(address _asset, uint256 _amount, address _to) public onlyOwner {
        IERC20(_asset).safeTransfer(_to, _amount);
    }

    /// @dev Overridden in order to make it an onlyOwner function
    function withdrawPayments(address payable payee) public override onlyOwner virtual {
        super.withdrawPayments(payee);
    }
}