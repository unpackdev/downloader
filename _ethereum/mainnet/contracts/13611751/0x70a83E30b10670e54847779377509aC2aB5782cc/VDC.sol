// // SPDX-License-Identifier: MIT

// ____   ____               .___              _________ .__  __          
// \   \ /   /___   ____   __| _/____   ____   \_   ___ \|__|/  |_ ___.__.
//  \   Y   /  _ \ /  _ \ / __ |/  _ \ /  _ \  /    \  \/|  \   __<   |  |
//   \     (  <_> |  <_> ) /_/ (  <_> |  <_> ) \     \___|  ||  |  \___  |
//    \___/ \____/ \____/\____ |\____/ \____/   \______  /__||__|  / ____|
//                            \/                       \/          \/     

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity ^0.7.0;
pragma abicoder v2;

contract VDC is ERC721, Ownable {
    using SafeMath for uint256;

    string public PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN TOKENS ARE ALL SOLD OUT

    uint256 public constant tokenPrice = 55000000000000000; // 0.055 ETH
    uint256 public constant maxTokenPurchase = 30;
    uint256 public constant MAX_TOKENS = 6666;

    bool public saleIsOn = false;
    bool public presaleIsOn = false;

    mapping(address => uint256) private _whitelist;
    mapping(address => uint256) private _whitelistClaimed;

    uint256 public presaleMaxMint = 5;
    uint256 public devReserve = 66;

    event VdcMinted(uint256 supply);

    struct Whitelist {
        address addr;
        uint256 slots;
    }

    constructor() ERC721("Voodoo City NFT", "VDC") {}

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function reserveTokens(address _to, uint256 _reserveAmount) external onlyOwner {
        require(
            _reserveAmount > 0 && _reserveAmount <= devReserve,
            "Not enough reserve left for team"
        );
        for (uint256 i = 0; i < _reserveAmount; i++) {
            uint256 id = totalSupply();
            _safeMint(_to, id);
        }
        devReserve = devReserve.sub(_reserveAmount);
    }

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function toggleSale() external onlyOwner {
        saleIsOn = !saleIsOn;
    }

    function togglePresale() external onlyOwner {
        presaleIsOn = !presaleIsOn;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mintToken(uint256 numberOfTokens) external payable {
        require(saleIsOn, "Sale must be active to mint Token");
        require(
            numberOfTokens > 0 && numberOfTokens <= maxTokenPurchase,
            "Can only mint one or more tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 id = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, id);
                emit VdcMinted(id);
            }
        }
    }

    function presaleMint(uint256 numberOfTokens) external payable {
        require(presaleIsOn, "Presale is not active");
        require(_whitelist[msg.sender] > 0, "You are not on the Whitelist");
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of token"
        );
        require(
            numberOfTokens > 0 && numberOfTokens <= presaleMaxMint,
            "Cannot purchase this many tokens"
        );
        require(
            _whitelistClaimed[msg.sender].add(numberOfTokens) <=
                _whitelist[msg.sender],
            "Can't mint more than allocated slots"
        );
        require(
            _whitelistClaimed[msg.sender].add(numberOfTokens) <=
                presaleMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            msg.value >= tokenPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 id = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _whitelistClaimed[msg.sender] += 1;
                _safeMint(msg.sender, id);
                emit VdcMinted(id);
            }
        }
    }

    function updateWhitelist(Whitelist[] calldata whitelist) external onlyOwner {
        for (uint256 i = 0; i < whitelist.length; i++) {
            require(whitelist[i].addr != address(0), "Can't add the null address");

            _whitelist[whitelist[i].addr] = whitelist[i].slots;
        }
    }

    function setPresaleMaxMint(uint256 maxMint) external onlyOwner {
        presaleMaxMint = maxMint;
    }

    function canPresaleMint(address addr) external view returns (bool) {
        return _whitelist[addr] - _whitelistClaimed[addr] > 0 && presaleIsOn;
    }

    function presaleSlots(address addr) external view returns (uint256) {
        return _whitelist[addr] - _whitelistClaimed[addr];
    }
}
