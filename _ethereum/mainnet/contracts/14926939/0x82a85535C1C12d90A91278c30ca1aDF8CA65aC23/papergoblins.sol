// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";

contract PaperGoblins is Ownable, ERC721A {
    uint256 public constant MAX_SUPPLY = 1000;

    string public baseURI = 'ipfs://bafybeidyivomo56sqwfcnjeqt5mfnombvfywcp3ta2krllyflvbpyustzy/';

    constructor() ERC721A("Paper Goblins", "pgbl") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function freeMint(uint256 quantity)
        external
        mintCompliance(quantity)
    {
        require(quantity < 3, "Only 2");

        _safeMint(msg.sender, quantity);
    }



    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < MAX_SUPPLY + 1
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }


    function setContractURI(string memory _contractURI) public onlyOwner {
        baseURI = _contractURI;
    }


    address private constant walletA = 0x639526B935670021fFBF2d967F33c9A1Bb0be89A;

    //this is included incase someone donates to the contract;
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

		Address.sendValue(payable(walletA), (balance * 100) / 100);

    }

    modifier mintCompliance(uint256 quantity) {
        require(
            totalSupply() + quantity < MAX_SUPPLY + 1,
            "Not enough mints left"
        );
        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}
