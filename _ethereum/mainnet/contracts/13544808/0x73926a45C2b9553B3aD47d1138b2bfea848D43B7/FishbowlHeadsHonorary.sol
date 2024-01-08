//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";

contract FishbowlHeadsHonorary is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant _maxSupply = 999;

    string private baseURI;

    event Receive(uint256);
    event Fallback(bytes,uint256);
    event honorEvent(address, uint256);

    constructor() ERC721("Fishbowl Heads Honorary", "FBHH") {
    }

    function honorMint(address minter, uint256 tokenCount) public onlyOwner {
      require(tokenCount > 0, "No. of tokens <= zero");
      require(_tokenIds.current() + tokenCount <= _maxSupply, "Max count reached");

      for (uint256 i = 0; i < tokenCount; i++) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(minter, newItemId);
      }
      emit honorEvent(minter, tokenCount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function withdraw() external onlyOwner {
        uint256 amt = address(this).balance;
        (bool sent, ) = payable(msg.sender).call{value: amt}("");
        require(sent, "Failed to send Ether");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        emit Receive(msg.value);
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        emit Fallback(msg.data, msg.value);
    }

    // --- recovery of tokens sent to this address

    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}
