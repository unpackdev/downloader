// SPDX-License-Identifier: MIT

/*
Only Flans - Sign up to support your favorite flans
*/

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract OnlyFlans is ERC721A("OnlyFlans", "ONLYFLAN"), Ownable, Pausable {
    using Strings for uint256;
    string public baseURI;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public freePerWallet = 1;
    uint256 public freeTotal = 1000;
    uint256 public price = 0.0069 ether;

    address private grandFlan = 0xB0430dd526Dd55eD262865dF7e7019371a124330;
    address private flanPhotog = 0xd45F75e7Ea7A4a6AbCBB84810102FDda4691D62b;
    address private nerdFlan = 0x2f046457Fa23C4bC3aA829f4e6BD2AA9C55bEa3d;

    bool public isPublicSaleActive;

    modifier onlyFlansSubscription(uint256 quantity) {
        require(price * quantity <= msg.value, "Incorrect ETH value sent");
        _;
    }

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier flansLeft(uint256 quantity) {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough remaining to mint"
        );
        _;
    }

    function freeMint(uint256 quantity)
        public
        payable
        flansLeft(quantity)
        publicSaleActive
    {
        require(
            _numberMinted(msg.sender) + quantity <= freePerWallet,
            "Free Limit Exceeded"
        );
        require(totalSupply() + quantity <= freeTotal, "Free Limit Exceeded");
        _mint(msg.sender, quantity);
    }

    function mint(uint256 quantity)
        public
        payable
        flansLeft(quantity)
        publicSaleActive
        onlyFlansSubscription(quantity)
    {
        _mint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity, address receiver)
        external
        onlyOwner
        flansLeft(quantity)
    {
        _mint(receiver, quantity);
    }

    /*
    =====   Admin Functions   =====
*/

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 amtOne = (balance * 43) / 100;
        uint256 amtTwo = (balance * 37) / 100;
        (bool callSuccess1, ) = payable(grandFlan).call{value: amtOne}("");
        require(callSuccess1, "Call failed");
        (bool callSuccess2, ) = payable(flanPhotog).call{value: amtTwo}("");
        require(callSuccess2, "Call failed");
        (bool callSuccess3, ) = payable(nerdFlan).call{
            value: address(this).balance
        }("");
        require(callSuccess3, "Call failed");
    }

    function updatePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function updateFree(uint256 quantity) external onlyOwner {
        freePerWallet = quantity;
    }

    function updateFreeTotal(uint256 quantity) external onlyOwner {
        require(quantity <= MAX_SUPPLY, "Cannot exceed max");
        freeTotal = quantity;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }
}
