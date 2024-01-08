// SPDX-License-Identifier: MIT
/*
##      ## ##     ## ########  ##      ## ########  #######     #####   #######   ##       ######### #########
##      ## ####   ## ##     ## ##      ## ##        ##         ##   ##  ##     ## ##       ##        ##
##      ## ## ##  ## ########  ##      ## ##        ##        ###   ### #######   ##       #########  ####### 
##      ## ##  ## ## ##   ##   ##      ## ##    ### ##    ### ## ### ## ##     ## ##       ##               ##
 ##    ##  ##   #### ##    ##   ##    ##  ##     ## ##     ## ##     ## ##     ## ##       ##               ##
   ####    ##     ## ##     ##    ####    ######### ######### ##     ## #######   ######## ######### ########
*/
pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

import "CommunityOwnable.sol";

contract WGMINFT is ERC721Enumerable, CommunityOwnable, Ownable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = "";
    string public notRevealedUri;
    uint256 public cost = 0.06 ether;
    uint256 public maxSupply = 887;
    uint256 public nftPerAddressLimit = 20;
    uint256 public whitelistNftPerAddressLimit = 20;
    bool public paused = false;
    bool public revealed = false;
    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;
    address[] public devAddresses = [0xa9476058979176694E16B8eC62A170334553A45c, 0x4F17562C9a6cCFE47c3ef4245eb53c047Cb2Ff1D];
    mapping(address => uint256) public addressMintedBalance;
    address public guille23Address = 0x53Bf851448571A7a1f190AcA5f27A8d33e353df8;
    address public withdrawAddress = 0xF18668d5A3246202029E134b57d17333e2bCA284;
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        address _communityOwner
        )

    ERC721(_name, _symbol)
    CommunityOwnable(_communityOwner) {
        initSetBaseURI(_initBaseURI);
        initSetNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        uint256 senderMintedCount = addressMintedBalance[msg.sender];

        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            require(
                senderMintedCount + _mintAmount <= whitelistNftPerAddressLimit,
                "max NFT per address exceeded while onlyWhitelisted is true"
            );
        }

        require(msg.value >= cost * _mintAmount, "insufficient funds");
        require(senderMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function guille23Mint() public payable {
        require(!paused, "the contract is paused");
        require(msg.sender == guille23Address, "guille23Address is not the caller");
        uint256 supply = totalSupply();
        require(supply == 887, "Only token #888 can be minted");

        addressMintedBalance[msg.sender]++;
        _safeMint(msg.sender, 888);
    }


    function devMint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        require(isDev(msg.sender), "user is not dev");
        require(_mintAmount > 0, "need to mint at least 1 NFT");

        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        uint256 senderMintedCount = addressMintedBalance[msg.sender];
        require(senderMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, supply + i);
        }
    }

    function setGuille23Address(address _address) public onlyCommunityOwner {
        guille23Address = _address;
    }

    function setWithdrawAddress(address _address) public onlyCommunityOwner {
        withdrawAddress = _address;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isDev(address _user) public view returns (bool) {
        for (uint i = 0; i < devAddresses.length; i++) {
            if (devAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    // only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setWhitelistNftPerAddressLimit(uint256 _limit) public onlyOwner {
        whitelistNftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function setDevAddresses(address[] calldata _users) public onlyCommunityOwner {
        delete devAddresses;
        devAddresses = _users;
    }

    function withdraw() public payable {
        (bool success, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(success, "withdrawal failed");
    }


    function initSetBaseURI(string memory _notRevealedURI) internal onlyOwner {
        baseURI = _notRevealedURI;
    }

    function initSetNotRevealedURI(string memory _newBaseURI) internal  onlyOwner {
        notRevealedUri = _newBaseURI;
    }
}
