// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ERC721.sol";

/**
 * @dev NFTBase contract.
 * @notice Setup admin control functional, include price,
 */
contract NFTBase is Ownable, ERC721 {
    // status of contract
    enum STATUS {
        OFF_SALE,
        PRE_SALE,
        ON_SALE
    }

    uint256 public DSA_SUPPLY;

    uint256 public maxMint;
    uint256 public preSaleMaxMint;
    uint256 public price;

    string internal blankURI;

    uint256 public beginRandomIndex;
    string internal celebTokenBaseURI;

    bool internal creatorMinted;
    uint256 internal numberDev;
    address internal developer;


    STATUS public status;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public giveAways;
    mapping(address => uint256) public whitelistCounts;

    constructor(string memory _blankURI, uint256 _supply, address _developer)
        public
        ERC721("Doomed Souls Army", "DSA")
    {
        DSA_SUPPLY = _supply;
        price = 0.05 ether;
        maxMint = 5;
        preSaleMaxMint = 5;
        blankURI = _blankURI;
        numberDev = 100;
        developer = _developer;
    }

    modifier canMintOnSale(uint256 _number) {
        require(status == STATUS.ON_SALE, "Status is not on sale");

        require(
            _number <= maxMint,
            "Over max token can mint per one transaction"
        );
        require(msg.value >= _number.mul(price), "Payment error");
        _;
    }

    /**
     * @dev ensure collector pays for mint token
     */
    modifier mintable(uint256 _number) {
        require(
            _number.add(totalSupply()) < DSA_SUPPLY,
            "Bound limit of maxinum supply limit"
        );
        _;
    }

    /**
     * @dev change status from online to offline and vice versa
     */
    function setStatus(STATUS _status) public onlyOwner returns (bool) {
        status = _status;
        return true;
    }

    function setPrice(uint256 _price) public onlyOwner {
        require(status == STATUS.OFF_SALE, "Current status is not off sale");
        price = _price;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setBlankURI(string memory _blankURI) public onlyOwner {
        blankURI = _blankURI;
    }

    function setCelebDSABaseURI(string memory _celebTokenBaseURI)
        public
        onlyOwner
    {
        celebTokenBaseURI = _celebTokenBaseURI;
    }

    function addToWhitelist(address[] memory _wallets) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; ++i) {
            whitelist[_wallets[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory _wallets) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; ++i) {
            whitelist[_wallets[i]] = false;
        }
    }

    function setGiveAways(address[] memory _wallets, uint256[] memory _giveAways)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; ++i) {
            whitelist[_wallets[i]] = true;
            giveAways[_wallets[i]] = _giveAways[i];
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).send(balance);
    }

    function _mintToken(address _receiver, uint256 _number) internal {
        for (uint256 i = 0; i < _number; i++) {
            uint256 tokenIndex = totalSupply();
            if (tokenIndex < DSA_SUPPLY) _safeMint(_receiver, tokenIndex);
        }
    }

    function _mintPreSale(address _receiver, uint256 _number) internal {
        require(status == STATUS.PRE_SALE, "Current status is not pre sale");
        require(whitelist[_receiver], "You not in whitelist");

        if (giveAways[_receiver] >= _number) {
            giveAways[_receiver] = giveAways[_receiver].sub(_number);
        } else {
            require(
                whitelistCounts[_receiver].add(_number).sub(
                    giveAways[_receiver]
                ) <= preSaleMaxMint,
                "Over whitelist max mint"
            );

            require(
                msg.value >= _number.sub(giveAways[_receiver]).mul(price),
                "Payment error"
            );

            whitelistCounts[_receiver] = whitelistCounts[_receiver].add(
                _number.sub(giveAways[_receiver])
            );

            giveAways[_receiver] = 0;
        }

        _mintToken(_receiver, _number);
    }

    function reserveByDeveloper(uint256 _number) external {
        require(_msgSender() == developer, "You don't have permission!!!");
        require(numberDev >= _number, "You can't mint more");
        numberDev = numberDev.sub(_number);
        _mintToken(developer, _number);
    }

    function reserveByCreator(
        uint256 _numberCreator,
        uint256 _numberCreatorCeleb,
        uint256 _numberDevCeleb,
        string memory _celebTokenBaseURI
    ) external onlyOwner {
        require(!creatorMinted, "You minted token for creator");
        creatorMinted = true;
        // celeb token URI
        setCelebDSABaseURI(_celebTokenBaseURI);

        beginRandomIndex = _numberCreatorCeleb.add(_numberDevCeleb);

        numberDev = numberDev.sub(_numberDevCeleb);

        _mintToken(owner(), _numberCreatorCeleb);
        _mintToken(developer, _numberDevCeleb);
        _mintToken(owner(), _numberCreator);
    }
}
