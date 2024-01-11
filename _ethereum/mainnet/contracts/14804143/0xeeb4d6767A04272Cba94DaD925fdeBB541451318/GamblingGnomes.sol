pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract GamblingGnomes is ERC721A, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxTokens = 8888;
    uint256 public _price = 150000000000000000; // .15 ETH
    uint256 public _presale_price = 100000000000000000; // .1 ETH
    uint256 public _withdraw_cuttoff = 125000000000000000000; // 125 ETH, will change before mint
    uint256 public _max_whitelist_mint = 10; // can be changed

    bool private _saleActive = false;
    bool private _presaleActive = false;
    bool private _presale2Active = false;

    string public _prefixURI;

    mapping(address => bool) private _whitelist;

    constructor() ERC721A("GamblingGnomes", "GG") 
    {
    }


    //view functions
    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function Sale() public view returns (bool) {
        return _saleActive;
    }

    function preSale() public view returns (bool) {
        return _presaleActive;
    }

    function preSale2() public view returns (bool) {
        return _presale2Active;
    }

    function numSold() public view returns (uint256) {
        return totalSupply();
    }

    function displayMax() public view returns (uint256) {
        return _maxTokens;
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        return _whitelist[_addr];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    } 

    //variable changing functions

    function changeMax(uint256 _newMax) public onlyOwner {
        _maxTokens = _newMax;
    }

    function changeWhitelistMaxMint(uint256 _newMax) public onlyOwner {
        _max_whitelist_mint = _newMax;
    }

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
    }

    function togglePreSale() public onlyOwner {
        _presaleActive = !_presaleActive;
    }

    function togglePreSale2() public onlyOwner {
        _presale2Active = !_presale2Active;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }


    function changeCutoffWithdrawal(uint256 _newWithdrawalLevel) public onlyOwner {
        _withdraw_cuttoff = _newWithdrawalLevel;
    }

    function changePresalePrice(uint256 _newPrice) public onlyOwner {
        _presale_price = _newPrice;
    }

    function whiteListMany(address[] memory accounts) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            _whitelist[accounts[i]] = true;
        }
    }

    //onlyOwner contract interactions

    function mintTo(uint256 quantity, address _addr) public onlyOwner {
        _safeMint(_addr, quantity);
    }

    function withdraw_costs() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance < _withdraw_cuttoff) {
            payable(0x1cDA7dc869DfA0558A3d305E04B1D31b08c211CD).transfer(balance);
        }
        else {
            payable(0x1cDA7dc869DfA0558A3d305E04B1D31b08c211CD).transfer(_withdraw_cuttoff);
        }

    }

    function withdraw_all() external onlyOwner {
        uint256 balance = address(this).balance;
        //divides the withdraw between everybody
        payable(0x1cDA7dc869DfA0558A3d305E04B1D31b08c211CD).transfer(balance * 37 * 100 / 10000);
        payable(0x1cDA7dc869DfA0558A3d305E04B1D31b08c211CD).transfer(balance * 5  * 10  / 10000);
        payable(0xffE54F84FA4a3B608da61772ffBf9e2fb2b34118).transfer(balance * 7  * 100 / 10000);
        payable(0x5f06ae58d89E2Ccd63dE09815905BF23183004aA).transfer(balance * 4  * 100 / 10000);
        payable(0x9aDFA29c4c8ffCC999bCE70022fD2494B21ab246).transfer(balance * 4  * 100 / 10000);
        payable(0xd2337113Bed666A3eB620b5B5f41f41A41Ba8C78).transfer(balance * 1  * 125 / 10000);
        payable(0x6EC619b6E5c7c1729427E67F3bAeA486F783B10B).transfer(balance * 2  * 100 / 10000);
        payable(0x112951cc13146B7e763b30C2ECb1D24D361760e3).transfer(balance * 3  * 100 / 10000);
        payable(0xD789Ed8E2D52452e081D038db5593151Cd354c29).transfer(balance * 1  * 100 / 10000);
        payable(0x2C1ED4dC9A3D0Daa1abb7313b75D0DB8542B440E).transfer(balance * 12 * 100 / 10000);
        payable(0x1B72813EE4e7782A159B85363C38332C144E029F).transfer(balance * 2  * 100 / 10000);
        payable(0x3731b157dEbE2036a91f7bb56bB4FE8969d5aAD1).transfer(balance * 5  * 100 / 10000);
        payable(0xD33a1db21052e5A54b277cABA21f8af9e6569649).transfer(balance * 5  * 100 / 10000);
        payable(0x3024B86C1694E4Ac29020aBE446e60B167a97f67).transfer(balance * 7  * 100 / 10000);
        payable(0x9D406b36E42624Dab427494815f3eEb1BEBc9534).transfer(balance * 1  * 25  / 10000);
        payable(0xA0BDF0C51B8d4B43b73248fdc57630c0Ba3CDCba).transfer(balance * 5  * 100 / 10000);
        payable(0x5d7021Fb68E2fe84c876A4b53A5A5B3e9808CD1D).transfer(balance * 1  * 100 / 10000);
        payable(0x3f3E2cd2c8aBc828Bce1b667cB6322AC9d8086c8).transfer(balance * 1  * 250 / 10000);
        payable(0x31a18677d2619350B53D1436a74DFDFf07513A6f).transfer(balance * 5  * 10  / 10000);
    }

    //minting functionality

    function mintItems(uint256 amount) public payable {
        require(_saleActive);
        uint256 totalMinted = totalSupply();
        require(totalMinted + amount <= _maxTokens);
        require(msg.value >= amount * _price);
        _safeMint(_msgSender(), amount);
    }

    function presaleMintItems(uint256 amount) public payable {
        require(_presaleActive);
        require(_whitelist[_msgSender()], "Mint: Unauthorized Access");
        require(amount <= _max_whitelist_mint, "Mint: You may only mint up to 10");

        uint256 totalMinted = totalSupply();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _presale_price);

        _safeMint(_msgSender(), amount);
        _whitelist[_msgSender()] = false;
    }

    function presaleMintItemz(uint256 amount) public payable {
        require(_presale2Active);
        require(amount <= 10, "Mint: You may only mint up to 10");
        _safeMint(_msgSender(), amount);
    }


}
