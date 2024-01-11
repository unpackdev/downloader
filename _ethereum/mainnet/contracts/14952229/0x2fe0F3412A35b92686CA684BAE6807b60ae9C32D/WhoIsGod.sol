// SPDX-License-Identifier: MIT

/////////////////////////
///// MINT DETAILS //////

// MINT 1 FOR FREE, .006/ea after
// 10/tx (you can include free in a transaction of multiple. so if you want to mint 8 and havent gotten your free ONLY pay for 7)
// REVEAL IS ON SELLOUT THE METADATA IS UPLOADED BUT DONT WANT TO PUSH THE CID AND HAVE SOMEONE TAKE IT

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Strings.sol";

contract WhoIsGod is ERC721A {
    using Strings for uint256;

    uint256 public maxSupply = 666;
    uint256 public price = .003 ether;

    string public cid = "QmfCTqTxBtpvKw6KBnp1yTYv5feYh61sTwAG9PnLUnvj4M";

    address public owner;
    bool public paused;
    bool public reveal;

    mapping(address => bool) public usedFree;

    constructor() ERC721A("Who is God", "GOD") {
        owner = msg.sender;
        _mint(msg.sender, 3);
    }

    function mint(uint256 quantity) external payable {
        require(!paused, "Sale paused");
        require(quantity <= 10, "tx limit is 10");
        require(totalSupply() + quantity <= maxSupply, "OOS");
        if (!usedFree[msg.sender]) {
            require(msg.value >= price * (quantity - 1));
            usedFree[msg.sender] = true;
        } else {
            require(msg.value >= price * quantity);
        }
        _mint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!reveal) return string(abi.encodePacked("ipfs://", cid));
        else
            return
                string(
                    abi.encodePacked(
                        "ipfs://",
                        cid,
                        "/",
                        tokenId.toString(),
                        ".json"
                    )
                );
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setCID(string memory _cid) external onlyOwner {
        cid = _cid;
    }

    function flipReveal() external onlyOwner {
        reveal = !reveal;
    }

    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    function toggleReveal(string memory _cid) external onlyOwner {
        cid = _cid;
        reveal = true;
    }

    function withdraw() external onlyOwner {
        (bool succ, ) = payable(owner).call{value: address(this).balance}("");
        require(succ, "Withdraw failed");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }
}
