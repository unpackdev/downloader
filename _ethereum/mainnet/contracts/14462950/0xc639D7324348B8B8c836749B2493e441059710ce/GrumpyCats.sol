// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}



contract GrumpyCats is ERC721A, Ownable {
    using ECDSA for bytes32;

    uint256 public constant MAX_ELEMENTS = 5001;
    uint256 public constant PRICE = 0.04 ether;
    uint256 public constant PRESALE_PRICE = 0.03 ether;
    address public whiteListSigningAddress = address(638743243542);
    address public constant wdAddress = 0xB6e65fC5C49EfF872c1AbfF3F98F45694F909be1;


    address proxyRegistryAddress;

    enum Status {CLOSED, PRESALE, SALE}
    Status public state = Status.CLOSED;

    string public baseTokenURI;


    constructor(string memory baseURI, address _proxyRegistryAddress) ERC721A("GrumpyCats", "GRMPY"){
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


        if(state == Status.PRESALE) {
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
        (bool success, ) = wdAddress.call{value: balance}("");
        require(success, "Transfer failed");
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