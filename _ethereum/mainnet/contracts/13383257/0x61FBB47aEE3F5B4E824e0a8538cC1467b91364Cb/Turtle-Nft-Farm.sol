pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";


//
//        __  __    _    ____ _____           _   _
//       |  \/  |  / \  | __ )_   _|   _ _ __| |_| | ___
//       | |\/| | / _ \ |  _ \ | || | | | '__| __| |/ _ \
//       | |  | |/ ___ \| |_) || || |_| | |  | |_| |  __/
//       |_|  |_/_/   \_\____/ |_| \__,_|_|   \__|_|\___|
//
//
//
//  Find out more on makeable.art
//

contract MABTurtleFarm is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    bool public _isSaleActive = false;
    string private _baseURIExtended;
    uint256 public maxMintablePerCall = 30;
    address[] public partnerCommunities;
    uint256 public freeTurtlesAvailable = 888;
    mapping(address => bool) public partnerCommunityFreeTurtleRetrieved;
    mapping(uint => bool) public cardsUsed;

    // Constants
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public NFT_PRICE = .04 ether;
    uint256 public MAX_NFT_PER_PARTNER_COMMUNITY = 1;
    address public BIG_BANG_CARDS = 0x4b24E905e29622fB02dC1Bf67aE59C7dF2F23872;

    event SaleStarted();
    event SaleStopped();
    event TokenMinted(uint256 supply);
    event CardMint(uint256[] cards);
    event PartnerMint();

    constructor() ERC721('MABTurtle', 'TURTLE') {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function getTurtlesByOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function _baseMint (uint256 num_tokens, address to) internal {
        require(totalSupply().add(num_tokens) <= MAX_SUPPLY, 'Sale would exceed max supply');
        uint256 supply = totalSupply();
        for (uint i=0; i < num_tokens; i++) {
            _safeMint(to, supply + i);
        }
        emit TokenMinted(totalSupply());
    }

    function mint(address _to, uint _count) public payable {
        require(_isSaleActive, 'Sale must be active to mint MAB Turtles');

        // check if we are doing a partner Mint
        bool isInPartnerCommunity = isCallerInAPartnerCommunity();
        bool isPartnerMint = false;
        if (isInPartnerCommunity && !partnerCommunityFreeTurtleRetrieved[msg.sender] && freeTurtlesAvailable>1) {
            isPartnerMint = true;
            emit PartnerMint();
        }

        // check if it has enough ethers in case it's not a partner mint or an owner mint
        if ( !isPartnerMint && owner() != msg.sender ) {
            require(NFT_PRICE*_count <= msg.value, 'Not enough ether sent (check NFT_PRICE for current token price)');
        }

        // require that in case of partnerMint the max number of Turtles mintable for free has not been reached
        // and it's only one the mintable
        if (isPartnerMint) {
            require(freeTurtlesAvailable >= 1, "Reached max number of free Turtles mintable");
            require(_count == 1, "Only one Turtle can be mint by a partner mint");
        }

        require(_count <= maxMintablePerCall, 'Exceeding max mintable limit for contract call');
        _baseMint(_count, _to);

        if (isPartnerMint) {
            partnerCommunityFreeTurtleRetrieved[msg.sender] = true;
            freeTurtlesAvailable = freeTurtlesAvailable - 1;
        }
    }

    function cardMint(address _to, uint _count, uint[] memory _cards) public payable {
        require(_isSaleActive, 'Sale must be active to mint MAB Turtles');
        require(_cards.length >= 1, 'At least one card needs to be given to call this method');

        // check if the cards has not already been used
        for (uint i=0; i<_cards.length; i++) {
            uint cardNum = _cards[i];
            require(!cardsUsed[cardNum], 'One of the given cards has been already used');
        }

        // check if the caller is the owner of those cards
        IERC721 bigBangContract = IERC721(BIG_BANG_CARDS);
        for (uint i=0; i<_cards.length; i++) {
            uint cardNum = _cards[i];
            address own = bigBangContract.ownerOf(cardNum);
            require(own == msg.sender, 'Sender needs to be the owner of all the cards passed in as argument');
        }

        // understand how many free turtles he should mint, and how paying ones
        uint freeMint = _count;
        uint paidMint = _count;
        if (_cards.length >= _count) {
            paidMint = 0;
        } else {
            freeMint = _cards.length;
            paidMint = _count - freeMint;
        }
        require(NFT_PRICE*paidMint <= msg.value, 'Not enough ether sent (check NFT_PRICE for current token price)');
        require(_count <= maxMintablePerCall, 'Exceeding max mintable limit for contract call');
        _baseMint(_count, _to);

        // set the cards as used
        for (uint i=0; i<_cards.length; i++) {
            uint cardNum = _cards[i];
            cardsUsed[cardNum] = true;
        }
        emit CardMint(_cards);
    }

    function isCallerInAPartnerCommunity() public view returns (bool) {
        bool isPartner = false;
        for (uint i=0; i<partnerCommunities.length; i++) {
            IERC721 partnerContract = IERC721(partnerCommunities[i]);
            uint256 balance = partnerContract.balanceOf(msg.sender);
            if (balance > 0) {
                return true;
            }
        }
        return isPartner;
    }

    function ownerMint(address[] memory recipients, uint256[] memory amount) external onlyOwner {
        require(recipients.length == amount.length, 'Arrays needs to be of equal lenght');
        uint256 totalToMint = 0;
        for (uint256 i=0; i<amount.length; i++) {
            totalToMint = totalToMint + amount[i];
        }
        require(totalSupply().add(totalToMint) <= MAX_SUPPLY, 'Mint will exceed total supply');

        for (uint256 i=0; i<recipients.length; i++) {
            _baseMint(amount[i], recipients[i]);
        }
    }

    function pauseSale() external onlyOwner {
        _isSaleActive = false;
        emit SaleStopped();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setMaxMintablePerCall(uint256 newMax) external onlyOwner {
        maxMintablePerCall = newMax;
    }

    function setMaxNFtPerPartnerCommunity(uint256 newMax) external onlyOwner {
        MAX_NFT_PER_PARTNER_COMMUNITY = newMax;
    }

    function setPrice(uint256 price) external onlyOwner {
        NFT_PRICE = price;
    }

    function setFreeTurtlesAvailable(uint256 available) external onlyOwner {
        freeTurtlesAvailable = available;
    }

    function setPartnerCommunities (address[] memory collections) external onlyOwner {
        delete partnerCommunities;
        partnerCommunities = collections;
    }

    function setBigBangCardsAddress (address newAddress) external onlyOwner {
        BIG_BANG_CARDS = newAddress;
    }

    function startSale() external onlyOwner {
        _isSaleActive = true;
        emit SaleStarted();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}