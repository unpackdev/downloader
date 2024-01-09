// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract WeMintQueen is ERC721A, Ownable {
    ERC721 Washies;
    using Strings for uint256;
    bool public enabled = true;
    bool public premint = true;
    uint256 constant maxSupply = 1960;
    uint256 constant price = 0.07 ether;
    string public baseURI = "";
    mapping(address => bool) public claimedFree;

    constructor() ERC721A("WeMint Queen", "QUEEN", maxSupply) {
        setWashie(0xA9cB55D05D3351dcD02dd5DC4614e764ce3E1D6e);
    }

    function mint(uint256 mints) public payable returns (uint256[] memory) {
        uint256 supply = totalSupply();
        require(enabled, "Contract not enabled.");
        require(
            tx.origin == msg.sender,
            "CANNOT MINT THROUGH A CUSTOM CONTRACT"
        );
        require(
            Washies.balanceOf(msg.sender) >= 2,
            "Queen only for wallets holding 2 or more Washies!"
        );
        require(balanceOf(msg.sender) < 2, "Limit 2 per wallet.");
        require(
            balanceOf(msg.sender) + mints <= 2,
            "Can't mint more than 2 queens per wallet."
        );
        require(supply + mints <= maxSupply, "Not enough supply.");

        uint256 txPrice = mints * price;
        if (premint && supply + mints <= 500 && !claimedFree[msg.sender]) {
            claimedFree[msg.sender] = true;
            txPrice = txPrice - price;
        }
        if (msg.sender != owner() && txPrice > 0) {
            require(msg.value >= txPrice, "Invalid amount sent.");
        }

        uint256[] memory newTokenIds = new uint256[](mints);
        uint256 newTokenId = supply;
        for (uint256 i = 0; i < mints; i++) {
            newTokenIds[i] = newTokenId;
            newTokenId += 1;
        }
        _safeMint(_msgSender(), mints);
        return newTokenIds;
    }

    function setWashie(address _washieAddress) public onlyOwner {
        Washies = ERC721(_washieAddress);
        return;
    }

    function enable(bool _enabled) public onlyOwner {
        enabled = _enabled;
    }

    function setPremint(bool _premint) public onlyOwner {
        premint = _premint;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
