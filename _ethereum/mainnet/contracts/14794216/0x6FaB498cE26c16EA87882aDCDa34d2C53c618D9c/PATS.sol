// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract PATS is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public cost;
    uint256 public cost1 = 0.333 * 10**18;
    uint256 public cost2 = 0.444 * 10**18;
    uint256 public cost3 = 0.555 * 10**18;
    uint256 public cost4 = 0.777 * 10**18;
    string public baseURI;
    string public ContractURI;
    uint256 totalWallet = 2;
    bool publicSale = false;

    string public baseExtension = ".json";
    mapping(address => bool) whitelistedAddresses;

    constructor() ERC721A("PA'T", "PATs") {
        whitelistedAddresses[address(this)] = true;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(supply + _mintAmount <= MAX_SUPPLY);

        if (publicSale) {
            cost = cost4;
        } else {
            if (supply <= 111) {
                require(
                    verifyUser(msg.sender),
                    "You need to be whitelisted for this phase!"
                );
                cost = cost1;
            } else if (supply > 111 && supply <= 222) {
                require(
                    verifyUser(msg.sender),
                    "You need to be whitelisted for this phase!"
                );
                cost = cost2;
            } else if (supply > 222 && supply <= 333) {
                require(
                    verifyUser(msg.sender),
                    "You need to be whitelisted for this phase!"
                );
                cost = cost3;
            } else {
                cost = cost4;
            }
        }

        if (msg.sender != owner()) {
            require(
                walletOfOwner(_to).length + _mintAmount <= totalWallet,
                "You have reached minting limit!"
            );
            require(msg.value >= cost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function changeCost(uint256 phase, uint256 newCost) public onlyOwner {
        if (phase == 1) {
            cost1 = newCost * 10**18;
        } else if (phase == 2) {
            cost2 = newCost * 10**18;
        } else if (phase == 3) {
            cost3 = newCost * 10**18;
        } else if (phase == 4) {
            cost4 = newCost * 10**18;
        }
    }

    function verifyUser(address _whitelistedAddress)
        public
        view
        returns (bool)
    {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return ContractURI;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function addUsers(address[] memory _addressesToWhitelist) public onlyOwner {
        for (uint256 i = 0; i < _addressesToWhitelist.length; i++) {
            whitelistedAddresses[_addressesToWhitelist[i]] = true;
        }
    }

    function changeWalletLimit(uint256 newLimit) public onlyOwner {
        totalWallet = newLimit;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function Reveal(string memory _RevealURI) public onlyOwner {
        baseURI = _RevealURI;
    }

    function startPublic() public onlyOwner {
        publicSale = true;
    }

    function stopPublic() public onlyOwner {
        publicSale = false;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
