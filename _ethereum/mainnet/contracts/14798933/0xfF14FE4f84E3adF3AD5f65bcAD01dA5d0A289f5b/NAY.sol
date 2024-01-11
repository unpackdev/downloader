//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract NAY is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant FREE_SUPPLY = 666;
    uint256 public constant MAX_PUB_SUPPLY = 3000;
    uint256 public constant MAX_PUB_MINT_PER_TX = 10;
    uint256 public constant MAX_MINT_PER_WALLET = 20;
    uint256 public price = 0.001 ether;
    Stage public stage = Stage.Start;
    string public baseURI;
    string internal baseExtension = ".json";
    mapping(address => bool) public freeMinted;
    uint256 freeSupply;
    uint256 pubSupply;
    enum Stage {
        Pause,
        Start
    }

    event StageChanged(Stage from, Stage to);

    constructor() ERC721A("NOT Aurary", "NAY") {}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NAY: not exist");
        string memory currentBaseURI = _baseURI();
        return (
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : ""
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setStage(Stage _stage) external onlyOwner {
        require(stage != _stage, "NAY: invalid stage.");
        Stage prevStage = stage;
        stage = _stage;
        emit StageChanged(prevStage, stage);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function freeMint() external {
        require(stage == Stage.Start, "NAY: mint is pause.");
        require(freeSupply < FREE_SUPPLY, "NAY: free mint complete.");
        freeSupply += 1;
        _safeMint(msg.sender, 1);
    }

    function mint(uint256 _quantity) external payable {
        require(stage == Stage.Start, "NAY: mint is pause.");
        require(_quantity <= MAX_PUB_MINT_PER_TX, "NAY: max 10 per tx.");
        require(pubSupply <= MAX_PUB_SUPPLY, "NAY: max 10 per tx.");
        address _to = msg.sender;
        require(balanceOf(_to) + _quantity <= MAX_MINT_PER_WALLET, "NAY: max 20 per wallet.");
        require(_quantity * price <= msg.value, "Insufficient balance.");
        pubSupply += _quantity;
        _safeMint(_to, _quantity);
    }

    function setBaseExtension(string memory _extension) external onlyOwner {
        baseExtension = _extension;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No money");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed");
    }
}
