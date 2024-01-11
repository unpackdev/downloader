// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract XmetaPoint is ERC721A, Ownable {
    using Strings for uint256;
    enum Status {
        Waiting,
        Started,
        Finished,
        AllowListOnly
    }

    Status public status;
    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 2;
    uint256 public constant MAX_SUPPLY = 666;
    uint256 public constant PRICE = 0.05 * 10**18; // 0.05 ETH

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("XmetaPoint", "XmetaPoint") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(status == Status.Started, "XmetaPoint: It's not on sale yet.");
//        require(tx.origin == msg.sender, "XmetaPoint: Bu yun xu he yue diao yong.");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "XmetaPoint: The individual purchase limit is reached."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "XmetaPoint: The maximum quantity is reached."
        );

        _safeMint(msg.sender, quantity);
        refundIfOver(PRICE * quantity);

        emit Minted(msg.sender, quantity);
    }


    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "GCLX: The value is not enough.");
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
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "XmetaPoint: Withdraw success.");
    }
}
