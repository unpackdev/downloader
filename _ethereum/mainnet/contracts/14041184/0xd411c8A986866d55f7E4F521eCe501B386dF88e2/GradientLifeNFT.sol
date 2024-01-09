// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract GradientLifeNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public defaultURI;
    uint256 public revealedProgress = 0;
    uint256 public generalCost = 0.07 ether;
    uint256 public whitelistCost = 0.05 ether;
    uint256 public maxSupply = 10000;
    uint256 public mintPerAddressLimit = 5;
    uint256 public maxMintPerTransaction = 5;
    uint256 public reserved = 300;
    bool public paused = false;
    bool public hasWhitelist = true;

    address public owner1 = 0x5E2448CE7bfAebE840e6E6dd2600c0aa9D88f4F7;
    address public owner2 = 0xAE175b64cE7C4Df5cf3e07bb28Bcbaea847F3683;

    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setDefaultURI(_initNotRevealedUri);

        _safeMint(owner1, 0);
        _safeMint(owner2, 1);
        addressMintedBalance[owner1]++;
        addressMintedBalance[owner2]++;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function MintCollectible(uint256 mint) public payable {
        require(!paused, "the contract is paused");
        require(mint > 0, "need to mint at least 1 NFT");
        require(
            mint <= maxMintPerTransaction,
            "maximum mint per transaction exceed"
        );
        uint256 supply = totalSupply();
        require(
            supply + mint <= maxSupply - reserved,
            "max NFT limit exceeded"
        );

        if (msg.sender != owner()) {
            if (mintPerAddressLimit > 0) {
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(
                    ownerMintedCount + mint <= mintPerAddressLimit,
                    "max mint per address exceeded"
                );
            }
            if (hasWhitelist) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
            }
            uint256 price = getPrice(msg.sender);
            require(msg.value >= price * mint, "insufficient funds");
        }

        for (uint256 i = 0; i < mint; i++) {
            _safeMint(msg.sender, (supply + i));
            addressMintedBalance[msg.sender]++;
        }
    }

    function isWhitelisted(address _check) public view returns (bool) {
        bool result = whitelistedAddresses[_check];
        return result;
    }

    function getPrice(address _check) public view returns (uint256) {
        if (isWhitelisted(_check)) {
            return whitelistCost;
        } else {
            return generalCost;
        }
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

        if (tokenId < revealedProgress) {
            string memory currentBaseURI = _baseURI();
            if (bytes(currentBaseURI).length > 0) {
                return
                    string(
                        abi.encodePacked(
                            currentBaseURI,
                            tokenId.toString(),
                            baseExtension
                        )
                    );
            } else {
                return
                    string(
                        abi.encodePacked(
                            defaultURI,
                            tokenId.toString(),
                            baseExtension
                        )
                    );
            }
        } else {
            return
                string(
                    abi.encodePacked(
                        defaultURI,
                        tokenId.toString(),
                        baseExtension
                    )
                );
        }
    }

    //ONLY OWNER

    //mint _amount amount of LIFE for to an address
    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(_amount > 0, "need to mint at least 1 NFT");
        require(_amount <= reserved, "Exceeds reserved supply");

        uint256 supply = totalSupply();
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, (supply + i));
        }
        reserved -= _amount;
    }

    function givewayForAll(address[] memory _to) external onlyOwner {
        require(_to.length > 0, "need to mint at least 1 NFT");
        require(_to.length <= reserved, "Exceeds reserved supply");

        uint256 supply = totalSupply();
        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], (supply + i));
        }
        reserved -= _to.length;
    }

    function setRevealedProgress(uint256 _set) public onlyOwner {
        revealedProgress = _set;
    }

    function setCost(uint256 _setGenral, uint256 _setWhitelist)
        public
        onlyOwner
    {
        generalCost = _setGenral;
        whitelistCost = _setWhitelist;
    }

    function setmaxMintPerTransaction(uint256 _set) public onlyOwner {
        maxMintPerTransaction = _set;
    }

    function setBaseURI(string memory _set) public onlyOwner {
        baseURI = _set;
    }

    function setBaseExtension(string memory _set) public onlyOwner {
        baseExtension = _set;
    }

    function setDefaultURI(string memory _set) public onlyOwner {
        defaultURI = _set;
    }

    function pause(bool _set) public onlyOwner {
        paused = _set;
    }

    function setOnlyWhitelisted(bool _set) public onlyOwner {
        hasWhitelist = _set;
    }

    function addWhitelist(address[] memory _add) public onlyOwner {
        for (uint256 i = 0; i < _add.length; i++) {
            whitelistedAddresses[_add[i]] = true;
        }
    }

    function removeWhitelist(address[] memory _remove) public onlyOwner {
        for (uint256 i = 0; i < _remove.length; i++) {
            whitelistedAddresses[_remove[i]] = false;
        }
    }

    function setMintPerAddressLimit(uint256 _limit) public onlyOwner {
        mintPerAddressLimit = _limit;
    }

    function withdrawAll() public onlyOwner {
        uint256 amount = address(this).balance / 2;
        require(amount > 0);
        _widthdraw(owner1, amount);
        _widthdraw(owner2, amount);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function setGradientLifeOwner(address _set1, address _set2)
        public
        onlyOwner
    {
        owner1 = _set1;
        owner2 = _set2;
    }
}
