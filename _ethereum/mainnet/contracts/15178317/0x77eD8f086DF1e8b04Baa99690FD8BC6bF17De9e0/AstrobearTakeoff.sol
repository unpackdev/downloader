// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Owned.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

// @title Contract for Astrobear Spaceclub - The Takeoff
// @author Kevin Mauel | What The Commit <https://what-the-commit.com>
contract AstrobearTakeoff is ERC721, Owned, PaymentSplitter, ReentrancyGuard {
    error SaleNotStarted();
    error NotPartOfList();
    error PaymentNotCorrect();
    error AlreadyMintedMaxAmount();
    error NoSupplyLeft();
    error NotOwnerOfToken();
    error AlreadyClaimedSculpture();

    uint256 public constant reservedSupply = 15;
    uint256 public constant totalSupply = 1969 - reservedSupply;
    uint256 public mintedSupply = 0;
    uint256 public mintedSupplyOwner = 0;

    uint8 public constant maxMintPerWallet = 4;

    mapping(uint256 => bool) public claimedSculpture;

    mapping(address => uint256) public genesisAddresses;
    mapping(address => uint256) public whitelistAddresses;

    mapping(address => uint256) public genesisAddressesMinted;
    mapping(address => uint256) public whitelistAddressesMinted;
    mapping(address => uint256) public publicAddressesMinted;

    string public baseUri;
    string public baseUriClaimed;

    uint256 public immutable salePriceGenesis;
    uint256 public immutable salePriceWhitelist;
    uint256 public immutable salePricePublic;

    enum SaleState {
        Genesis,
        Whitelist,
        Public,
        Ended
    }

    SaleState public saleState = SaleState.Ended;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory payees,
        uint256[] memory shares,
        uint256 _salePriceGenesis,
        uint256 _salePriceWhitelist,
        uint256 _salePricePublic,
        string memory _baseUri
    ) ERC721(_name, _symbol) Owned(msg.sender) PaymentSplitter(payees, shares) {
        baseUri = _baseUri;
        salePriceGenesis = _salePriceGenesis;
        salePriceWhitelist = _salePriceWhitelist;
        salePricePublic = _salePricePublic;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        if (claimedSculpture[id]) {
            return string(abi.encodePacked(baseUriClaimed, uint2str(id)));
        }

        return string(abi.encodePacked(baseUri, uint2str(id)));
    }

    function mint(uint256 amount) external payable nonReentrant {
        if (saleState == SaleState.Ended) revert SaleNotStarted();
        if (msg.value < salePriceGenesis * amount) revert PaymentNotCorrect();
        if (totalSupply <= mintedSupply + amount) revert NoSupplyLeft();

        if (saleState == SaleState.Genesis) {
            if (genesisAddressesMinted[msg.sender] + amount > genesisAddresses[msg.sender]) revert AlreadyMintedMaxAmount();

            for (uint i=0; i<amount; i++) {
                _mint(msg.sender, ++mintedSupply);
                ++genesisAddressesMinted[msg.sender];
            }

            return;
        }

        if (saleState == SaleState.Whitelist) {
            if (msg.value < salePriceWhitelist * amount) revert PaymentNotCorrect();
            if (whitelistAddressesMinted[msg.sender] + amount > whitelistAddresses[msg.sender]) revert AlreadyMintedMaxAmount();


            for (uint i=0; i<amount; i++) {
                _mint(msg.sender, ++mintedSupply);
                ++whitelistAddressesMinted[msg.sender];
            }

            return;
        }

        if (saleState == SaleState.Public) {
            if (msg.value < salePricePublic * amount) revert PaymentNotCorrect();
            if (publicAddressesMinted[msg.sender] + amount > maxMintPerWallet) revert AlreadyMintedMaxAmount();

            for (uint i=0; i<amount; i++) {
                _mint(msg.sender, ++mintedSupply);
                ++publicAddressesMinted[msg.sender];
            }
            return;
        }
    }

    function claimSculpture(uint256 tokenId) external {
        if (msg.sender != this.ownerOf(tokenId)) revert NotOwnerOfToken();
        if (claimedSculpture[tokenId]) revert AlreadyClaimedSculpture();

        claimedSculpture[tokenId] = true;
    }

    /// ========= Owner Functions ========
    function ownerMint(uint256 amount) external onlyOwner {
        if (mintedSupplyOwner + amount > reservedSupply) revert NoSupplyLeft();

        for (uint i=0; i<amount; i++) {
            _mint(msg.sender, totalSupply+i);
            ++mintedSupplyOwner;
        }
    }

    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    function setBaseUri(string memory newBaseUri) external onlyOwner {
        baseUri = newBaseUri;
    }

    function setBaseUriClaimed(string memory newBaseUriClaimed) external onlyOwner {
        baseUriClaimed = newBaseUriClaimed;
    }

    function addAddressesToGenesisList(address[] memory _genesisAddresses, uint256[] memory amount) external onlyOwner {
        unchecked {
            for (uint i=0; i<_genesisAddresses.length; i++) {
                genesisAddresses[_genesisAddresses[i]] = amount[i];
            }
        }
    }

    function changeAmountOfAddressInGenesisList(address genesisAddress, uint256 amount) external onlyOwner {
        genesisAddresses[genesisAddress] = amount;
    }

    function addAddressesToWhitelist(address[] memory _whitelistAddresses, uint256[] memory amount) external onlyOwner {
        unchecked {
            for (uint i=0; i<_whitelistAddresses.length; i++) {
                whitelistAddresses[_whitelistAddresses[i]] = amount[i];
            }
        }
    }

    function changeAmountOfAddressInWhitelist(address whitelistAddress, uint256 amount) external onlyOwner {
        whitelistAddresses[whitelistAddress] = amount;
    }

    /// ========= Internal Functions ========

    function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
