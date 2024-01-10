// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract NFTClone is ERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(uint256 => NFT) private tokenIdToNFT;
    uint private fee = 0.005 ether;

    struct NFT {
        address contractAddr;
        uint256 tokenId;
    }

    // solhint-disable-next-line
    constructor() ERC721("NFTClone", "NCLN") {}

    function mint(address _contract, uint256 _tokenId, address _destination) public payable {
        if (msg.sender != owner()) {
            require(msg.value >= fee, string(abi.encodePacked("Missing fee of ", fee.toString(), " wei")));
        }

        // call ownerOf(_tokenId) to validate token exists
        (bool _success, ) = _contract.call(abi.encodeWithSelector(0x6352211e, _tokenId));
        require(_success, "tokenId does not exist");

        uint256 newSupply = totalSupply() + 1;
        tokenIdToNFT[newSupply] = NFT(
            _contract,
            _tokenId
        );
        _safeMint(_destination, newSupply);
    }
    
    function mint(address _contract, uint256 _tokenId) public payable {
        mint(_contract, _tokenId, msg.sender);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return ERC721(tokenIdToNFT[_tokenId].contractAddr).tokenURI(tokenIdToNFT[_tokenId].tokenId);
    }

    function getFee() public view returns (uint) {
        return fee;
    }

    function setFee(uint _newFee) public onlyOwner {
        fee = _newFee;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}

// Pilate 2022