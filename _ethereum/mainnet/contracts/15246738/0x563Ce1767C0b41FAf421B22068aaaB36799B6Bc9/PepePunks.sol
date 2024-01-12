// SPDX-License-Identifier: MIT

/*
 * Pepe Punks!
 * twitter: @pepepunks_nft
 *
 * Roadmap:
 * 
 *
 */

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./OwnableWithAdmin.sol";

contract PepePunks is ERC721A, OwnableWithAdmin {

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant COST_AFTER_FREE = 0.005 ether;

    mapping(address => bool) public addressHasMintedFree;

    string public baseURI;
    bool public saleActive; 

    constructor(string memory _baseURI) ERC721A("Pepe Punks", "PPP") {
        baseURI = _baseURI;
        _setAdmin(0xd37830e8e701Acc80A91bD1E13A4377A8Ed166AC);
    }

    /**
     * First one is free and each additional one is .005 eth
     */
    function mint(uint256 _amount) external payable {
        require(_totalMinted() + _amount <= MAX_SUPPLY, "sold out");
        require(saleActive, "sale inactive");
        uint256 _cost = COST_AFTER_FREE * _amount;
        if(!addressHasMintedFree[_msgSender()]) {
            addressHasMintedFree[_msgSender()] = true;
            _cost -= 0.005 ether;
        }
        require(msg.value >= _cost, "not enough ether");
        _safeMint(_msgSender(), _amount);
    }


    function devMint(address _addr, uint256 _amount) external onlyOwnerOrAdmin {
        require(_totalMinted() + _amount <= MAX_SUPPLY, "no more");
        _safeMint(_addr, _amount);
    }

    function setSaleActive(bool _intended) external onlyOwnerOrAdmin {
        saleActive = _intended;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwnerOrAdmin {
        baseURI = _baseURI;
    }
  
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract.json"));
    }

    function withdraw(address _to) external onlyOwnerOrAdmin {
        uint256 balance = address(this).balance;
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Failed to send ether");
    }

}

