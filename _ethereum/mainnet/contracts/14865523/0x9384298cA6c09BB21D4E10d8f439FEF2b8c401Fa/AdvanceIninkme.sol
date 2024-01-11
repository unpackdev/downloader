// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./EIP712Whitelisting.sol";
import "./ERC721A.sol";
import "./Address.sol";
import "./Strings.sol";

contract Ininkme is ERC721A, EIP712Whitelisting {
    using Address for address;
    using Strings for uint256;

    SalePhase public salePhase = SalePhase.WarmUp;

    uint256 public constant whitelistMaxSupply = 600;

    string internal _defaultURI =
        "ipfs://QmWHbd5rsNh7gDkG2qNYVwBDu7nUFDw6QkQygSEuxRW25t";
    string public _tokenBaseURI;

    mapping(uint256 => string) internal customIdToURI;

    constructor() ERC721A("Ininkme", "IM") {}

    function setSalePhase(SalePhase _salePhase) external onlyOwner {
        require(salePhase != SalePhase.End, "Sale ends!");
        salePhase = _salePhase;
    }

    function whitelistMint(uint256 amount, bytes calldata signature) external {
        require(!msg.sender.isContract(), "Contract is not allowed.");
        require(
            isEIP712WhiteListed(signature, amount, _numberMinted(msg.sender)),
            "Not whitelisted."
        );
        require(salePhase == SalePhase.WhitelistPhase, "Sale not available.");
        require(
            totalSupply() + (amount) <= whitelistMaxSupply,
            "Purchase exceed whitelistMaxSupply."
        );

        _safeMint(msg.sender, amount);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _tokenBaseURI = _baseURI;
    }

    function setDefaultURI(string memory _default) external onlyOwner {
        _defaultURI = _default;
    }

    function tokenBaseURI() external view returns (string memory) {
        return _tokenBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(tokenId <= totalSupply() - 1, "Token does not exist.");
        if (bytes(_tokenBaseURI).length == 0) {
            return _defaultURI;
        } else {
            return
                string(
                    abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
                );
        }
    }
}

enum SalePhase {
    WarmUp,
    WhitelistPhase,
    End
}
