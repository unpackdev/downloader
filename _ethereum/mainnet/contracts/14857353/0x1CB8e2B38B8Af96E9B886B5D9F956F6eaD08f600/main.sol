//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Royalty.sol";

/*
 * Chaotic Circles collection by Yury Coding Art.
 * Website:   https://yurycoding.art/
 * Twitter:   https://twitter.com/yurycoding/
 * Instagram: https://www.instagram.com/yurycoding/
 *
 * Contract developed by n1nja. (@___n1nja___ on twitter)
 *
 */

contract ChaoticCirclesNFT is ERC721Royalty, Ownable {
    constructor() ERC721("chaotic-circles", "NFT") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    uint public totalSupply = 0;
    uint public TOTAL_LIMIT = 1000;
    
    uint public PRICE_OG     = 0.09 ether;
    uint public PRICE_WL     = 0.1 ether;
    uint public PRICE_PUBLIC = 0.12 ether;
    
    bool public allowPublic = false;
    mapping (address => uint) public OG;
    mapping (address => uint) public WL;

    string public URI = "";
    string public contractMetadataURI = "";

    function setAllowPublic(bool _value) public onlyOwner {
        allowPublic = _value;
    }

    function setOGList(address[] calldata _list, uint number) public onlyOwner{
        uint len = _list.length;
        for (uint i = 0; i < len; i++) {
            OG[_list[i]] = number;
        }
    }

    function setWLList(address[] calldata _list, uint number) public onlyOwner{
        uint len = _list.length;
        for (uint i = 0; i < len; i++) {
            WL[_list[i]] = number;
        }
    }

    function getPrice(address buyer) external view returns (uint) {
        require(totalSupply < TOTAL_LIMIT, "all tokens are minted");
        if (OG[buyer] > 0) {
            return PRICE_OG;
        } else if (WL[buyer] > 0) {
            return PRICE_WL;
        } else {
            require(allowPublic, "public mint is not open yet");
            return PRICE_PUBLIC;
        }
    }

    function mintNFT() public payable {
        require(totalSupply < TOTAL_LIMIT, "all tokens are minted");
        if (OG[msg.sender] > 0) {
            require(msg.value == PRICE_OG, "incorrect amount sent");
            unchecked {
                OG[msg.sender]--;
            }
        } else if (WL[msg.sender] > 0) {
            require(msg.value == PRICE_WL, "incorrect amount sent");
            unchecked {
                WL[msg.sender]--;
            }
        } else {
            require(allowPublic, "public mint is not open yet");
            require(msg.value == PRICE_PUBLIC, "incorrect amount sent");
        }

        unchecked {
            totalSupply++;
        }
        _mint(msg.sender, totalSupply);
    }

    function mintMultipleNFT(uint _amount) public payable {
        require(totalSupply + _amount <= TOTAL_LIMIT, "all tokens are minted");
        require(allowPublic, "public mint is not open yet");
        require(msg.value == PRICE_PUBLIC * _amount, "incorrect amount sent");

        while (_amount > 0) {
            unchecked {
                totalSupply++;
                _amount--;
            }
            _mint(msg.sender, totalSupply);
        }
    }

    function giftNFT(address _recepient, uint _amount) public onlyOwner {
        while (_amount > 0) {
            require(totalSupply < TOTAL_LIMIT, "all tokens are minted");
            unchecked {
                totalSupply++;
                _amount--;
            }
            _mint(_recepient, totalSupply);
        }
    }

    function withdraw(address payable _recepient, uint _amount) public onlyOwner {
        require(_recepient != address(0));
        require(_amount <= address(this).balance);
        _recepient.transfer(_amount);
    }

    function setURI(string memory _newURI) public onlyOwner {
        URI = _newURI;
    }

    function setContractMetadataURI(string memory _newURI) public onlyOwner {
        contractMetadataURI = _newURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return URI;
    }

    function updateRoyaltyInfo(address payable _address, uint96 fee) public onlyOwner {
        _setDefaultRoyalty(_address, fee);
    }
}
