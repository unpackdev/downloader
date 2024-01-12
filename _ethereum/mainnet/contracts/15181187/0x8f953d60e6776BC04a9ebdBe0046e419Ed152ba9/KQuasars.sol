// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract KQuasars is Ownable, ERC721A, ReentrancyGuard {
    bool public saleIsActive = false;
    bool public preSalesIsActive = false;

    address payable founders;
    address payable team;

    string private _baseURIextended;

    uint256 public constant MAX_SUPPLY = 777;
    uint256 public PRICE_PER_TOKEN = 0.5 ether;

    mapping(address => bool) private _allowList;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(
        string memory name, 
        string memory symbol,
        address payable founders_,
        address payable team_
    ) ERC721A(name, symbol) {
        founders = founders_;
        team = team_;
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = true;
        }
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE_PER_TOKEN = _price;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function canMint(address addr) public view returns (bool) {
        return _allowList[addr];
    }

    function reserve(uint256 numberOfTokens, address to) external onlyOwner {
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        _safeMint(to, numberOfTokens);
    }

    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
    }

    function setPreSalesState(bool newState) external onlyOwner {
        preSalesIsActive = newState;
    }

    function mint(uint256 numberOfTokens) external payable callerIsUser {
        require(numberOfTokens >= 1, "You must mint at least one token");
        require(saleIsActive, "Sale must be active to mint tokens");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        _safeMint(msg.sender, numberOfTokens);
        distributeRoyalties(PRICE_PER_TOKEN * numberOfTokens);
    }

    function mintAllowList(uint256 numberOfTokens) external payable callerIsUser {
        require(numberOfTokens >= 1, "You must mint at least one token");
        require(preSalesIsActive, "Pre-sales is not active");
        require(canMint(msg.sender), "Address is not in allowlist");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        _safeMint(msg.sender, numberOfTokens);
        distributeRoyalties(PRICE_PER_TOKEN * numberOfTokens);
    }

    function distributeRoyalties(uint256 price) private {        
        require(msg.value >= price, "Ether value sent is not correct");

        // for the founders treasury
        (bool success, ) = founders.call{value: msg.value * 90 / 100}("");
        require(success, "Error in the payment");

        // for the team treasury
        (bool successTwo, ) = team.call{value: msg.value * 10 / 100}("");
        require(successTwo, "Error in the payment");
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function getTokensMintedByUser(address tokenOwner) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](balanceOf(tokenOwner));
        uint256 counter = 0;
        uint256 totalMinted = totalSupply();
        for (uint256 i = 0; i < totalMinted; i++) {
            if (ownerOf(i) == tokenOwner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
}
