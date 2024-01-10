// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//            _           __    __  __  _____
//   /\/\    /_\  /\ /\  / /   /__\/__\/ _  /
//  /    \  //_\\/ / \ \/ /   /_\ / \//\// /
// / /\/\ \/  _  \ \_/ / /___//__/ _  \ / //\
// \/    \/\_/ \_/\___/\____/\__/\/ \_//____/
// =====  Maulerz by Mincent man Gogh  ======

// dev @nftchef

import "./Pausable.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Maulerz is
    ERC721A,
    Ownable,
    Pausable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;

    uint128 public SUPPLY = 10000;
    uint128 public MINT_LIMIT = 10;
    uint128 public PRICE = 0.02 ether;

    /// @dev enforce a per-address lifetime limit based on the mintBalances mapping
    bool public walletLimit = true;

    string public PROVENANCE_HASH; // keccak256

    mapping(address => uint256) public mintBalances;

    string internal baseTokenURI;
    address[] internal payees;

    constructor(
        string memory _initialURI,
        address[] memory _payees,
        uint256[] memory _shares
    )
        payable
        ERC721A("Maulerz", "MLRZ")
        Pausable()
        PaymentSplitter(_payees, _shares)
    {
        payees = _payees;
        baseTokenURI = _initialURI;
    }

    function purchase(uint256 _quantity)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        require(_quantity <= MINT_LIMIT, "Quantity exceeds MINT_LIMIT");
        if (walletLimit) {
            require(
                _quantity + mintBalances[msg.sender] <= MINT_LIMIT,
                "Quantity exceeds per-wallet limit"
            );
        }

        require(_quantity * PRICE <= msg.value, "Not enough minerals");

        require(
            _quantity + totalSupply() <= SUPPLY,
            "Purchase exceeds available supply"
        );

        _safeMint(msg.sender, _quantity);
        mintBalances[msg.sender] += _quantity;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), '"ERC721Metadata: tokenId does not exist"');
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    //----------------------------------------------------------------------------
    // Only Owner
    //----------------------------------------------------------------------------

    // @dev gift a single token to each address passed in through calldata
    // @param _recipients Array of addresses to send a single token to
    function gift(address[] calldata _recipients) external onlyOwner {
        uint256 recipients = _recipients.length;
        require(
            recipients + totalSupply() <= SUPPLY,
            "_quantity exceeds supply"
        );

        for (uint256 i = 0; i < recipients; i++) {
            _safeMint(_recipients[i], 1);
        }
    }

    function setPaused(bool _state) external onlyOwner {
        _state ? _pause() : _unpause();
    }

    function setWalletLimit(bool _state) external onlyOwner {
        walletLimit = _state;
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE_HASH = _provenance;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseTokenURI = _URI;
    }

    // @dev: blockchain is forever, you never know, you might need these...
    function setPrice(uint128 _price) external onlyOwner {
        PRICE = _price;
    }

    function setPublicLimit(uint128 _limit) external onlyOwner {
        MINT_LIMIT = _limit;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < payees.length; i++) {
            release(payable(payees[i]));
        }
    }
}
