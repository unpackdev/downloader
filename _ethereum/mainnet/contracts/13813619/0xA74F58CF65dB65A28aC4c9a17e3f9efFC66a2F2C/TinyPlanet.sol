// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./base64.sol";

contract TinyPlanet is ERC721, ReentrancyGuard, Ownable
{
    uint128 constant PRICE = 0.025 ether;
    uint128 private _tokenCounter = 0;

    string private _baseTokenURI = "none";
    bool private _isRevealed = false;
    constructor() ERC721("TinyPlanet", "TNP"){}

    mapping (address => bool) private _isFreeAddress;
    mapping (uint256 => string) private _planetName;
    function addFreeAddresses(address[] memory _addr) external onlyOwner
    {
        for(uint i = 0; i < _addr.length; i++)
        {
            _isFreeAddress[_addr[i]] = true;
        }
    }

    function toggleReveal() external onlyOwner
    {
        _isRevealed = true;
    }
    function changeBaseURI(string memory _newBaseURI) external onlyOwner
    {
        _baseTokenURI = _newBaseURI;
    }

    function getFreePlanet() external nonReentrant
    {
        require(_isFreeAddress[msg.sender] == true, "Unauthorized Address");
        _isFreeAddress[msg.sender] = false;
        _planetName[_tokenCounter] = string(abi.encodePacked('Tiny Planet #', uint2str(_tokenCounter)));
        _safeMint(msg.sender, _tokenCounter);
        _tokenCounter = _tokenCounter + 1;
    }

    function changeName(uint _tokenID, string memory _newName) external
    {
        require(msg.sender == ownerOf(_tokenID), "No Ownership of this NFT");

        _planetName[_tokenID] = _newName;
    }
    function buyPlanet(uint _count) external payable
    {
        createPlanet(_count);
    }

    function createPlanet(uint _countToMint) internal
    {
        require(_countToMint <= 5, "Max 5 per tx!");
        require(msg.value >= PRICE * _countToMint, "Incorrect Price");
        require(_tokenCounter + _countToMint < 4000, "SOLD OUT");

        for(uint256 i = 0; i < _countToMint; i++)
        {
            _planetName[_tokenCounter + i] = string(abi.encodePacked('Tiny Planet #', uint2str(_tokenCounter + i)));
            _safeMint(msg.sender, _tokenCounter + i);
        }
        _tokenCounter = _tokenCounter + uint64(_countToMint);
    }
    
    function withdraw() external onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        
        string memory image = "none";

        if(_isRevealed)
        {
            image = string(abi.encodePacked(_baseTokenURI, '/', uint2str(_tokenId + 1), '.png'));
        }
        else
        {
            image = _baseTokenURI;
        }

        string memory json = string(abi.encodePacked(
        '{ "description": "One of the 4000 procedurally generated Tiny Planets, with millions of possibilities regarding colors, shapes, clouds, ocean, and much more!",', 
        ' "image": "', image, '",',
        ' "name": "', _planetName[_tokenId], '", "attributes": []}'));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(abi.encodePacked(json)))));

    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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