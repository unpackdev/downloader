// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./console.sol";

contract BossApes is ERC721Upgradeable, OwnableUpgradeable {
    uint16 public constant MAX_APES = 5555;
    uint16 public constant MAX_WHITELIST_APES = 1111;
    uint16 public constant MAX_WHITELIST_APES_MINTED = 5;
    uint16 public constant MAX_APES_MINTED = 5;
    uint64 public constant MINT_PRICE = 0.2 ether;
    uint64 public constant MINT_PRICE_WHITELIST = 0.08 ether;

    // always add trailing / at the end
    string private _base;
    string private _contractURI;

    bool public mintIsActive;

    uint16 public totalSupply;

    mapping(address => bool) private whitelistedAddresses;

    bool public presaleIsActive;

    function initialize() public initializer {
        ERC721Upgradeable.__ERC721_init("Boss Apes Club", "BAC");
        OwnableUpgradeable.__Ownable_init();

        presaleIsActive = false;
        mintIsActive = false;
        totalSupply = 0;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function setBaseURI(string memory base) external onlyOwner {
        // console.log(string.concat("Changing _baseURI to\t: ", base));
        _base = base;
        // console.log(string.concat("_baseURI is now\t\t: ", _baseURI));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _base;
    }

    // function _setTokenURI(uint16 _tokenId, string memory _tokenURI) internal {
    //     require(
    //         _exists(_tokenId),
    //         "ERC721Metadata: URI set of nonexistent token"
    //     );
    //     _tokenURIs[_tokenId] = _tokenURI;
    // }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        // string memory _tokenURI = _tokenURIs[uint16(_tokenId)];
        string memory base = _baseURI();

        return
            string(abi.encodePacked(base, Strings.toString(_tokenId), ".json"));
    }

    // should only be called ONCE after max whitelist limit is reached
    function setWhitelistAddresses(address[] memory _addresses)
        public
        onlyOwner
    {
        uint16 i;
        for (i = 0; i < _addresses.length; i++) {
            whitelistedAddresses[_addresses[i]] = true;
        }
    }

    modifier isWhitelisted() {
        require(
            whitelistedAddresses[msg.sender],
            "Whitelist: You need to be whitelisted"
        );
        _;
    }

    function _mintApe(address to) internal {
        require(
            totalSupply + 1 <= MAX_APES,
            "Mint would exceed max supply of apes!"
        );
        _safeMint(to, ++totalSupply);

        // string memory newTokenURI = string.concat(
        //     Strings.toString(totalSupply),
        //     ".json"
        // );
        // set token URI
        // _tokenURIs[_tokenId] = _tokenURI;
    }

    function mintApesWhitelist(uint8 numberOfTokens) public payable {
        require(presaleIsActive, "Currently not for open for minting");
        require(
            numberOfTokens <= MAX_WHITELIST_APES_MINTED,
            string(
                abi.encodePacked(
                    "Cannot mint more than ",
                    Strings.toString(numberOfTokens),
                    " tokens at once!"
                )
            )
        );
        // console.log("Minting stats...");
        // console.log(totalSupply + numberOfTokens);
        // console.log(MINT_PRICE * numberOfTokens);
        // console.log(msg.value);
        require(
            totalSupply + numberOfTokens <= MAX_WHITELIST_APES + 123,
            "Purchase would exceed max supply of whitelisted apes!"
        );
        require(
            msg.value >= MINT_PRICE_WHITELIST * numberOfTokens,
            "Not enough ETH! Please check mint price."
        );

        for (uint8 i = 0; i < numberOfTokens; i++) {
            _mintApe(msg.sender);
        }
    }

    function mintApes(uint16 numberOfTokens) public payable {
        require(mintIsActive, "Currently not for open for minting");
        require(
            numberOfTokens <= MAX_APES_MINTED,
            string(
                abi.encodePacked(
                    "Cannot mint more than ",
                    Strings.toString(numberOfTokens),
                    " tokens at once!"
                )
            )
        );
        // console.log("Minting stats...");
        // console.log(totalSupply + numberOfTokens);
        // console.log(MINT_PRICE * numberOfTokens);
        // console.log(msg.value);
        require(
            totalSupply + numberOfTokens <= MAX_APES,
            "Purchase would exceed max supply of apes!"
        );
        require(
            msg.value >= MINT_PRICE * numberOfTokens,
            "Not enough ETH! Please check mint price."
        );

        for (uint8 i = 0; i < numberOfTokens; i++) {
            _mintApe(msg.sender);
        }
    }

    function reserve(uint16 numberOfTokens, address to) public onlyOwner {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            _mintApe(to);
        }
    }

    // Pause presale if active, make active if paused
    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    // Pause mint if active, make active if paused
    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    // transfer ETH from contract to owner
    function withdrawMoney() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
}
