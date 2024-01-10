// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Xenopets is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    mapping(string => Counters.Counter) private _planetTotalSupply;
    mapping(string => uint256) private _planetSupplyOffset;

    mapping(address => string) public whitelist;

    address constant deposit = 0xd49a215f2FdbEfcA9A9364eB44E31860996aa3A8;

    uint256 public constant pre_sale_cost = 0.05 ether;
    uint256 public constant main_sale_cost = 0.07 ether;
    uint256 public constant transaction_limit = 10;
    uint256 public constant total_supply_per_planet = 10000;

    uint256 public reserved = 50;

    bool public paused_sale = true;
    bool public paused_presale = true;

    string private _baseTokenURI = "";

    string public currentPlanet = "";

    modifier saleNotPaused() {
        require(!paused_sale, "Xenopets: sale is paused");
        _;
    }

    modifier preSaleNotPaused() {
        require(!paused_presale, "Xenopets: pre-sale is paused");
        _;
    }

    modifier isWhitelisted() {
        require(
            keccak256(abi.encodePacked(whitelist[msg.sender])) ==
                keccak256(abi.encodePacked(currentPlanet)),
            "Xenopets: wallet address is not on whitelist for drop"
        );
        _;
    }

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        currentPlanet = "Terra Zoi";
        _planetSupplyOffset["Terra Zoi"] = 0;
        _planetSupplyOffset["Xeros Sfaria"] = total_supply_per_planet;
        _planetSupplyOffset["Pagos Prasinos"] = total_supply_per_planet * 2;
        _planetSupplyOffset["Mykitas Thanatos"] = total_supply_per_planet * 3;
    }

    fallback() external payable {}

    receive() external payable {}

    function toggleSale() public onlyOwner {
        paused_sale = !paused_sale;
    }

    function togglePreSale() public onlyOwner {
        paused_presale = !paused_presale;
    }

    function mint(uint256 num) public payable saleNotPaused {
        require(num > 0, "Xenopets: amount must be at least 1");
        require(
            num <= transaction_limit,
            "Xenopets: amount must be smaller than transaction limit"
        );
        uint256 supply = _planetTotalSupply[currentPlanet].current() + 0;
        require(
            supply + num <= total_supply_per_planet - reserved,
            "Xenopets: Exceeds max supply"
        );
        require(
            msg.value >= main_sale_cost * num,
            "Xenopets: Ether sent is less than main_sale_cost * num"
        );
        for (uint256 i = 0; i < num; i++) {
            _tokenSupply.increment();
            _planetTotalSupply[currentPlanet].increment();
            _safeMint(
                msg.sender,
                _planetTotalSupply[currentPlanet].current() +
                    _planetSupplyOffset[currentPlanet]
            );
        }
    }

    function preMint(uint256 num)
        public
        payable
        preSaleNotPaused
        isWhitelisted
    {
        require(num > 0, "Xenopets: amount must be at least 1");
        require(
            num <= transaction_limit,
            "Xenopets: amount must be smaller than transaction limit"
        );
        uint256 supply = _planetTotalSupply[currentPlanet].current() + 0;
        require(
            supply + num <= total_supply_per_planet - reserved,
            "Xenopets: Exceeds max supply"
        );
        require(
            msg.value >= pre_sale_cost * num,
            "Xenopets: Ether sent is less than pre_sale_cost * num"
        );
        for (uint256 i = 0; i < num; i++) {
            _tokenSupply.increment();
            _planetTotalSupply[currentPlanet].increment();
            _safeMint(
                msg.sender,
                _planetTotalSupply[currentPlanet].current() +
                    _planetSupplyOffset[currentPlanet]
            );
        }
    }

    function adminMint(uint256 num) public onlyOwner {
        require(num > 0, "Xenopets: amount must be at least 1");
        require(num <= reserved, "Xenopets: Exceeds reserved supply");
        for (uint256 i = 0; i < num; i++) {
            _tokenSupply.increment();
            _planetTotalSupply[currentPlanet].increment();
            _safeMint(
                msg.sender,
                _planetTotalSupply[currentPlanet].current() +
                    _planetSupplyOffset[currentPlanet]
            );
        }
        reserved = reserved - num;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = deposit.call{value: address(this).balance}("");
        require(success, "Xenopets: Withdraw failed");
    }

    function batchWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = currentPlanet;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Xenopets: URI query for nonexistent token");

        string memory baseURI = getBaseURI();
        string memory json = ".json";
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), json))
                : "";
    }

    function tokensMinted() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function planetTokensMinted() public view returns (uint256) {
        return _planetTotalSupply[currentPlanet].current();
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function changePlanet(uint256 num) public onlyOwner {
        require(num > 1 && num < 5, "Xenopets: Incorrect planet number");
        reserved = 50;
        if (num == 2) {
            currentPlanet = "Xeros Sfaria";
        } else if (num == 3) {
            currentPlanet = "Pagos Prasinos";
        } else if (num == 4) {
            currentPlanet = "Mykitas Thanatos";
        }
    }

    function tokensOfOwner(address _owner, string memory _planet)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalXenos = _planetTotalSupply[_planet].current() +
                _planetSupplyOffset[_planet];
            uint256 resultIndex = 0;

            uint256 xenoId;

            for (
                xenoId = 1 + _planetSupplyOffset[_planet];
                xenoId <= totalXenos;
                xenoId++
            ) {
                if (ownerOf(xenoId) == _owner) {
                    result[resultIndex] = xenoId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}
