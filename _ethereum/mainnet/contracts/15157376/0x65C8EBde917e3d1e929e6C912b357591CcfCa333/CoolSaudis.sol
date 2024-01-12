// SPDX-License-Identifier: MIT

/*
 * COOL SAUDIS
 * 1 free per wallet; each additional costs .005 eth
 * Darwinian burning: You may mint 3 new Saudis by burning 2
 * Mint supply: 500, Max possible supply (after Darwinian burning): 1,000
 */

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract CoolSaudis is ERC721A, Ownable {

    uint256 public constant MINT_MAX = 500;
    uint256 public constant TOTAL_MAX = 1000;
    uint256 public constant COST_AFTER_FREE = 0.005 ether;

    mapping(address => bool) public addressHasMintedFree;

    string public baseURI;
    string public baseExtension = ".json";

    bool public saleActive; 

    constructor(string memory _baseURI) ERC721A("Cool Saudis", "SAUDIS") {
        baseURI = _baseURI;
    }

    /**
     * 1 free per wallet; each additional costs .005 eth
     */
    function mint(uint256 _amount) external payable { // free, 1 per wallet
        require(_totalMinted() + _amount <= MINT_MAX, "sold out");
        require(saleActive, "sale inactive");
        uint256 _cost = COST_AFTER_FREE * _amount;
        if(!addressHasMintedFree[_msgSender()]) {
            addressHasMintedFree[_msgSender()] = true;
            _cost -= 0.005 ether;
        }
        require(msg.value >= _cost, "not enough ether");
        _safeMint(_msgSender(), _amount);
    }

    function burnTwoForThreeFree(uint256 _tokenId1, uint256 _tokenId2) external {
        require(totalSupply() < TOTAL_MAX, "supply cap reached");
        require(_tokenId1 != _tokenId1);
        require(ownerOf(_tokenId1) == _msgSender() && ownerOf(_tokenId2) == _msgSender(), "NOT YOURS");
        _burn(_tokenId1);
        _burn(_tokenId2);
        _safeMint(_msgSender(), 3);
    }

    function devMint(address _addr, uint256 _amount) external onlyOwner {
        require(_totalMinted() + _amount <= TOTAL_MAX, "no more");
        _safeMint(_addr, _amount);
    }

    function setSaleActive(bool _intended) external onlyOwner {
        require(saleActive != _intended, "This is already the value");
        saleActive = _intended;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
  
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, _toString(_tokenId), baseExtension));
    }

    function getAmountBurned() external view returns(uint256) {
        return _totalMinted() - totalSupply();
    }

    function withdraw(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Failed to send ether");
    }

    function donate() public payable {
        (bool balls, ) = owner().call{value: address(this).balance}("");
        require(balls);
	}

}

