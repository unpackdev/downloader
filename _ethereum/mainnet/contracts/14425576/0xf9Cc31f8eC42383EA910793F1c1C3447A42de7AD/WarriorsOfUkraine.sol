// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0 < 0.9.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract WarriorsOfUkraine is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public name = "Warriors Of Ukraine";
    string public symbol = "WOU";
    string public baseURI = "ipfs://QmbZvhhxXDDm9BqRfGqM4bFS8htGnQSBFWaUGWmxTkkjCo/";

    uint private counter;
    uint public supply;
    uint256 public constant PRICE = 0.05 ether;

    uint32 public constant ARTWORK = 24;
    uint32 public constant SUPPLY_MAX = 12001;

    constructor() ERC1155(baseURI) {
        for (uint i=1; i<26; i++) {
            _mint(msg.sender, i, 1, "");   
        }
    }

    function mint(uint32 quantity) external payable nonReentrant {
        require(quantity > 0, "Quantity needs to be more than 0.");
        require(msg.value >= PRICE * quantity, "Insufficient eth sent.");
        require(supply + quantity <= SUPPLY_MAX, "Exceeds the maximum allowed supply.");

        supply += quantity;

        uint i;
        for (i=0; i<quantity; i++) {
            uint tkId = (counter % ARTWORK) + 1; // Equal distribution.
            _mint(msg.sender, tkId, 1, "");
            counter++;
        }
    }

    function mintForAddress(
        address to,
        uint32 id,
        uint32 quantity      
    ) external onlyOwner {
        supply += quantity;
        _mint(to, id, quantity, "");
    }

    function batchMintForAddress(
        address[] calldata to,
        uint32 id,
        uint256[] calldata quantity      
    ) external onlyOwner {
        uint i;
        for (i=0; i<quantity.length; i++) {
            supply += quantity[i];
            _mint(to[i], id, quantity[i], "");
        }
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function withdraw() external onlyOwner {
        payable(address(0x165CD37b4C644C2921454429E7F9358d18A45e14)).transfer(address(this).balance * 95/100); // 95% to Ukraine Crypto Wallet.
        payable(msg.sender).transfer(address(this).balance); // Remaining 5% to the Artists.
    }
}