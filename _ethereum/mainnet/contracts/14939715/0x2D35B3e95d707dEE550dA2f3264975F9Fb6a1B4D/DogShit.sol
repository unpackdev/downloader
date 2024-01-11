//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Strings.sol";
import "./ERC721A.sol";

// WOOF WOOF!

contract DogShit is ERC721A {
    using Strings for uint256;

    modifier onlyOwner() {
        require(owner == _msgSender(), "DogShit: not owner");
        _;
    }

    event StageChanged(Stage from, Stage to);

    enum Stage {
        Pause,
        Public
    }

    Stage public stage;

    address public immutable owner;
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public freeSupply = 2000;
    uint256 public price = 0.005 ether;
    uint256 public constant MAX_MINT_PER_WALLET_FREE = 1;
    uint256 public constant MAX_MINT_PER_TX = 10;

    mapping(address => bool) public addressFreeMinted;

    string public baseURI;
    string internal baseExtension = ".json";

    constructor() ERC721A("DogShit", "DS") {
        owner = _msgSender();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "DogShit: not exist");
        string memory currentBaseURI = _baseURI();
        return (
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : ""
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _quantity) external payable {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + _quantity <= MAX_SUPPLY,
            "DogShit: exceed max supply."
        );
        if (stage == Stage.Public) {
            require(_quantity <= MAX_MINT_PER_TX, "DogShit: too many mint.");
            require(
                msg.value >= price * _quantity,
                "DogShit: insufficient fund."
            );
        } else {
            revert("DogShit: mint is pause.");
        }
        _safeMint(msg.sender, _quantity);
    }

    // The function can only be called ONCE
    function freeMint(uint256 _quantity) external {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + _quantity <= MAX_SUPPLY,
            "DogShit: exceed max supply."
        );
        require(
            addressFreeMinted[msg.sender] == false,
            "DogShit: already free minted"
        );
        if (stage == Stage.Public) {
            if (currentSupply < freeSupply) {
                require(
                    _quantity <= MAX_MINT_PER_WALLET_FREE,
                    "DogShit: too many free mint per tx."
                );
            } else {
                revert("DogShit: free mint it out");
            }
        } else {
            revert("DogShit: mint is pause.");
        }
        addressFreeMinted[msg.sender] = true;
        _safeMint(msg.sender, _quantity);
    }

    function setStage(Stage newStage) external onlyOwner {
        require(stage != newStage, "DogShit: invalid stage.");
        Stage prevStage = stage;
        stage = newStage;
        emit StageChanged(prevStage, stage);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setFreeSupply(uint256 newFreeSupply) external onlyOwner {
        freeSupply = newFreeSupply;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No money");
        _withdraw(msg.sender, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}
