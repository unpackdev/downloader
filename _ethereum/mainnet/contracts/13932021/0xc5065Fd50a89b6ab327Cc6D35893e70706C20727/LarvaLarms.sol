// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./OpenSea.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";

contract LarvaLarms is ERC721Enumerable, OpenSea, Ownable, PaymentSplitter {
    using Strings for uint256;

    string private _baseTokenURI;
    string private _tokenURISuffix;

    uint256 public price = 11100000000000000; // 0.0111 ETH
    uint256 public constant MAX_SUPPLY = 3335;
    uint256 public maxPerTx = 20;

    bool public started = false;

    constructor(
        address openSeaProxyRegistry,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC721("LarvaLarms", "LarvaLarms") PaymentSplitter(_payees, _shares) {
        if (openSeaProxyRegistry != address(0)) {
            _setOpenSeaRegistry(openSeaProxyRegistry);
        }
    }

    function mint(uint256 count) public payable {
        require(started, "Minting not started");
        require(count <= maxPerTx, "Exceed max per transaction");
        uint256 supply = _owners.length;
        require(supply + count < MAX_SUPPLY, "Max supply reached");
        if (supply < 2223 && supply + count > 2223) {
            uint256 payCount = supply + count - 2223;
            require(payCount * price == msg.value, "Invalid funds provided.");
        } else if (supply >= 2223) {
            require(count * price == msg.value, "Invalid funds provided.");
        }
        for (uint256 i; i < count; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
    }

    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix)
        external
        onlyOwner
    {
        _baseTokenURI = _newBaseURI;
        _tokenURISuffix = _newSuffix;
    }

    function toggleStarted() external onlyOwner {
        started = !started;
    }

    function airdrop(uint256[] calldata quantity, address[] calldata recipient)
        external
        onlyOwner
    {
        require(
            quantity.length == recipient.length,
            "Quantity length is not equal to recipients"
        );

        uint256 totalQuantity = 0;
        for (uint256 i = 0; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }

        uint256 supply = _owners.length;
        require(supply + totalQuantity <= MAX_SUPPLY, "Max supply reached");

        delete totalQuantity;

        for (uint256 i = 0; i < recipient.length; ++i) {
            for (uint256 j = 0; j < quantity[i]; ++j) {
                _safeMint(recipient[i], supply++);
            }
        }
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(owner, operator) ||
            isOwnersOpenSeaProxy(owner, operator);
    }
}
