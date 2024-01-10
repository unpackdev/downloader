// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract PurpleHeylo is Ownable, ERC721A {
    using Strings for uint256;
    using SafeMath for uint256;
    uint256 public MAX_SUPPLY = 8888;
    uint256 public MAX_NFT_PRESALE = 1000;
    uint256 public PRESALE_COST = 0.04 ether;
    uint256 public MINT_PRICE = 0.08 ether;

    string public notRevealedUri;
    string private baseURI;
    string public baseExtension = ".json";

    bool public isPresale;
    bool public isLaunched;
    bool public revealed = false;

    address public constant artistWallet =
        0x9D99aE38de338Add76A741B02b1820e814B99c62;
    address public constant ownerWallet =
        0xc557B691111745EDC255bf66f37b4C4Cbce37Dee;

    //init function called on deploy
    function init() public {
        isPresale = false;
        isLaunched = false;
    }

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri)
        ERC721A("Purple Heylo", "Purple Heylo")
    {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
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

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function launchPresaleToggle() public onlyOwner {
        isPresale = !isPresale;
    }

    function saleToggle() public onlyOwner {
        isLaunched = !isLaunched;
    }

    function setPresalePrice(uint256 newPrice) public onlyOwner {
        PRESALE_COST = newPrice;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        MINT_PRICE = newPrice;
    }

    function setPresaleAmount(uint256 presaleAmount) public onlyOwner {
        MAX_NFT_PRESALE = presaleAmount;
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(artistWallet, balance.mul(10).div(100));
        _widthdraw(ownerWallet, balance.mul(90).div(100));
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    //presale
    function preSaleWhitelist(address account, uint256 _mintAmount)
        external
        payable
    {
        require(isPresale, "presale is not active");
        require(
            totalSupply() + _mintAmount <= MAX_NFT_PRESALE,
            "exceeds presale limit"
        );
        require(
            msg.value >= (PRESALE_COST * _mintAmount),
            "Not enough eth sent: check price"
        );
        _safeMint(account, _mintAmount);
    }

    function mint(address account, uint256 _mintAmount) external payable {
        require(isLaunched, "general mint has not started");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY,
            "exceeds total available NFT"
        );
        require(
            msg.value >= (MINT_PRICE * _mintAmount),
            "Not enough eth sent: check price"
        );
        _safeMint(account, _mintAmount);
    }
}
