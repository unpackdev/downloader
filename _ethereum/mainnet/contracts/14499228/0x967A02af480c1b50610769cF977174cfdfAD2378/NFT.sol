// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract TZeroTroopers is ERC721, ERC721Enumerable, Ownable {
    string public PROVENANCE;
    string private _baseURIextended;
    bool public saleIsActive = false;
    uint256 public constant MAX_SUPPLY = 210;
    mapping(address => bool) public hasMinted;

    constructor(string memory _provenance) ERC721("t0-Troopers", "T0T") {
        PROVENANCE = _provenance;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(msg.sender, supply + i);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(bytes memory sig, bool canMintAfterSaleEnds) public {
        uint256 ts = totalSupply();

        require(saleIsActive || canMintAfterSaleEnds, "Sale must be active to mint tokens");
        require(ts <= MAX_SUPPLY, "Mint would exceed max tokens");
        require(hasMinted[msg.sender] == false, "Already minted");
        require(
            sigAllowsMint(msg.sender, canMintAfterSaleEnds, sig),
            "sig doesnt allow minting"
        );

        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, ts);
    }

    function sigAllowsMint(address sender, bool canMintAfterSaleEnds, bytes memory sig)
        private
        view
        returns (bool)
    {

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(this, sender, canMintAfterSaleEnds))
            )
        );
        
        address signingAddress = getSigningAddress(hash, sig);
        return signingAddress == owner();
    }

    function getSigningAddress(bytes32 message, bytes memory signature)
        public
        pure
        returns (address)
    {
        assert(signature.length == 65);
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        return ecrecover(message, v, r, s);
    }
}