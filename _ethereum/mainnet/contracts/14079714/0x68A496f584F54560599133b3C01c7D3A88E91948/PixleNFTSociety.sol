// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract PixleNFTSociety is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 1352;
    uint256 public constant MAX_PURCHASABLE = 5;

    uint256 public tokenPrice = .25 ether; // 0.25 ETH

    bool public saleIsActive = false;

    // bool public whitelistActive = false;

    // address[] public whitelistedAddresses;

    constructor() public ERC721("PIXLE NFT Society", "PNS") {
        setBaseURI("ipfs://QmdgE7hsWS4qQbY4Zr36aoPhpyjXDCHLZKZmhVD79UtTWu/");
        reserveTokens(10); // reserve for the team
    }

    // SETTER FUNCTIONS

    function openSale() public onlyOwner {
        saleIsActive = true;
    }

    function closeSale() public onlyOwner {
        saleIsActive = false;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setTokenPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }

    // GETTERS

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory baseURI = baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    // MINTING FUNCTIONS

    // function presaleMint(uint256 numberOfTokens) public payable {
    //     require(
    //         saleIsActive && whitelistActive,
    //         "Sale and whitelist must be active to mint"
    //     );
    //     require(
    //         isWhitelisted(msg.sender),
    //         "You must be on the whitelist to mint during the presale."
    //     );
    //     require(
    //         balanceOf(msg.sender).add(numberOfTokens) <= 1,
    //         "You can only mint 1 before the sale begins"
    //     );
    //     require(numberOfTokens > 0, "Minimum mint is 1 token");
    //     require(
    //         numberOfTokens <= 1,
    //         "You can only mint up to 1 tokens during the presale."
    //     );

    //     require(
    //         tokenPrice.mul(numberOfTokens) <= msg.value,
    //         "Incorrect Ether value."
    //     );

    //     for (uint256 i = 0; i < numberOfTokens; i++) {
    //         uint256 mintIndex = totalSupply();
    //         _safeMint(msg.sender, mintIndex);
    //     }
    // }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(totalSupply() < MAX_SUPPLY, "All tokens have been minted.");
        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "The amount of tokens you are trying to mint exceeds the max supply."
        );
        require(numberOfTokens > 0, "Minimum mint is 1 token");
        require(numberOfTokens <= MAX_PURCHASABLE, "Maximum mint is 5 tokens");
        require(
            tokenPrice.mul(numberOfTokens) <= msg.value,
            "Incorrect Ether value."
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function reserveTokens(uint256 _reserveAmount) public onlyOwner {
        uint256 supply = totalSupply();

        require(
            _reserveAmount > 0 && _reserveAmount + supply <= MAX_SUPPLY,
            "Not enough reserve left for team"
        );

        for (uint256 i = 0; i < _reserveAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // WHITELIST METHODS

    // function addToWhitelist(address[] calldata _users) public onlyOwner {
    //     delete whitelistedAddresses;
    //     whitelistedAddresses = _users;
    // }

    // function isWhitelisted(address _user) public view returns (bool) {
    //     for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
    //         if (whitelistedAddresses[i] == _user) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    // function clearWhitelist() public onlyOwner {
    //     delete whitelistedAddresses;
    // }

    // function getWhitelistSize() public view returns (uint256) {
    //     return whitelistedAddresses.length;
    // }
}
