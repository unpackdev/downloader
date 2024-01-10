// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract TestNfts is ERC721, Ownable {
    using SafeMath for uint256;

    event Received(address from, uint256 amount);
    event NewGrowlie(
        address indexed growlieAddress,
        uint256 count,
        bool isFreeMint
    );

    bool public isPaused = true;
    bool public isPublicSale = false;

    string private _baseTokenURI = "";

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 private constant PUBLIC_MAX_MINT = 10;
    uint256 private constant WL_MAX_MINT = 3;
    uint256 public totalSupply = 0;
    uint256 public presalePrice = 0.07 ether;
    uint256 public publicPrice = 0.09 ether;

    address public proxyRegistryAddress;
    address public signer;
    address[] private _members;

    mapping(string => bool) private _isNonceUsed;
    mapping(address => uint256) private _wlQtyMintedByGrowlie;
    mapping(address => bool) private _freeClaimQtyMintedByGrowlie;

    constructor(
        string memory baseURI,
        address[] memory members,
        address _signer,
        address newProxyRegistryAddress
    ) ERC721("TestNfts II", "TsT") {
        _baseTokenURI = baseURI;
        _members = members;
        signer = _signer;
        proxyRegistryAddress = newProxyRegistryAddress;

        // reserved premint for the team and giveways
        uint256 reserved = 50;

        for (uint256 i = 1; i <= reserved; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        emit NewGrowlie(msg.sender, reserved, true);
        totalSupply += reserved;
    }

    function mint(uint256 quantityToMint) external payable {
        require(!isPaused, "Sale paused");
        require(isPublicSale, "Not public sale");
        require(totalSupply < MAX_SUPPLY, "Sold out");

        require(
            quantityToMint > 0 && quantityToMint <= PUBLIC_MAX_MINT,
            "Max per purchase exceed"
        );

        require(
            totalSupply + quantityToMint <= MAX_SUPPLY,
            "Exceed max supply"
        );
        require(msg.value >= publicPrice * quantityToMint, "Insufficient ETH");

        for (uint256 i = 1; i <= quantityToMint; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += quantityToMint;
        emit NewGrowlie(msg.sender, quantityToMint, false);
    }

    function mintPresale(
        uint256 quantityToMint,
        bool isFreeMint,
        string memory nonce,
        bytes memory signature
    ) external payable {
        require(!isPaused, "Sale paused");
        require(!isPublicSale, "Presale already ended");
        require(quantityToMint > 0, "Quantity must be greater 0");
        require(totalSupply < MAX_SUPPLY, "Sold out");

        if (isFreeMint) {
            require(
                !_freeClaimQtyMintedByGrowlie[msg.sender],
                "Already freeminted"
            );
            require(quantityToMint == 1, "Only 1 freemint");
        } else {
            require(quantityToMint <= WL_MAX_MINT, "Max per purchase exceed");
            require(
                _wlQtyMintedByGrowlie[msg.sender] + quantityToMint <=
                    WL_MAX_MINT,
                "Exceed max wl mints"
            );
            require(
                totalSupply + quantityToMint <= MAX_SUPPLY,
                "Exceed max supply"
            );
            require(msg.value >= presalePrice * quantityToMint, "Insufficient ETH");
        }

        require(!_isNonceUsed[nonce], "Used nonce");
        address signerAddress = _verifySign(
            msg.sender,
            quantityToMint,
            isFreeMint,
            nonce,
            signature
        );
        require(signerAddress == signer, "Not authorized");

        for (uint256 i = 1; i <= quantityToMint; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
        totalSupply += quantityToMint;
        _isNonceUsed[nonce] = true;

        if (isFreeMint) {
            _freeClaimQtyMintedByGrowlie[msg.sender] = true;
        } else {
            _wlQtyMintedByGrowlie[msg.sender] += quantityToMint;
        }
        emit NewGrowlie(msg.sender, quantityToMint, isFreeMint);
    }

    function _verifySign(
        address growlieAddress,
        uint256 quantityToMint,
        bool isFreeMint,
        string memory nonce,
        bytes memory signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        growlieAddress,
                        quantityToMint,
                        isFreeMint,
                        nonce
                    )
                ),
                signature
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getWlQtyMintedByGrowlie(address growlieAddress)
        external
        view
        returns (uint256)
    {
        return _wlQtyMintedByGrowlie[growlieAddress];
    }

    function getFreeClaimQtyMintedByGrowlie(address growlieAddress)
        external
        view
        returns (bool)
    {
        return _freeClaimQtyMintedByGrowlie[growlieAddress];
    }

    function ownedBy(address owner) external view returns (uint256[] memory) {
        uint256 counter = 0;
        uint256[] memory tokenIds = new uint256[](balanceOf(owner));
        for (uint256 i = 0; i < totalSupply; i++) {
            if (ownerOf(i) == owner) {
                tokenIds[counter] = i;
                counter++;
            }
        }
        return tokenIds;
    }

    // Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    //only Owner
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setPause(bool _isPaused) external onlyOwner {
        require(isPaused != _isPaused, "Cannot set same value");
        isPaused = _isPaused;
    }

    function setPublicSale(bool _isPublicSale) external onlyOwner {
        require(isPublicSale != _isPublicSale, "Cannot set same value");
        isPublicSale = _isPublicSale;
    }

    function setSigner(address _signer) external onlyOwner {
        require(signer != _signer, "Address already signer");
        signer = _signer;
    }

    function setProxy(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        require(address(this).balance > 0, "Balance is zero");
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function withdrawAll() external onlyOwner {
        uint256 _totalBalance = address(this).balance;
        require(_totalBalance > 0, "Balance is zero");

        uint256 _amount = _totalBalance / _members.length;
        for (uint256 i = 0; i < _members.length; i++) {
            (bool success, ) = _members[i].call{value: _amount}("");
            require(success, "Transfer failed");
        }
    }
}
