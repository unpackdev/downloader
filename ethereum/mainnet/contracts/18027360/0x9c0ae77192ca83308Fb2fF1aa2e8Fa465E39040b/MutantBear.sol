// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";

contract MutantBear is
    Ownable,
    ERC721A("Mutant Bear", "MB"),
    DefaultOperatorFilterer,
    ReentrancyGuard
{
    /**
     * @dev Emitted by mint.
     */
    event Mint(address[] indexed accounts, uint16[] indexed nums);

    uint16 public constant MAX_AMOUNT = 10000;

    uint16 public totalRemainCount = MAX_AMOUNT;

    // Metadata URI
    string public notRevealedURI;
    string public baseExtension = "";
    mapping(uint256 => string) private tokenBaseURI;

    // -------
    // Owner Functions
    // -------
    function setNotRevealedURI(string calldata _notRevealedURI)
        public
        onlyOwner
    {
        notRevealedURI = _notRevealedURI;
    }

    function setBaseExtension(string calldata _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setTokenBaseURI(
        uint16 start,
        uint16 end,
        string memory _baseTokenURI
    ) public onlyOwner {
        require(start > 0, "Start must be greater than 0");
        require(end <= MAX_AMOUNT, "End must be less than totalSupply");
        require(start <= end, "Start must be less than or equal to end");

        for (uint256 i = start; i <= end; i++) {
            tokenBaseURI[i] = _baseTokenURI;
        }
    }

    // -------
    // Mint function
    // -------
    function mint(address[] memory accounts, uint16[] memory nums)
        public
        onlyOwner
    {
        require(
            accounts.length > 0 && accounts.length == nums.length,
            "Length not match"
        );

        uint16 mintNum = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            mintNum += nums[i];
        }

        require(totalRemainCount - mintNum >= 0, "No more NFT");

        totalRemainCount -= mintNum;
        for (uint256 i = 0; i < accounts.length; i++) {
            _safeMint(accounts[i], nums[i]);
        }
        emit Mint(accounts, nums);
    }

    // -------
    // Internal Overrides
    // -------
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // -------
    // Metadata Reveal Override
    // -------
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721aMetadata: URI query for nonexistent token"
        );
        string memory _baseTokenURI = tokenBaseURI[_tokenId];
        if (bytes(_baseTokenURI).length <= 0) {
            return notRevealedURI;
        }
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    _toString(_tokenId),
                    baseExtension
                )
            );
    }

    // -------
    // Opensea OperatorFilterer Overrides
    // -------
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
