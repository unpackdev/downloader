//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract WEALTH_CITY is ERC721A, Ownable {
    using Strings for uint256;

    string private baseTokenURI;
    string private notRevealedUri;
    uint256 public cost = 0.095 ether;
    uint256 public maxSupply = 5555;
    bool public paused = false;
    bool public revealed = false;
    address payable private devguy = payable(0x5C3229ef0c9A4219D226dE5cA2c14C7FAA175799);

    constructor() ERC721A("WEALTH CITY", "WC") {}

    function mint(uint256 _amount) public payable {
        require(!paused, "the mint is paused");
        require(totalSupply() + _amount <= maxSupply, "Sold out !");
        require(msg.value >= cost * _amount, "Not enough ether sended");
        _safeMint(msg.sender, _amount);
    }

    function gift(uint256 _amount, address _to) public onlyOwner {
        require(totalSupply() + _amount <= maxSupply, "Sold out");
        _safeMint(_to, _amount);
    }

    function setPause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function _baseUri() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseUri();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdraw() external onlyOwner {
        uint part = address(this).balance / 100 * 3;
        devguy.transfer(part);
        payable(owner()).transfer(address(this).balance);
    }
}