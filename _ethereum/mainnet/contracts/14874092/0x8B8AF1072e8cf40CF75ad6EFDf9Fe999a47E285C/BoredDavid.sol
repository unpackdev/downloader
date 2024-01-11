// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";

contract BoredDavid is
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    event AirdropClaimed(
        address indexed user,
        uint256 indexed tokenId,
        uint8 indexed rarity
    );
    event OwnerMint(
        address indexed user,
        uint256 indexed tokenId,
        uint8 indexed rarity
    );
    event UserMint(
        address indexed user,
        uint256 indexed tokenId,
        uint8 indexed rarity
    );

    using Strings for uint256;

    uint256 public rareCost;
    uint256 public commonCost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    uint256 public startingTokenId;

    bool public paused;
    bool public commonSaleEnabled;
    bool public rareSaleEnabled;

    mapping(address => bool) public eligibleForAirdrop;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initNotRevealedUri,
        uint256 _rareCost,
        uint256 _commonCost,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        uint256 _startingTokenId,
        bool _commonSaleEnabled,
        bool _rareSaleEnabled
    ) ERC721(_name, _symbol) {
        setNotRevealedURI(_initNotRevealedUri);
        rareCost = _rareCost;
        commonCost = _commonCost;
        maxSupply = _maxSupply;
        maxMintAmount = _maxMintAmount;
        startingTokenId = _startingTokenId;
        commonSaleEnabled = _commonSaleEnabled;
        rareSaleEnabled = _rareSaleEnabled;
    }

    function claimAirdrop() external {
        require(
            eligibleForAirdrop[msg.sender] == true,
            "Only listed users can mint it once"
        );
        eligibleForAirdrop[msg.sender] = false;
        uint256 supply = totalSupply();
        require(!paused);
        require(supply + 1 <= maxSupply);

        uint256 tokenId = startingTokenId + supply + 1;
        _safeMint(msg.sender, tokenId);
        //_setTokenURI(tokenId, notRevealedUri);
        emit AirdropClaimed(msg.sender, tokenId, 0);
    }

    function _mintToken(uint256 _mintAmount, uint8 rarity) internal {
        uint256 supply = totalSupply();
        require(!paused, "Contract must be unpaused");
        require(_mintAmount > 0, "Mint amount must be more than 0");
        require(
            msg.sender == owner() || _mintAmount <= maxMintAmount,
            "Mint amount must be less than or equal to maxMintAmount"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "Mint amount must be less than or equal to maxSupply"
        );

        uint256 newTokenId = startingTokenId + supply;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, newTokenId + i);
            //_setTokenURI(newTokenId + i, notRevealedUri);
            if (msg.sender != owner()) {
                emit UserMint(msg.sender, newTokenId + i, rarity);
            } else {
                emit OwnerMint(msg.sender, newTokenId + i, rarity);
            }
        }
    }

    function mintCommon(uint256 _mintAmount) external payable {
        require(commonSaleEnabled, "Sale not enabled yet");
        if (msg.sender != owner()) {
            require(
                msg.value >= commonCost * _mintAmount,
                "Need appropriate amount of eth"
            );
        }
        _mintToken(_mintAmount, 0);
    }

    function mintRare(uint256 _mintAmount) external payable {
        require(rareSaleEnabled, "Sale not enabled yet");
        if (msg.sender != owner()) {
            require(
                msg.value >= rareCost * _mintAmount,
                "Need appropriate amount of eth"
            );
        }
        _mintToken(_mintAmount, 1);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Only owner can access these
    function addAddressesToAirdrop(address[] memory _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            eligibleForAirdrop[_users[i]] = true;
        }
    }

    function removeAddressesToAirdrop(address[] memory _users)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _users.length; i++) {
            eligibleForAirdrop[_users[i]] = false;
        }
    }

    //unveilNFTs

    // One will accept a batch of nfts.

    // Parameters: 2 arrays, one for token ids and one for token uris. You can update it more than once.

    function unveilNFTs(uint256[] memory tokenIds, string[] memory uris)
        external
        onlyOwner
    {
        require(
            tokenIds.length == uris.length,
            "Parameters Arrays should have the same length"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            string memory uri = uris[i];
            if (bytes(_tokenURIs[tokenId]).length == 0) {
                _setTokenURI(tokenId, uri);
            }
        }
    }

    function setRareCost(uint256 _newCost) external onlyOwner {
        rareCost = _newCost;
    }

    function setCommonCost(uint256 _newCost) external onlyOwner {
        commonCost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function enableCommonSale(bool _state) external onlyOwner {
        commonSaleEnabled = _state;
    }

    function enableRareSale(bool _state) external onlyOwner {
        rareSaleEnabled = _state;
    }

    function withdraw() external onlyOwner {
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
    }
}
