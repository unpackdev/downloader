// SPDX-License-Identifier: MIT
// Creator: RYAD LtD

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface NFTInterface is IERC721Enumerable {}

contract MetaverseTycoon is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    
    uint public constant MAX_DEEDS = 2001;
    uint public constant PRICE = 0.1 ether;
    string public METADATA_PROVENANCE_HASH = "";

    string public baseURI = "https://mvtycoon.azurewebsites.net/static/json/";
    
    uint private _curIndex = 0;
    
    bool public saleActive = false;
    
    constructor(address royaltyRecipient, uint96 royaltyPoints) ERC721A("Metaverse Tycoon","MVTYCOON")  {
        _setDefaultRoyalty(royaltyRecipient, royaltyPoints);
        /** Mint #0 to Royalty Recipient **/
        _safeMint(royaltyRecipient, 1);
    }
    
    /** NFT */
    
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
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


    function mint(uint256 numDeeds) external payable nonReentrant() {
        require(saleActive, "Sale is not active.");
        require(totalSupply() + numDeeds <= MAX_DEEDS, "Not enough Deeds remain!");
        require((msg.value >= numDeeds * PRICE), "Minimum price of 0.1 ETH.");
        require(numDeeds <= 4, "Max 4 Deeds per transaction.");
        _safeMint(msg.sender, numDeeds);

        if (totalSupply() + numDeeds >= MAX_DEEDS) {
            saleActive = false;
        }
    }


    function setProvenanceHash(string memory _hash) external onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return getBaseURI();
    }
    
    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function flipSaleState() external onlyOwner {
        saleActive = !saleActive;
    }

    function withdrawAll() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // Claim = mint to owner wallet

    function claimMany(uint256 numDeeds) external onlyOwner {
        require(totalSupply() < MAX_DEEDS, "Sale has already ended");
        require(totalSupply() + numDeeds <= MAX_DEEDS, "Not enough available");
        _safeMint(owner(), numDeeds);
    }

    function claimAllRemaining() external onlyOwner {
        // send remaining maneki to owner wallet
        _safeMint(owner(), MAX_DEEDS - totalSupply());
        saleActive = false;
    }

    // Give away = mint to another wallet

    function giveAway(address recipient) external nonReentrant() onlyOwner {
        require(totalSupply() < MAX_DEEDS, "No more maneki");
        _safeMint(recipient, 1);
    }

    function giveAwayManyToOne(address recipient, uint256 numDeeds) external nonReentrant() onlyOwner {
        require(totalSupply() < MAX_DEEDS, "No more maneki");
        require(totalSupply() + numDeeds <= MAX_DEEDS, "Not enough available");
        _safeMint(recipient, numDeeds);
    }

    function giveAwayOneToMany(address[] memory recipients) external nonReentrant() onlyOwner {
        require(totalSupply() + recipients.length <= totalSupply(), "Not enough maneki remain.");
        for (uint i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], 1);
        }
    }

    function giveAwayManyToMany(address[] memory recipients, uint256[] memory amounts) external nonReentrant() onlyOwner {
        require(recipients.length == amounts.length, "Number of addresses and amounts much match");
        uint256 totalToGiveAway = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalToGiveAway += amounts[i];
        }
        require(totalSupply() + totalToGiveAway <= totalSupply(), "Not enough maneki remain.");
        
        for (uint i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], amounts[i]);
        }
    }

    function burn(uint256 tokenId) external {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);
        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        require(isApprovedOrOwner, "Caller is not owner nor approved");
        _burn(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contract_metadata.json"));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }
}
