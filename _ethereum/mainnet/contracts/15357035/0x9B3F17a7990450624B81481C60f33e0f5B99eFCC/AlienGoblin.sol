// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC721A.sol";

contract AlienGoblin is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished,
        AllowListOnly
    }

    Status public status;
    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 3;
    uint256 public constant STARTID = 1;
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant PRICE = 0.00000 * 10**18; // 0.000 ETH

    mapping(address => uint256) public allowlist;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("AlienGoblin", "AlienGoblin") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256 startid){
        return STARTID;
    }

    function mint(uint256 quantity) external payable {
        require(status == Status.Started, "AlienGoblin: Not yet started.");
        require(tx.origin == msg.sender, "AlienGoblin: Contract call is not allowed.");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "AlienGoblin: MAX 3."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "AlienGoblin: Not so much."
        );

        _safeMint(msg.sender, quantity);
        refundIfOver(PRICE * quantity);

        emit Minted(msg.sender, quantity);
    }

    function allowlistMint(uint256 quantity) external payable {
        require(allowlist[msg.sender] > 0, "AlienGoblin: Not on the white list.");
        require(
            status == Status.Started || status == Status.AllowListOnly,
            "AlienGoblin: Not yet started."
        );
        require(tx.origin == msg.sender, "AlienGoblin: Contract call is not allowed.");
        require(quantity <= allowlist[msg.sender], "AlienGoblin: So many are not allowed.");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "AlienGoblin: Not so much."
        );
        allowlist[msg.sender] = allowlist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(PRICE * quantity);

        emit Minted(msg.sender, quantity);
    }

    function seedAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(addresses.length == numSlots.length, "AlienGoblin: Address error.");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "AlienGoblin: No more ETH.");
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
        require(success, "AlienGoblin: SOLD OUT.");
    }

    function teamMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "AlienGoblin: Not so much."
        );

        _safeMint(msg.sender, quantity);
        refundIfOver(PRICE * quantity);

        emit Minted(msg.sender, quantity);
    }
}
