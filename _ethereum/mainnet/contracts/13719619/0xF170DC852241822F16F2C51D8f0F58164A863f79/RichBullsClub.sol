// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract RichBulls is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    string public whitelistNotRevealedUri;

    uint256 public maxSupply = 9999;
    uint256 public mintedSupply = 0;
    uint256 public mintedPresaleSupply = 0;
    uint256 public maxPresaleSupply = 1000;

    uint256 public maxWhitelistNfts = 1;
    uint256 public maxVipNfts = 1;

    bool public paused = true;
    bool public revealed = false;

    uint256 public presaleCost = 0.15 ether;
    uint256 public publicCost = 0.3 ether;

    bool public whitelistMint = false;
    bool public vipMint = false;
    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;
    address whitelistWallet;
    bool public airdropped = false;
    mapping(uint256 => address) public whitelistTokensOwners;
    uint256[] public whitelistTokens;
    address[] public vipAddresses;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        string memory _initWhitelistNotRevealedUri,
        address _whitelistWallet
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        whitelistWallet = _whitelistWallet;
        setNotRevealedURI(_initNotRevealedUri);
        setWhitelistNotRevealedURI(_initWhitelistNotRevealedUri);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function presaleMint(uint256 _mintAmount) public payable {
        require(!paused, "The contract is paused");
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(whitelistMint == true || vipMint == true, "Presale is closed.");
        require(
            mintedSupply + _mintAmount <= maxSupply,
            "Max NFT limit exceeded"
        );
        require(
            mintedPresaleSupply + _mintAmount <= maxPresaleSupply,
            "Max Presale NFT limit exceeded"
        );
        require(
            (whitelistMint && isWhitelisted(msg.sender)) || (vipMint && isVip(msg.sender)),
            "User is not eligible to the Presale"
        );
        require(msg.value >= presaleCost * _mintAmount, "Insufficient funds");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(
            (!isVip(msg.sender) ||
                (ownerMintedCount + _mintAmount <= maxVipNfts)),
            "Max NFT per address exceeded"
        );
        require(
            (!isWhitelisted(msg.sender) ||
                (ownerMintedCount + _mintAmount <= maxWhitelistNfts)),
            "Max NFT per address exceeded"
        );
        mintedPresaleSupply += _mintAmount;

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            uint256 tokenId = mintedSupply + i;
            if (isWhitelisted(msg.sender)) {
                _safeMint(whitelistWallet, tokenId);
                whitelistTokensOwners[tokenId] = msg.sender;
                whitelistTokens.push(tokenId);
            } else {
                _safeMint(msg.sender, tokenId);
            }
        }
        mintedSupply += _mintAmount;
    }

    function mint(uint256 _mintAmount) public payable {
        require(!paused, "The contract is paused");
        require(whitelistMint == false && vipMint == false, "Public sale is not open yet.");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "Collection is sold out");

        require(msg.value >= publicCost * _mintAmount, "Insufficient funds");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            uint256 tokenId = supply + i;
            _safeMint(msg.sender, tokenId);
        }
        mintedSupply += _mintAmount;
    }

    function totalSupply() public view override returns (uint256) {
        return mintedSupply;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isVip(address _user) public view returns (bool) {
        for (uint256 i = 0; i < vipAddresses.length; i++) {
            if (vipAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isWhitelistToken(uint256 tokenId) public view returns (bool) {
        for (uint256 i = 0; i < whitelistTokens.length; i++) {
            if (whitelistTokens[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

        if (revealed == false) {
            if (isWhitelistToken(tokenId)) {
                return whitelistNotRevealedUri;
            }
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function airdropWhitelistTokens() public onlyOwner {
        require(!airdropped, "Whitelist Tokens have already been airdroped.");
        require(!paused, "The contract is paused");
        require(!whitelistMint, "Whitelist sale is still running");
        airdropped = true;
        for (uint256 i; i < whitelistTokens.length; i++) {
            transferFrom(
                whitelistWallet,
                whitelistTokensOwners[whitelistTokens[i]],
                whitelistTokens[i]
            );
        }
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setWhitelistNotRevealedURI(string memory _whitelistNotRevealedURI)
        public
        onlyOwner
    {
        whitelistNotRevealedUri = _whitelistNotRevealedURI;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function toggleWhitelistMint(bool _state) public onlyOwner {
        whitelistMint = _state;
    }

    function toggleVipMint(bool _state) public onlyOwner {
        vipMint = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function vipUsers(address[] calldata _users) public onlyOwner {
        delete vipAddresses;
        vipAddresses = _users;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}