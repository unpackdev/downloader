//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./ERC721A.sol";

contract RoyalAzuki is ERC721A {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public freeSupply = 250;
    uint256 public constant MAX_MINT_PER_TX = 10;
    uint256 public constant MAX_MINT_PER_TX_FREE = 5;
    uint256 public price = 0.015 ether;
    address public immutable owner;
    Stage public stage;
    string public baseURI;
    string internal baseExtension = ".json";
    address private constant WITHDRAW_ADDRESS =
        0xb4008a294609A9f1AF08188592dfFca0477658Cf;

    enum Stage {
        Pause,
        Public
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "RoyalAzuki: not owner");
        _;
    }

    event StageChanged(Stage from, Stage to);

    constructor() ERC721A("RoyalAzuki", "RAZK") {
        owner = _msgSender();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "RoyalAzuki: not exist");
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

    function setStage(Stage _stage) external onlyOwner {
        require(stage != _stage, "RoyalAzuki: invalid stage.");
        Stage prevStage = stage;
        stage = _stage;
        emit StageChanged(prevStage, stage);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setFreeSupply(uint256 _freeSupply) external onlyOwner {
        freeSupply = _freeSupply;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(uint256 _quantity) external payable {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + _quantity <= MAX_SUPPLY,
            "RoyalAzuki: exceed max supply."
        );
        if (stage == Stage.Public) {
            if (currentSupply < freeSupply) {
                require(
                    _quantity <= MAX_MINT_PER_TX_FREE,
                    "RoyalAzuki: too many free mint."
                );
            } else {
                require(
                    _quantity <= MAX_MINT_PER_TX,
                    "RoyalAzuki: too many mint."
                );
                require(
                    msg.value >= price * _quantity,
                    "RoyalAzuki: insufficient fund."
                );
            }
        } else {
            revert("RoyalAzuki: mint is pause.");
        }
        _safeMint(msg.sender, _quantity);
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No money");
        _withdraw(WITHDRAW_ADDRESS, ((balance * 24) / 100));
        _withdraw(msg.sender, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }
}
