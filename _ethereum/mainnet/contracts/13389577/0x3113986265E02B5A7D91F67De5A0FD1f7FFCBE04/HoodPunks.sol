// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";

contract HoodPunks is ERC721, Ownable {
    uint public lastTokenMinted;
    uint public nftPrice;
    uint public tokenAllocation;
    uint public tokenQuota;
    mapping(address => uint) private addressQuotaLog;
    
    uint public state; 

    constructor() ERC721("HoodPunks", "HPX") {
        tokenAllocation = 10000;
        lastTokenMinted = 0;
        nftPrice = 0.1 ether;
        state = 0;
        tokenQuota = 100;
    }
    
    modifier mintingEnabled {
        require(state > 0 && lastTokenMinted <= tokenAllocation, "The offering is not currently active"); _;
    }
    
    modifier quotaLeft {
        require(addressQuotaLog[msg.sender] <= tokenQuota, "This account has exceeded its quota"); _;
    }
    
    function getState() public view returns (string memory) {
        if (state == 1) {
            return "active";
        } else {
            return "inactive";
        }
    }

    function setState(uint newState) public onlyOwner {
        if (newState == 1) {
            state = 1;
        } else {
            state = 0;
        }
    }

    function currentBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }
    
    function withdrawBalance() public onlyOwner {
        address payable one_50 = payable(0xa25642A26b78ec948575a485A7CAE0d55422EeB2);
        address payable two_40 = payable(0x0F2a8cb0E190860f07B061D26AeBe0bE59cc0298);
        address payable three_10 = payable(0xdbd440B582863C92d3FfAB95C183d318E49A7a27);
        uint amount_50 = address(this).balance * 50 / 100;
        uint amount_40 = address(this).balance * 40 / 100;
        uint amount_10 = address(this).balance * 10 / 100;
        one_50.transfer(amount_50);
        two_40.transfer(amount_40);
        three_10.transfer(amount_10);
    }
    
    function mint() public payable mintingEnabled quotaLeft returns (uint tokenId) {
        require(msg.value == nftPrice, "Incorrect funds supplied: this is not the price for a NFT purchase");
        lastTokenMinted = lastTokenMinted + 1;
        if (lastTokenMinted == 4 || lastTokenMinted == 87 || lastTokenMinted == 91 || lastTokenMinted == 192 || lastTokenMinted == 830 || lastTokenMinted == 19 || lastTokenMinted == 17  || lastTokenMinted == 35) {
            lastTokenMinted = lastTokenMinted + 1;
        }
        _safeMint(msg.sender, lastTokenMinted);
        addressQuotaLog[msg.sender] = addressQuotaLog[msg.sender] + 1;
        tokenId = lastTokenMinted;
    }
    
    function ownerMint(uint reservedTokenId) public mintingEnabled onlyOwner returns (uint tokenId) {
        if (reservedTokenId == 4 || reservedTokenId == 87 || reservedTokenId == 91 || reservedTokenId == 192 || reservedTokenId == 830 || reservedTokenId == 19 || reservedTokenId == 17  || reservedTokenId == 35) {
            _safeMint(msg.sender, reservedTokenId);
            tokenId = reservedTokenId;
        } else {
            lastTokenMinted = lastTokenMinted + 1;
            if (lastTokenMinted == 4 || lastTokenMinted == 87 || lastTokenMinted == 91 || lastTokenMinted == 192 || lastTokenMinted == 830 || lastTokenMinted == 19 || lastTokenMinted == 17  || lastTokenMinted == 35) {
                lastTokenMinted = lastTokenMinted + 1;
            }
            _safeMint(msg.sender, lastTokenMinted);
            tokenId = lastTokenMinted;
        }
    }
    
    event PermanentURI(string _value, uint256 indexed _id);
    
    function contractURI() public pure returns (string memory) {
        return "https://hoodpunks.org/data/hoodpunks.json";
    }
    
    function _baseURI() internal pure override returns (string memory) {
        return "";
    }
    
    function tokenURI(uint256 tokenId) public pure override returns (string memory uri) {
        if (tokenId < 10) {
            return string(abi.encodePacked("https://meta.hoodpunks.org/000", uint2str(tokenId), ".json"));
        } else if (tokenId < 100) {
            return string(abi.encodePacked("https://meta.hoodpunks.org/00", uint2str(tokenId), ".json"));
        } else if (tokenId < 1000) {
            return string(abi.encodePacked("https://meta.hoodpunks.org/0", uint2str(tokenId), ".json"));
        } else {
            return string(abi.encodePacked("https://meta.hoodpunks.org/", uint2str(tokenId), ".json"));
        }
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