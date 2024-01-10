// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

    /// @title 0x0.art utility NFT tokens contract
    /// @author MV
    /// @notice ERC-721 Contract. Presale mint, public mint, reserve mint functions

contract Oxo is ERC721, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public totalSupply; //Total tokens supply
    uint256 public preSalePrice; //Whitelist sale token price in Wei
    uint256 public publicPrice; //Public sale token price in Wei
    uint256 public tokenId; //Token id
    bool public publicSaleEvent; //Enable public sale
    bool public whitelistSaleEvent; //Enable whitelisted sale
    string public baseUri; //Base uri for tokens Uri
    string public baseExtension; //Base extension for tokens Uri
    string public contractUri; //Contract uri with contract details
    address public signer; //Signer address for whitelist signatures verification
    uint256 public reserve; //Reserved tokens for team
    uint256 public maxTokensWallet; //Max number of tokens per wallet in whitelist sale event

    mapping(address => uint256) private whiteMinted;  //whitlist mint event minted list

    constructor() ERC721("test 0x0 Art NFT2", "test OART2") {
        totalSupply = 10000;
        reserve = 50;
        preSalePrice = 60000000000000000;
        publicPrice = 100000000000000000;
        tokenId = 0;
        publicSaleEvent = false;
        whitelistSaleEvent = false;
        baseUri = "https://tokens.0x0.art/";
        contractUri = "ipfs://QmWw9orbwVegBmS4jcaNoxWPgnV12tr7t49Ta912NyNqQe";
        baseExtension = ".json";
        signer = 0x8BF0AA44B7ABFC54F7e87fC9294695c4D7a5EFca;
        maxTokensWallet = 7;
    }

    /// @notice Public mint event mint function
    /// @param  number number of tokens to mint
    function publicMint(uint256 number) external payable returns(bool){
        require(publicSaleEvent, "Public sale event disabled");
        require(
            msg.value >= publicPrice * number,
            "ETH amount lower than price"
        );
        require(
            number + tokenId + reserve <= totalSupply,
            "Total tokens supply reached"
        );
        bulkMint(number);
        return true;
    }

    /// @notice Presale mint event function
    /// @param number number of tokens to mint
    /// @param signature wallet whitelist verification signature
    function whitelistMint(uint256 number, bytes memory signature)
        external
        payable
        returns(bool)
    {
        address recovered = keccak256(abi.encodePacked(msg.sender))
            .toEthSignedMessageHash()
            .recover(signature);
        require(recovered == signer, "Coupon not valid");
        require(whitelistSaleEvent, "Whitelist sale event disabled");
        require(
            msg.value >= preSalePrice * number,
            "ETH amount lower than price"
        );
        require(
            whiteMinted[msg.sender] + number <= maxTokensWallet,
            "Maximum tokens per wallet reached"
        );
        require(
            number + tokenId + reserve <= totalSupply,
            "Total tokens supply reached"
        );

        whiteMinted[msg.sender] += number;
        bulkMint(number);
        return true;
    }

    /// @notice Team reserve mint function
    /// @param number number of tokens to mint
    function reserveMint(uint256 number) external onlyOwner {
        require(number <= reserve);
        reserve -= number;
        bulkMint(number);
    }

    function bulkMint(uint256 number) private {
        for (uint256 i = 1; i <= number; i++) {
            tokenId += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    /// @notice Returns base uri of tokens
    /// @return string
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setPublicSale(bool _val) external onlyOwner {
        publicSaleEvent = _val;
    }

    function setWhitelistSale(bool _val) external onlyOwner {
        whitelistSaleEvent = _val;
    }

    /// @notice Returns token uri, JSON data address
    /// @param _tokenId token id
    /// @return string
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /// @notice Returns contract uri with details, JSON data address
    /// @return string
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setReserve(uint256 _number) external onlyOwner {
        reserve = _number;
    }

    function setPreSalePrice(uint256 _newPrice) external onlyOwner {
        preSalePrice = _newPrice;
    }

    function setPublicPrice(uint256 _newPrice) external onlyOwner {
        publicPrice = _newPrice;
    }

    function setTokensLimit(uint256 _number) external onlyOwner {
        maxTokensWallet = _number;
    }

    function setExtension(string memory _extension) external onlyOwner {
        baseExtension = _extension;
    }
}
