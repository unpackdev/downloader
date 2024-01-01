// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721.sol";

contract ProofOfCock is ERC721, Ownable {
    using Strings for uint256;

    uint public constant MINT_PRICE = 10000000000000000 wei; //0.01 ETH;
    uint public constant TOTAL_SUPPLY = 1000;
    uint public CURRENT_SUPPLY;

    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("ProofOfCock", "COCK") {
        baseUri = "ipfs://bafybeigls33pgh72t5c5fywsyj6rjc3436fqwdhkizy2ll23ekqkixvteu/";
        for (uint i; i < 10; i++) {
            _safeMint(msg.sender, CURRENT_SUPPLY);
            CURRENT_SUPPLY++;
        }
    }

    function mintCertificate(uint _amount) external payable {
        require(
            CURRENT_SUPPLY + _amount <= TOTAL_SUPPLY,
            "Mint cap has been reached."
        );
        require(msg.value >= MINT_PRICE * _amount, "Not enough funds to mint.");
        require(_amount > 0 && _amount <= 10, "Invalid amount");

        for (uint i; i < _amount; i++) {
            _safeMint(msg.sender, CURRENT_SUPPLY);
            CURRENT_SUPPLY++;
        }
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function withdrawAll() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
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

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}
