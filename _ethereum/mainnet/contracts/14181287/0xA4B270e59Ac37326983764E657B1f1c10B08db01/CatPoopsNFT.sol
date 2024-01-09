//SPDX-License-Identifier: MIT
//solhint-disable no-empty-blocks

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CatPoopsNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    address public constant CREATOR = 0xD3fB3e29D50Ab272F244619F6bc773583A0242AE;
    address public constant DEV = 0xC2a8814258F0bb54F9CC1Ec6ACb7a6886097b994;

    modifier onlyAllowed() {
        require(msg.sender == owner() || msg.sender == DEV, "not-allowed");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {

        baseURI = "https://nft-cdn-catpoops-ggy6xprbuq-ez.a.run.app/meta/";

        for (uint256 i = 0; i < 36; i++)
            _safeMint(CREATOR, totalSupply());

        _transferOwnership(CREATOR);
    }

    mapping(address => uint256) private maxMintsPerAddress;
    mapping(uint256 => uint256) public mintDate;

    //solhint-disable var-name-mixedcase 
    uint256 public MINT_PRICE = 0.07 ether;
    uint256 public MAX_TOTAL_SUPPLY = 1035;
    uint256 public MAX_MINT_LIMIT = 5;

    bool public publicSale = true;
    bool public isBaseURILocked = false;

    string private baseURI;

    address[] public teamPayments = [
        CREATOR, // Creator
        DEV // Dev
    ];

    uint256[] public teamPaymentShares = [
        500, // Creator: 50%
        500 // Dev: 50%
    ];

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (from == address(0)) {
            mintDate[tokenId] = block.timestamp;
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isRevealed(uint256 tokenId) external view returns (bool) {
        if (mintDate[tokenId] == 0) return false;
        else {
            if (block.timestamp - mintDate[tokenId] > 24 hours) return true;
            return false;
        }
    }

    function setBaseURI(string memory _newURI) external onlyAllowed {
        require(!isBaseURILocked, "locked-base-uri");
        baseURI = _newURI;
    }

    function setMintPrice(uint256 _newPrice) external onlyAllowed {
        MINT_PRICE = _newPrice;
    }

    function setMaxSupply(uint256 _newLimit) external onlyAllowed {
        MAX_TOTAL_SUPPLY = _newLimit;
    }

    function setMaxMintLimit(uint256 _newLimit) external onlyAllowed {
        MAX_MINT_LIMIT = _newLimit;
    }

    function withdraw() public onlyAllowed {
        uint256 _balance = address(this).balance;
        for (uint256 i = 0; i < teamPayments.length; i++) {
            uint256 _shares = (_balance / 1000) * teamPaymentShares[i];
            uint256 _currentBalance = address(this).balance;
            _shares = (_shares < _currentBalance) ? _shares : _currentBalance;
            payable(teamPayments[i]).transfer(_shares);
        }
    }

    function flipSaleState() public onlyAllowed {
        publicSale = !publicSale;
    }

    function lockBaseURI() public onlyAllowed {
        isBaseURILocked = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "non-existent-token");
        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId.toString()));
    }

    function mintTo(address _to, uint256 _numberOfTokens) external onlyAllowed {
        for (uint256 i = 0; i < _numberOfTokens; i++)
            _safeMint(_to, totalSupply());
    }

    function mint(uint256 _numberOfTokens) public payable {
        require(publicSale, "sale-not-active");
        require(
            _numberOfTokens > 0 && _numberOfTokens <= MAX_MINT_LIMIT,
            "mint-number-out-of-range"
        );
        require(
            msg.value == MINT_PRICE * _numberOfTokens,
            "incorrect-ether-value"
        );
        require(
            maxMintsPerAddress[msg.sender] + _numberOfTokens <= MAX_MINT_LIMIT,
            "max-mint-limit"
        );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_TOTAL_SUPPLY) {
                _safeMint(msg.sender, totalSupply());
                maxMintsPerAddress[msg.sender]++;
            } else {
                payable(msg.sender).transfer(
                    (_numberOfTokens - i) * MINT_PRICE
                );
                break;
            }
        }
    }
}
