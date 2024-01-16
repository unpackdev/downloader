pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./Ownable.sol";

contract UnstoppableDomainsZelusAirdrop is Ownable, ERC721 {
    string public _baseuri = "https://nft.zelus.io/unstoppable-zelus-airdrop/";
    uint256 private _idToMint = 1;

    constructor() ERC721("Unstoppable Domains x Zelus", "UDxZ") public {

    }

    /// mint one token and transfer it to the contract owner
    function mint() public onlyOwner {

        _safeMint(msg.sender, _idToMint);
        _idToMint += 1;
    }

    /// mint a single token and transfer it to the recipient
    function mintTo(address recipient) public onlyOwner() {
        _safeMint(recipient, _idToMint);
        _idToMint += 1;
    }

    function getMostRecentTokenID() public view returns (uint256) {
        return _idToMint - 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseuri;
    }



    function setBaseURI(string memory _uri) external onlyOwner {
        _baseuri = _uri;
    }

    function airdrop (
        address[] memory _recipients,
        uint256 _numRecipients
    ) public onlyOwner {

        for (uint i = 0; i < _numRecipients; i++) {
            mintTo(_recipients[i]);
        }
    }
}