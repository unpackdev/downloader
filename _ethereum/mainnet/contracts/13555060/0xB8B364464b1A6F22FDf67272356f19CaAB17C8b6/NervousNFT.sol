pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./Counters.sol";
import "./SignatureChecker.sol";

//        nervous.eth
//
//      ██╗██╗   ██╗██╗ ██████╗███████╗     ██████╗██████╗ ███████╗██╗    ██╗
//      ██║██║   ██║██║██╔════╝██╔════╝    ██╔════╝██╔══██╗██╔════╝██║    ██║
//      ██║██║   ██║██║██║     █████╗      ██║     ██████╔╝█████╗  ██║ █╗ ██║
// ██   ██║██║   ██║██║██║     ██╔══╝      ██║     ██╔══██╗██╔══╝  ██║███╗██║
// ╚█████╔╝╚██████╔╝██║╚██████╗███████╗    ╚██████╗██║  ██║███████╗╚███╔███╔╝
//  ╚════╝  ╚═════╝ ╚═╝ ╚═════╝╚══════╝     ╚═════╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝
//
// ██╗  ██╗
// ╚██╗██╔╝
//  ╚███╔╝
//  ██╔██╗
// ██╔╝ ██╗
// ╚═╝  ╚═╝
//
// ███╗   ██╗███████╗██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗███████╗
// ████╗  ██║██╔════╝██╔══██╗██║   ██║██╔═══██╗██║   ██║██╔════╝
// ██╔██╗ ██║█████╗  ██████╔╝██║   ██║██║   ██║██║   ██║███████╗
// ██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║   ██║██║   ██║╚════██║
// ██║ ╚████║███████╗██║  ██║ ╚████╔╝ ╚██████╔╝╚██████╔╝███████║
// ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝   ╚═════╝  ╚═════╝ ╚══════╝
//
//        work with us: nervous.net // dylan@nervous.net

contract NervousNFT is ERC721, ERC721Enumerable, PaymentSplitter, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public MAX_TOKENS = 5555;
    uint256 public tokenPrice = 25000000000000000; //gwei
    bool public hasSaleStarted = false;
    string public baseURI;

    uint256 public MAX_GIFTS = 2000;
    uint256 public numberOfGifts;

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> dylan@nervous.net";

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        uint256 _maxTokens,
        uint256 _price,
        uint256 _maxGifts,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721(name, symbol) PaymentSplitter(payees, shares) {
        MAX_TOKENS = _maxTokens;
        MAX_GIFTS = _maxGifts;
        tokenPrice = _price;

        setBaseURI(_initBaseURI);
    }

    function calculatePrice() public view returns (uint256) {
        return tokenPrice; // 0.025 ETH
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function mint(uint256 numTokens) public payable {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(
            _tokenIds.current() + numTokens <= MAX_TOKENS,
            "Exceeds maximum token supply."
        );
        require(
            numTokens > 0 && numTokens <= 10,
            "Machine can dispense a minimum of 1, maximum of 10 tokens"
        );
        require(
            msg.value >= SafeMath.mul(calculatePrice(), numTokens),
            "Amount of Ether sent is not correct."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }

    /* Magic */

    function magicGift(address[] calldata receivers) external onlyOwner {
        require(
            _tokenIds.current() + receivers.length <= MAX_TOKENS,
            "Exceeds maximum token supply"
        );
        require(
            numberOfGifts + receivers.length <= MAX_GIFTS,
            "Exceeds maximum allowed gifts"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            numberOfGifts++;

            _safeMint(receivers[i], _tokenIds.current());
            _tokenIds.increment();
        }
    }

    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            _tokenIds.current() + numTokens <= MAX_TOKENS,
            "Exceeds maximum token supply."
        );
        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }

    /* URIs */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
