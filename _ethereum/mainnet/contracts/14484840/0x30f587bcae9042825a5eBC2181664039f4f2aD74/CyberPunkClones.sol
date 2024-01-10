// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}



contract CyberPunkClones is ERC721A, Ownable {
    using ECDSA for bytes32;

    uint256 public constant MAX_ELEMENTS = 5556;  //must be +1
    uint256 public constant PRICE = 0.11 ether;
    uint256 public constant PRESALE_PRICE = 0.06 ether;
    uint256 public constant PRESALE_LIMIT = 6; //must be +1
    uint256 public constant SALE_LIMIT = 3;  //must be +1
    address public whiteListSigningAddress = address(43874433243542);
    address public constant wdAddress = 0xf3fb4419B2De62a906BE9B0719017f0Ab7959c1B;
    address public constant wd2Address = 0x175A73E2A7686E65eB04178D229dd1a60c99eC9c;


    //

    address proxyRegistryAddress;

    enum Status {CLOSED, PRESALE, SALE}
    Status public state = Status.CLOSED;

    string public baseTokenURI;


    constructor(string memory baseURI, address _proxyRegistryAddress) ERC721A("CyberPunkClones", "CPCL"){
        setBaseURI(baseURI);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    modifier saleIsOpen {
       require (state != Status.CLOSED, "sales closed");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }


    function numMinted(address addr) public view returns (uint256) {
        return _numberMinted(addr);
    }


    function airdropTo(address[] calldata _wallets) external onlyOwner {
        uint256 num = _wallets.length;
        require(totalSupply() + num < MAX_ELEMENTS, "exceed limit");


        for(uint256 i = 0; i < num; i++) {
            _safeMint(_wallets[i], 1);

        }
    }

    function mint(uint256 _numToMint, bytes calldata _signature) external payable saleIsOpen {

        require(_numToMint > 0 && _numToMint < 11, "max limit to mint"); //10 per mint
        require(totalSupply() + _numToMint < MAX_ELEMENTS, "sold out");
        require(msg.value == getPrice(_numToMint), "sended value must equal price");
        require(msg.sender == tx.origin, "no contract calls");

        if(state == Status.SALE){
            require((_numToMint + _numberMinted(msg.sender)) < SALE_LIMIT, "minting more than allowed");
        }

        if(state == Status.PRESALE) {
            require((_numToMint + _numberMinted(msg.sender)) < PRESALE_LIMIT, "minting more than allowed");
            require(
                whiteListSigningAddress ==
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            bytes32(uint256(uint160(msg.sender)))
                        )
                    ).recover(_signature),
                "you are not whitelisted"
            );
        }


        // solhint-disable-next-line
        _safeMint(_msgSender(), _numToMint);

    }

    function getPrice(uint256 _count) public view returns (uint256) {
        if(state == Status.PRESALE){
            return PRESALE_PRICE * _count;
        }
        return PRICE * _count;
    }


    function setWhiteListSigningAddress(address _signingAddress) external onlyOwner {
        whiteListSigningAddress = _signingAddress;
    }


    function setSaleState(uint newState) external onlyOwner {
        state = Status(newState);
    }


    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(wd2Address, balance * 2 / 100);
        _widthdraw(wdAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    //Whitelist opensea proxy
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}