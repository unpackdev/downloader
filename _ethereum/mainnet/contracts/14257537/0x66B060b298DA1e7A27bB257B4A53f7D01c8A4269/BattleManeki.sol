// SPDX-License-Identifier: MIT
// Creator: Ryan Meyers

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface NFTInterface is IERC721Enumerable {}

contract BattleManeki is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    event Promo(address indexed _promoter, address indexed _minter, uint _numberMinted);
    
    uint public constant MAX_MANEKI = 5000;
    uint public constant HOLDER_PRICE = 0.045 ether;
    uint public constant PRICE = 0.075 ether;
    string public METADATA_PROVENANCE_HASH = "";

    address private _LuckyManekiContract = 0x144E84adAFA54dE411E68E1DE16eC9953B46180F;
    address private _ManekiGangContract = 0x08Da8a11C9b3A35D715B5da5B3E4661929490F53;

    string public baseURI = "https://battlemaneki.azurewebsites.net/static/json/";
    
    uint private _curIndex = 0;
    
    bool public saleActive = false;
    
    constructor(address luckyManekiContract, address manekiGangContract, address royaltyRecipient, uint96 royaltyPoints) ERC721A("Battle Maneki Series One","BATTLEMANEKI")  {
        _LuckyManekiContract = luckyManekiContract;
        _ManekiGangContract = manekiGangContract;
        _setDefaultRoyalty(royaltyRecipient, royaltyPoints);
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


    function mintManekiPublic(uint256 numManeki, address promoRecipient) external payable nonReentrant() {
        require(saleActive, "Sale is not active.");
        require(totalSupply() + numManeki <= MAX_MANEKI, "Not enough Maneki remain!");
        require((msg.value >= numManeki * PRICE), "Minimum price of 0.075.");
        _safeMint(msg.sender, numManeki);

        if (totalSupply() + numManeki >= MAX_MANEKI) {
            saleActive = false;
        }

        if (promoRecipient != msg.sender) {
            if (promoRecipient != address(0)){
                emit Promo(promoRecipient, msg.sender, numManeki);
            }
        }
    }

    function mintManekiWithManeki(uint256 numManeki) external payable nonReentrant() {
        require(NFTInterface(_LuckyManekiContract).balanceOf(msg.sender) > 0 || NFTInterface(_ManekiGangContract).balanceOf(msg.sender) > 0 , "Minter does not own a Maneki."); 
        require(totalSupply() + numManeki <= MAX_MANEKI, "Not enough Maneki remain!");
        require((msg.value >= numManeki * HOLDER_PRICE), "Minimum price of 0.045.");

        _safeMint(msg.sender, numManeki);

        if (totalSupply() + numManeki >= MAX_MANEKI) {
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

    function claimMany(uint256 numManeki) external onlyOwner {
        require(totalSupply() < MAX_MANEKI, "Sale has already ended");
        require(totalSupply() + numManeki <= MAX_MANEKI, "Not enough available");
        _safeMint(owner(), numManeki);
    }

    function claimAllRemaining() external onlyOwner {
        // send remaining maneki to owner wallet
        _safeMint(owner(), MAX_MANEKI - totalSupply());
        saleActive = false;
    }

    // Give away = mint to another wallet

    function giveAway(address recipient) external nonReentrant() onlyOwner {
        require(totalSupply() < MAX_MANEKI, "No more maneki");
        _safeMint(recipient, 1);
    }

    function giveAwayManyToOne(address recipient, uint256 numManeki) external nonReentrant() onlyOwner {
        require(totalSupply() < MAX_MANEKI, "No more maneki");
        require(totalSupply() + numManeki <= MAX_MANEKI, "Not enough available");
        _safeMint(recipient, numManeki);
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