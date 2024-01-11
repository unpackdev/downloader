// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC2981.sol";
import "./Strings.sol";

/// @title Objection Hearsay

contract OHearSayContract is
    ERC721A,
    IERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;

    string private baseURI = "ipfs://QmaGBnt7rJemJCPSi8iYD3ZwUonyQptLaCFVe9UsnTZh8K/";
    uint256 public reservedTokensMinted = 0;

    constructor() ERC721A("OHearsay", "OHearsay") {}

    function mint(
        uint256 numberOfTokens
    )
        external
        payable
        isCorrectPayment(numberOfTokens)
        isSupplyRemaining(numberOfTokens)
        nonReentrant
        whenNotPaused
    {
        _mint(msg.sender, numberOfTokens);
    }

    function mintReservedToken(address to, uint256 numberOfTokens)
        external
        canReserveToken(numberOfTokens)
        isNonZero(numberOfTokens)
        nonReentrant
        onlyOwner
    {
        _safeMint(to, numberOfTokens);
        reservedTokensMinted = reservedTokensMinted + numberOfTokens;
    }


    function withdraw() external onlyOwner {
        // This is a test to ensure we have atleast withdrawn the amount once in production.
        payable(owner()).transfer(address(this).balance);
    }


    /**
        We want our tokens to start at 1 not zero.
    */
    function _startTokenId() 
        internal 
        view 
        virtual 
        override 
        returns (uint256) 
    {
        return 1;
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }
    function contractURI() 
        external
        pure 
        returns 
        (string memory) 
    {
        return "ipfs://QmWAE99cLh6fA7Ap3Vy8FfjFthDATnR2X61K5X7EQcsiN8";
    }

    function numberMinted(address owner) 
        public 
        view 
        returns 
        (uint256) 
    {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) 
        public 
        onlyOwner 
    {
        baseURI = _newBaseURI;
    }

    function pause() 
        external 
        onlyOwner 
    {
        _pause();
    }

    function unpause() 
        external 
        onlyOwner 
    {
        _unpause();
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) 
        public 
        override 
        view 
        returns 
        (bool isOperator) 
    {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721A.isApprovedForAll(_owner, _operator);
    }

    function royaltyInfo(
        uint256, /*_tokenId*/
        uint256 _salePrice
    )
        external
        view
        override(IERC2981)
        returns (address Receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * 10) / 100);
    }

    modifier canReserveToken(uint256 numberOfTokens) {
        require(
            reservedTokensMinted + numberOfTokens <= 10,
            "Cannot reserve more than 10 tokens"
        );
        _;
    }

    modifier isCorrectPayment(
        uint256 numberOfTokens
    ) {
        require(
            0.015 ether * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isSupplyRemaining(uint256 numberOfTokens) {
        require(
            totalSupply() + numberOfTokens <=
                1984 - (10 - reservedTokensMinted),
            "Purchase would exceed max supply"
        );
        _;
    }

    modifier isNonZero(uint256 num) {
        require(num > 0, "Parameter value cannot be zero");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}
