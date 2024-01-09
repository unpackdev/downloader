// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";

contract MekaApesERC721 is ERC721Upgradeable, OwnableUpgradeable {

    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    address public gameContract;

    string public baseURI;

    string public _contractURI;

    function initialize(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_,
        string memory contractURI_
    ) public initializer {

        __ERC721_init(name_, symbol_);
        __Ownable_init();

       
        baseURI = baseURI_;
        _contractURI = contractURI_;
    }

    function setGameContract(address gameContract_) external onlyOwner {
         gameContract = gameContract_;
    }   

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    function mint(address account, uint256 tokenId) external {
        require(msg.sender == gameContract, "E1");
        _mint(account, tokenId);
    }

    function mintMultiple(address account, uint256 startFromTokenId, uint256 amount) external {
        require(msg.sender == gameContract, "E1");
        for(uint256 i=0; i<amount; i++) {
            _mint(account, startFromTokenId + i);
        }
    }

    function burn(uint256 tokenId) external {
        require(msg.sender == gameContract, "E2");
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "E3");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, uintToStr(tokenId), ".json")) : "";
    }

    function changeBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender) || spender == gameContract);
    }

    function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}