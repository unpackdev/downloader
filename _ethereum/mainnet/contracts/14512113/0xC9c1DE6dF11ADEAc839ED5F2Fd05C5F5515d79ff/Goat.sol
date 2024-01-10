// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./draft-ERC721Votes.sol";
import "./Counters.sol";
import "./ERC721Royalty.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

/// @custom:security-contact info@richgoatdao.com
contract RichGoatDAO is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable,
    EIP712,
    ERC721Votes,
    ERC721Royalty,
    VRFConsumerBaseV2
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    VRFCoordinatorV2Interface internal COORDINATOR;
    LinkTokenInterface internal LINKTOKEN;

    uint64 internal sSubscriptionId;

    //ETH Mainnet
    address internal constant VRFCOORDINATOR =
        0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address internal constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 internal constant KEYHASH =
        0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805;

    uint32 internal callbackGasLimit = 100000;
    uint16 internal requestConfirmations = 3;
    uint32 internal numWords = 1;

    uint256[] private _sRandomWords;
    uint256 private _sRequestId;

    uint256 public constant MAX_NFT_PURCHASE = 20;
    uint256 public constant MAX_NFTS = 10000;

    uint256 public goatPrice = 40000000000000000; //0.04 ETH

    bool private _reveal = false;
    bool private _sale = false;

    string private _contractURI;

    Counters.Counter private _tokenIdCounter;

    constructor(uint64 subscriptionId)
        VRFConsumerBaseV2(VRFCOORDINATOR)
        ERC721("RichGoatDAO", "RDF")
        EIP712("RichGoatDAO", "1")
    {
        _setDefaultRoyalty(msg.sender, 250);
        COORDINATOR = VRFCoordinatorV2Interface(VRFCOORDINATOR);
        LINKTOKEN = LinkTokenInterface(LINK);
        sSubscriptionId = subscriptionId;
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "ipfs://bafybeif4ozsvipb4ig6scnoq5rpi4nyq2cb6rpsr6f6vtcecjtygdygxhm/";
    }

    function setSale() public onlyOwner {
        _sale = true;
    }

    function setReveal() public onlyOwner {
        _reveal = true;
        _requestRandomWords();
    }

    function setPrice(uint256 price) public onlyOwner {
        require(!_sale, "Sale already started");
        goatPrice = price;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        uint256 id = 11000;
        if (_sRandomWords.length > 0) {
            id = SafeMath.add(_sRandomWords[0], tokenId);
            id = SafeMath.mod(id, 10000);
        }
        return
            _sRandomWords.length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(id)))
                : "ipfs://bafybeiedcm2rhuqzndm5jbjucfa2opctgnl5exfact4ianm5kwedaxo454";
    }

    function setContractURI(string memory _newURI) external onlyOwner {
        _contractURI = _newURI;
    }

    // For OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function safeMint(uint256 numberOfTokens) public payable {
        require(
            numberOfTokens <= MAX_NFT_PURCHASE,
            "Can only mint 20 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_NFTS,
            "Purchase would exceed max supply of Goats"
        );
        require(
            goatPrice.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );
        require(_sale, "_sale must be active to mint a Goat");

        _mintGoat(numberOfTokens);
    }

    function _mintGoat(uint256 numberOfTokens) private {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            if (totalSupply() < MAX_NFTS) {
                _tokenIdCounter.increment();
                _safeMint(msg.sender, tokenId);
            }
        }
        if ((totalSupply() == MAX_NFTS) && !_reveal) {
            _requestRandomWords();
        }
    }

    function ownerSafeMint(uint256 numberOfTokens) public onlyOwner {
        require(
            totalSupply().add(numberOfTokens) <= MAX_NFTS,
            "Purchase would exceed max supply of Goats"
        );
        _mintGoat(numberOfTokens);
    }

    function withdraw(address payable _to, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    // Assumes the subscription is funded sufficiently.
    function _requestRandomWords() private {
        // Will revert if subscription is not set and funded.
        _sRequestId = COORDINATOR.requestRandomWords(
            KEYHASH,
            sSubscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        _sRandomWords = randomWords;
        _reveal = true;
    }
}
