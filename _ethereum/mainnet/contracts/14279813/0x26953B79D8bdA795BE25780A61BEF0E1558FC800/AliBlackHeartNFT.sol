// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721A.sol";

contract AliBlackHeartNFT is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished
    }

    Status public status;
    string public baseURI;
    uint256 public mintedCount = 0;
    uint256 public mintedBlocktime = 0;
    uint256 public constant MAX_MINT_PER_ADDR = 5;
    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant PRICE = 0.03 * 10**18; // 0.03 ETH

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);
    event Payback(address user, uint256 tokenId);

    constructor(string memory initBaseURI) ERC721A("AliBlackHeartNFT", "ABH") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(status == Status.Started, "ABH: Not begin");
        require(tx.origin == msg.sender, "ABH: Not contract call");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "ABH: Exceeds the maximum mint amount of a single wallet"
        );
        require(
            mintedCount + quantity <= MAX_SUPPLY,
            "ABH: Exceeded max mint range"
        );

        _safeMint(msg.sender, quantity);
        refundIfOver(PRICE * quantity);
        if (mintedCount == 0) {
            mintedBlocktime = block.timestamp;
        }
        mintedCount += quantity;

        emit Minted(msg.sender, quantity);
    }

    function payback(uint256 tokenId) public {
        require(tx.origin == msg.sender, "ABH: Not contract call");
        require(ownerOf(tokenId) == msg.sender, "ABH: Not the owner");
        require(address(this).balance >= PRICE, "ABH: Not enough balance");
        transferFrom(address(msg.sender), address(this), tokenId);
        _burn(tokenId);
        payable(msg.sender).transfer(PRICE);

        emit Payback(address(msg.sender), tokenId);
    }

    function paybackMore(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 cid = tokenIds[i];
            payback(cid);
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "ABH: Insufficient eth");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function withdraw(address payable recipient) external onlyOwner {
        require(mintedBlocktime != 0, "ABH: Don't start");
        require(
            block.timestamp - mintedBlocktime > 30 days,
            "ABH: In lock time"
        );
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "ABH: Run");
    }
}
