// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./Ownable.sol";

contract LivesOfWarden is ERC721, Ownable {
    
    uint public tokenQuota;
    uint public tokensFree;
    uint public tokensTotal;
    uint public lastTokenMinted;
    uint public mintPrice;
    mapping(address => uint) private addressQuotaLog;
    
    constructor() ERC721("LivesOfWarden", "WARDEN") {
        tokenQuota = 100;
        tokensFree = 500;
        tokensTotal = 9969;
        lastTokenMinted = 0;
        mintPrice = 0.0069 ether;
    }
    
    modifier quotaLeft {
        require(addressQuotaLog[msg.sender] <= tokenQuota, "This account has exceeded its quota"); _;
    }

    modifier tokensLeft {
        require(lastTokenMinted <= tokensTotal, "This project is sold out"); _;
    }

    function currentBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawBalance() public onlyOwner {
        uint withdrawAmount_100 = address(this).balance * 100 / 100;
        payable(0xa25642A26b78ec948575a485A7CAE0d55422EeB2).transfer(withdrawAmount_100);
    }

    function _mint(uint quantity) private quotaLeft tokensLeft {
        uint[20] memory tokenIds;
        for (uint i=0; i<quantity; i++) {
            lastTokenMinted = lastTokenMinted + 1;
            _safeMint(msg.sender, lastTokenMinted);
            addressQuotaLog[msg.sender] = addressQuotaLog[msg.sender] + 1;
            emit Minted(msg.sender, lastTokenMinted);
            tokenIds[i] = lastTokenMinted;
        }
    }
    
    function mint(uint quantity) public payable quotaLeft tokensLeft {
        require(quantity >= 1 && quantity <= 20, "Invalid quantity supplied");
        if (lastTokenMinted > tokensFree) {
            require(msg.value == mintPrice * quantity, "Incorrect amount supplied");
        }
        _mint(quantity);
    }
    
    function ownerMint(uint quantity) public quotaLeft tokensLeft onlyOwner {
        _mint(quantity);
    }
    
    function emitPermanentURI(string memory _value, uint256 _id) public onlyOwner {
        emit PermanentURI(_value, _id);
    }
    
    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked("https://meta.livesofwarden.com/", uint2str(tokenId), ".json"));
    }

    event PermanentURI(string _value, uint256 indexed _id);
    event Minted(address sender, uint tokenId);
    
    function contractURI() public pure returns (string memory) {
        return "https://livesofwarden.com/nft/collection.json";
    }
    
    function _baseURI() internal pure override returns (string memory) {
        return "";
    }
    
    function getBlockTimestamp() public view returns (uint) {
        return block.timestamp;
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

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }    

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}