/**
 * @title SunMoony contract
 * @dev Extends ERC721 Non-Fungible Token Standard Basic Implementation
 */

/**
 *  SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SunMoony is ERC721Enumerable, Ownable {
    using Strings for uint256;

    event Minted(address indexed to, uint256 indexed tokenId);

    string private _baseTokenURI;

    uint256 public constant SALE_PRICE = 0.07 ether;
    uint256 public constant MAX_SALE_PURCHASE = 10;
    uint256 public constant MAX_TOKENS = 3000;
    bool public saleIsActive;
    bool public saleIsFinished;

    mapping(address => uint256) public referrals;
    mapping(uint256 => address) public referrers;
    uint256 public referrersCount = 0;

    constructor() ERC721("SunMoony", "SNM") {
        saleIsActive = false;
        saleIsFinished = false;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
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
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function startSale() external onlyOwner {
        require(saleIsActive == false, "Sale is started");
        saleIsActive = true;
    }

    function pauseSale() external onlyOwner {
        require(saleIsActive == true, "Sale is paused");
        saleIsActive = false;
    }

    function finishSale() external onlyOwner {
        saleIsFinished = true;
    }

    function mintSale(uint256 numberOfTokens, address referrer)
        external
        payable
    {
        require(saleIsActive == true, "Sale must be active to mint tokens");
        require(numberOfTokens > 0, "At least one token must be minted");
        require(
            numberOfTokens <= MAX_SALE_PURCHASE,
            "Exceeded max token purchase"
        );
        require(
            totalSupply() + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of tokens"
        );
        require(
            SALE_PRICE * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
            emit Minted(msg.sender, supply + i);
        }

        addReferral(referrer, numberOfTokens);
    }

    function addReferral(address referrer, uint256 tokensCount) private {
        if (referrals[referrer] == 0) {
            referrers[referrersCount] = referrer;
            referrersCount += 1;
        }

        referrals[referrer] += tokensCount;
    }

    function withdrawReferrer() external {
        require(saleIsFinished == true, "Sale must be finished to withdraw");
        uint256 amount = referrals[msg.sender] * SALE_PRICE * 3 / 10;
        payable(msg.sender).transfer(amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
