// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

//  ________   ___    _ ,---.   .--.  .-_'''-.     ___    _    ____     __  .-'''-.
// |        |.'   |  | ||    \  |  | '_( )_   \  .'   |  | |   \   \   /  // _     \
// |   .----'|   .'  | ||  ,  \ |  ||(_ o _)|  ' |   .'  | |    \  _. /  '(`' )/`--'
// |  _|____ .'  '_  | ||  |\_ \|  |. (_,_)/___| .'  '_  | |     _( )_ .'(_ o _).
// |_( )_   |'   ( \.-.||  _( )_\  ||  |  .-----.'   ( \.-.| ___(_ o _)'  (_,_). '.
// (_ o._)__|' (`. _` /|| (_ o _)  |'  \  '-   .'' (`. _` /||   |(_,_)'  .---.  \  :
// |(_,_)    | (_ (_) _)|  (_,_)\  | \  `-'`   | | (_ (_) _)|   `-'  /   \    `-'  |
// |   |      \ /  . \ /|  |    |  |  \        /  \ /  . \ / \      /     \       /
// '---'       ``-'`-'' '--'    '--'   `'-...-'    ``-'`-''   `-..-'       `-...-'

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Funguys is ERC721, Ownable {
    using SafeMath for uint256;

    event Received(address from, uint256 amount);
    event NewFunguy(address indexed funguyAddress, uint256 count);
    event NewFunguyFreeClaim(address indexed funguyAddress, uint256 count);

    uint256 public constant MAX_SUPPLY = 4913;
    bool public pauseState;
    bool public publicSalesState;

    uint256 public totalSupply;
    address public proxyRegistryAddress;

    string private _baseTokenURI;
    string private _currentContractURI;

    uint256 private _maxTokensPerPurchase;
    uint256 private _reservedTokensNumber;
    uint256 private _price;

    address[] private _members;

    mapping(string => bool) private _isNonceUsed;
    mapping(address => uint256) private _wlQtyMintedByFunguy;
    mapping(address => uint256) private _freeClaimQtyMintedByFunguy;

    constructor(
        address newProxyRegistryAddress,
        address[] memory members,
        string memory baseURI,
        string memory newContractURI
    ) ERC721("Funguys", "Funguy") {
        pauseState = true;
        publicSalesState = false;
        totalSupply = 0;
        proxyRegistryAddress = newProxyRegistryAddress;
        _members = members;
        _baseTokenURI = baseURI;
        _currentContractURI = newContractURI;
        _maxTokensPerPurchase = 3;
        _reservedTokensNumber = 200;
        _price = 0.05 ether;
    }

    function Mint(uint256 quantityToMint) external payable {
        require(!pauseState, "Sale paused");
        require(publicSalesState, "Public sale paused");
        require(totalSupply < MAX_SUPPLY, "Sold out");

        require(
            quantityToMint > 0 && quantityToMint <= _maxTokensPerPurchase,
            "3 is max per purchase"
        );

        require(
            totalSupply + quantityToMint <= MAX_SUPPLY - _reservedTokensNumber,
            "Exceed max supply"
        );
        require(msg.value >= _price * quantityToMint, "Insufficient ETH");

        for (uint256 i = 0; i < quantityToMint; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += quantityToMint;
        emit NewFunguy(msg.sender, quantityToMint);
    }

    function SignedMint(
        string memory nonce,
        uint256 quantityToMint,
        uint256 maxQtyForOneGuy,
        bool freeMintEligible,
        bytes memory signature
    ) external payable {
        require(!pauseState, "Sale paused");
        require(quantityToMint > 0, "Quantity must be greater 0");
        require(totalSupply < MAX_SUPPLY, "Sold out");

        if (freeMintEligible) {
            require(
                quantityToMint <= _reservedTokensNumber,
                "Exceeds reserved supply"
            );
        } else {
            require(
                totalSupply + quantityToMint <=
                    MAX_SUPPLY - _reservedTokensNumber,
                "Exceed max supply"
            );
        }

        address signerAddress = _verifySign(
            msg.sender,
            nonce,
            maxQtyForOneGuy,
            freeMintEligible,
            signature
        );

        require(signerAddress == owner(), "Not authorized");
        require(!_isNonceUsed[nonce], "Used nonce");

        if (freeMintEligible) {
            require(
                _freeClaimQtyMintedByFunguy[msg.sender] + quantityToMint <=
                    maxQtyForOneGuy,
                "Exceed max free mints"
            );
        } else {
            require(
                _wlQtyMintedByFunguy[msg.sender] + quantityToMint <=
                    maxQtyForOneGuy,
                "Exceed max wl mints"
            );

            require(msg.value >= _price * quantityToMint, "Insufficient ETH");
        }

        for (uint256 i = 0; i < quantityToMint; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += quantityToMint;
        _isNonceUsed[nonce] = true;

        if (freeMintEligible) {
            _reservedTokensNumber -= quantityToMint;
            _freeClaimQtyMintedByFunguy[msg.sender] += quantityToMint;
            emit NewFunguyFreeClaim(msg.sender, quantityToMint);
        } else {
            _wlQtyMintedByFunguy[msg.sender] += quantityToMint;
            emit NewFunguy(msg.sender, quantityToMint);
        }
    }

    function _verifySign(
        address funguyAddress,
        string memory nonce,
        uint256 maxQtyForOneGuy,
        bool freeMintEligible,
        bytes memory signature
    ) internal pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        funguyAddress,
                        nonce,
                        maxQtyForOneGuy,
                        freeMintEligible
                    )
                ),
                signature
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _currentContractURI;
    }

    function getNumberOfMaxTokensPerPurchase() external view returns (uint256) {
        return _maxTokensPerPurchase;
    }

    function getNumberOfReservedTokens() external view returns (uint256) {
        return _reservedTokensNumber;
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }

    function getWlQtyMintedByFunguy(address funguyAddress)
        external
        view
        returns (uint256)
    {
        return _wlQtyMintedByFunguy[funguyAddress];
    }

    function getFreeClaimQtyMintedByFunguy(address funguyAddress)
        external
        view
        returns (uint256)
    {
        return _freeClaimQtyMintedByFunguy[funguyAddress];
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

    function setContractURI(string memory newContractURI) external onlyOwner {
        _currentContractURI = newContractURI;
    }

    function setPauseState(bool newPauseState) external onlyOwner {
        pauseState = newPauseState;
    }

    function setPublicSalesState(bool newPublicSalesState) external onlyOwner {
        publicSalesState = newPublicSalesState;
    }

    function setNumberOfMaxTokensPerPurchase(uint256 newNumber)
        public
        onlyOwner
    {
        _maxTokensPerPurchase = newNumber;
    }

    function setNumberOfReservedTokens(uint256 newNumber) external onlyOwner {
        require(newNumber >= 0, "New number must be not negative");

        require(
            MAX_SUPPLY - (totalSupply + newNumber) >= 0,
            "New number exceeds max supply"
        );

        _reservedTokensNumber = newNumber;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        _price = newPrice;
    }

    function setProxy(address newProxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = newProxyRegistryAddress;
    }

    //External
    function giveAway(address to, uint256 quantityToMint) external onlyOwner {
        require(quantityToMint > 0, "Quantity must be greater 0");
        require(totalSupply < MAX_SUPPLY, "Sold out");        

        require(
            quantityToMint <= _reservedTokensNumber,
            "Exceeds reserved supply"
        );

        for (uint256 i; i < quantityToMint; i++) {
            _safeMint(to, totalSupply + i);
        }

        totalSupply += quantityToMint;
        _reservedTokensNumber -= quantityToMint;
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