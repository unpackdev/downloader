// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//   _  _  ___  _  _ _____   __  ___   _   ___   ___ ___ ___  ___    ___ _   _   _ ___
//  | || |/ _ \| \| | __\ \ / / | _ ) /_\ |   \ / __| __| _ \/ __|  / __| | | | | | _ )
//  | __ | (_) | .` | _| \ V /  | _ \/ _ \| |) | (_ | _||   /\__ \ | (__| |_| |_| | _ \
//  |_||_|\___/|_|\_|___| |_|   |___/_/ \_\___/ \___|___|_|_\|___/  \___|____\___/|___/
//
/// @creator:   HoneyBadgersClub
/// @author:    salih.eth

import "./ERC721.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract HoneyBadgersClub is ERC721, Ownable, PaymentSplitter {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public merkleRoot;
    address proxyRegistryAddress;

    string public BASE_URI;

    uint256 constant MINT_PRICE = 0.077 ether;
    uint256 constant TOTAL_SUPPLY = 9999;

    uint256 public RESERVED = 150;

    bool public IS_PRESALE_ACTIVE = false;
    bool public IS_PUBLIC_SALE_ACTIVE = false;

    mapping(address => uint256) mintCountByAddress;

    address[] private payeeAddresses = [
        0x3388B1edDC683857Df7B048B5E85Ed4872731445, // Team 1
        0x886c0Ea23312E814108e44caAeB2424bbff3c01E, // Team 2
        0xA75Dec79F464212d27f9b0714AEADaFBA0E02cf4, // Team 3
        0xC3c98CF752190A3244c4Dd204f472E5ABeA11904, // Team 4
        0x7cfe810CDae2F10Da2f51294B5B2C21715428966, // Community Wallet
        0x987992cDB23ffAaCbA0fC4a5463a20A4c8782cB6 // Charity
    ];

    uint256[] private payeeShares = [40, 39, 5, 1, 10, 5];

    constructor(string memory _newURI, address _proxyRegistryAddress)
        ERC721("Honey Badgers Club", "HBC")
        PaymentSplitter(payeeAddresses, payeeShares)
    {
        setBaseURI(_newURI);
        proxyRegistryAddress = _proxyRegistryAddress;
        _tokenIdCounter.increment();
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory newUri) public onlyOwner {
        BASE_URI = newUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function togglePreSale() public onlyOwner {
        IS_PRESALE_ACTIVE = !IS_PRESALE_ACTIVE;
    }

    function togglePublicSale() public onlyOwner {
        IS_PUBLIC_SALE_ACTIVE = !IS_PUBLIC_SALE_ACTIVE;
    }

    modifier onlyAccounts() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function preSaleMint(
        address _account,
        uint256 _numberOfTokens,
        bytes32[] calldata _proof
    ) public payable onlyAccounts {
        require(msg.sender == _account, "Not allowed");
        require(IS_PRESALE_ACTIVE, "Pre Sale paused");
        require(
            mintCountByAddress[msg.sender] + _numberOfTokens <= 4,
            "You can mint 2 tokens per address on pre sale"
        );
        require(
            msg.value >= _numberOfTokens * MINT_PRICE,
            "Ether sent is not correct"
        );

        bytes32 leaf = keccak256(abi.encode(msg.sender));
        require(
            MerkleProof.verify(_proof, merkleRoot, leaf),
            "invalid merkle proof"
        );

        uint256 current = _tokenIdCounter.current();
        require(
            current + _numberOfTokens < TOTAL_SUPPLY - RESERVED,
            "Exceeds max token supply"
        );

        mintCountByAddress[msg.sender] += _numberOfTokens;

        for (uint256 i; i < _numberOfTokens; i++) {
            mintInternal(msg.sender);
        }
    }

    function publicSaleMint(uint256 _numberOfTokens)
        public
        payable
        onlyAccounts
    {
        uint256 current = _tokenIdCounter.current();

        // sale must be active
        require(IS_PUBLIC_SALE_ACTIVE, "Sale paused");

        // max 10 tokens per tx
        require(_numberOfTokens <= 10, "You can mint 10 tokens per tx");

        // max 20 per address
        require(
            mintCountByAddress[msg.sender] + _numberOfTokens <= 20,
            "You can mint 20 tokens per address"
        );

        // ether value
        require(
            msg.value >= _numberOfTokens * MINT_PRICE,
            "Ether sent is not correct"
        );

        // if exceeds
        require(
            current + _numberOfTokens < TOTAL_SUPPLY - RESERVED,
            "Exceeds max token supply"
        );

        // increade mint count of address
        mintCountByAddress[msg.sender] += _numberOfTokens;

        for (uint256 i; i < _numberOfTokens; i++) {
            mintInternal(msg.sender);
        }
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= RESERVED, "Exceeds reserved token supply");

        for (uint256 i; i < _amount; i++) {
            mintInternal(_to);
        }

        RESERVED -= _amount;
    }

    function mintInternal(address _to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current() - 1;
    }

    function tokensOfOwner(
        address _owner,
        uint256 startId,
        uint256 endId
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw.");

        for (uint256 i = 0; i < payeeAddresses.length; i++) {
            release(payable(payee(i)));
        }
    }
}
