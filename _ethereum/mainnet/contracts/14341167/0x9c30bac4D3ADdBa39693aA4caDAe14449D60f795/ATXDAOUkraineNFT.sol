/*
  /$$$$$$  /$$$$$$$$ /$$   /$$ /$$$$$$$   /$$$$$$   /$$$$$$
 /$$__  $$|__  $$__/| $$  / $$| $$__  $$ /$$__  $$ /$$__  $$
| $$  \ $$   | $$   |  $$/ $$/| $$  \ $$| $$  \ $$| $$  \ $$
| $$$$$$$$   | $$    \  $$$$/ | $$  | $$| $$$$$$$$| $$  | $$
| $$__  $$   | $$     >$$  $$ | $$  | $$| $$__  $$| $$  | $$
| $$  | $$   | $$    /$$/\  $$| $$  | $$| $$  | $$| $$  | $$
| $$  | $$   | $$   | $$  \ $$| $$$$$$$/| $$  | $$|  $$$$$$/
|__/  |__/   |__/   |__/  |__/|_______/ |__/  |__/ \______/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract ATXDAOUkraineNFT is ERC721URIStorage, Ownable {
    using Strings for uint256;

    bool public isMintable = false;

    uint256 public _tokenId = 0;

    uint256[] public priceTiers;

    string private baseURI;

    mapping(uint256 => uint256) public tierMap;
    mapping(uint256 => uint256) public valueMap;

    mapping(address => uint256) public recips;

    event UkraineNFTMinted(
        address minter,
        address recip,
        uint256 value,
        uint256 tier
    );

    constructor(uint256[] memory _priceTiers, address _to)
        ERC721("ATX <3 UKR", "<3UKR")
    {
        setTiers(_priceTiers);
        addRecip(_to);
    }

    function setTiers(uint256[] memory _priceTiers) public onlyOwner {
        require(_priceTiers.length > 0, "must be at least 1 price tier");
        priceTiers = new uint256[](_priceTiers.length);
        priceTiers[0] = _priceTiers[0];
        for (uint256 i = 1; i < _priceTiers.length; ++i) {
            require(
                _priceTiers[i] > _priceTiers[i - 1],
                "price tiers not ascending!"
            );
            priceTiers[i] = _priceTiers[i];
        }
    }

    function getTier(uint256 value) internal view returns (uint256) {
        require(value >= priceTiers[0], "value smaller than lowest tier!");
        uint256 tier = 0;
        for (uint256 i = 0; i < priceTiers.length; ++i) {
            if (value < priceTiers[i]) {
                break;
            }
            tier = i;
        }
        return tier;
    }

    // Normal mint
    function mint(address recip) external payable {
        require(isMintable == true, "minting not started!");
        require(isRecip(recip), "recipient not whitelisted!");
        // returns a tier or throws an error if value too small
        uint256 tier = getTier(msg.value);

        _tokenId += 1;
        _safeMint(msg.sender, _tokenId);
        _setTokenURI(
            _tokenId,
            string(abi.encodePacked(baseURI, tier.toString(), ".json"))
        );
        payable(recip).transfer(msg.value);
        tierMap[_tokenId] = tier;
        valueMap[_tokenId] = msg.value;
        recips[recip] += msg.value;
        emit UkraineNFTMinted(msg.sender, recip, msg.value, tier);
    }

    function totalDonated(address recip) public view returns (uint256) {
        require(isRecip(recip), "invalid recipient!");
        return recips[recip] - 1;
    }

    function addRecip(address recip) public onlyOwner {
        recips[recip] = 1;
    }

    function isRecip(address recip) public view returns (bool) {
        return recips[recip] > 0;
    }

    function startMint(string memory tokenURI) public onlyOwner {
        baseURI = tokenURI;
        isMintable = true;
    }

    function endMint() public onlyOwner {
        isMintable = false;
    }

    function getOwners()
        public
        view
        returns (
            address[] memory owners,
            uint256[] memory tiers,
            uint256[] memory values
        )
    {
        owners = new address[](_tokenId);
        tiers = new uint256[](_tokenId);
        values = new uint256[](_tokenId);
        for (uint256 i = 0; i < _tokenId; ++i) {
            owners[i] = ownerOf(i + 1);
            tiers[i] = tierMap[i + 1];
            values[i] = valueMap[i + 1];
        }
        return (owners, tiers, values);
    }
}
