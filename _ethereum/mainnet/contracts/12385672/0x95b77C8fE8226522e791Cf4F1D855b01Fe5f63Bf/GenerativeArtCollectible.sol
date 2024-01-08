//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.3;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./HasSecondarySaleFees.sol";

contract GenerativeArtCollectible is ERC721, HasSecondarySaleFees, Ownable {

    event AddArt(uint256 indexed artId);

    event BuyArt(uint256 indexed artId, uint256 indexed tokenId, address indexed buyer);

    struct Art {
        uint8 remainingAmount;
        uint256 price;
    }

    string private baseURI;
    Art[4] private arts;
    address payable[] private recipients;
    mapping(uint256 => string) private tokenURISuffixes;

    constructor(
        string memory initialBaseURI,
        address payable[2] memory _recipients
    ) ERC721("Okazz's Generative Art NFT", "OGA") {
        baseURI = initialBaseURI;
        for (uint8 i = 0; i < 4; i++) {
            arts[i] = Art(10, 3e16);
            emit AddArt(i);
        }
        recipients = _recipients;
        address payable[] memory marketRoyaltyRecipients = new address payable[](1);
        marketRoyaltyRecipients[0] = payable(this);
        uint256[] memory marketRoyaltyFees = new uint256[](1);
        marketRoyaltyFees[0] = 1000;

        _setDefaultRoyalty(marketRoyaltyRecipients, marketRoyaltyFees);
    }

    function remainingAmountOf(uint8 artId) view external returns (uint8) {
        Art memory art = arts[artId];
        return art.remainingAmount;
    }

    function priceOf(uint8 artId) view external returns (uint256) {
        Art memory art = arts[artId];
        return art.price;
    }

    function buy(
        uint8 artId,
        string memory metadataCid
    ) external payable {
        Art storage art = arts[artId];
        art.remainingAmount = art.remainingAmount - 1;
        require(msg.value == art.price, "Sent ether is invalid.");

        uint256 tokenId = ((art.price * 1000 - 3e19) / 1e18) + artId * 10;
        art.price = art.price + 1e15;
        tokenURISuffixes[tokenId] = metadataCid;

        _mint(msg.sender, tokenId);
        emit BuyArt(artId, tokenId, msg.sender);
    }

    function withdrawETH() external {
        uint256 distribution = address(this).balance / 2;

        payable(recipients[0]).transfer(distribution);
        payable(recipients[1]).transfer(distribution);
    }

    function withdrawToken(address _token) external {
        ERC20 token = ERC20(_token);
        uint256 distribution = token.balanceOf(address(this)) / 2;

        token.transfer(recipients[0], distribution);
        token.transfer(recipients[1], distribution);
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenURISuffixes[tokenId]))
        : '';
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, HasSecondarySaleFees)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}

