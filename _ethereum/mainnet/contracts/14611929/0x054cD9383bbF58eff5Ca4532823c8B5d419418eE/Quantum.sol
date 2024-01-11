//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SignatureVerifier.sol";
import "./Strings.sol";

library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return
            address(registry) != address(0) &&
            address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Quantum is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    SignatureVerifier
{
    using Strings for uint256;

    uint16 public publicSupply;
    uint16 public privateSupply;
    uint16 public publicSupplyLimit;
    uint16 public privateSupplyLimit;
    bool public publicMintActive;
    bool public isRevealed;
    bool public privateMintActive;

    address public regularSigner;
    address public privateSigner;
    string public baseURI;
    string public notRevealedUri;
    string public baseExtension;

    mapping(address => bool) public mintingLedger;
    address[3000] public tokenLedger; // reserved storage in case of a pivotal expansion.

    event tokenMinted(address, uint256);
    string public whaleURI;
    string public normalURI;
    address proxyRegistryAddress;

    mapping(address => bool) public privateMintingLedger;

    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721_init("Quantum", "QUANTUM");

        publicMintActive = false;
        isRevealed = true;
        normalURI = "ipfs://QmYpKcCC4e7JLXwbMwPCfQJMf86LmxCZyMQkHw3xRa7Ffc";
        whaleURI = "ipfs://QmT4WWqgsiyERPkb9txCQgCzgaPwZob8UNaK7Q8V5A8iM8";
        privateMintActive = false;
        regularSigner = 0xB3BA692696A60271b2f2D2917c20E14c32cA74d7;
        privateSigner = 0xc9c3B4587fcD88E463Cd3c86B4C6594709f22c12;
        baseExtension = ".json";
        proxyRegistryAddress = 0xe850eB266384A133844976aC66B98A44eDBFCb0d;
        /* we are keeping track of two different counters.
         * privateSupply, which is limited by the privateSupplyLimit.
         * and publicSupply, which is limited by the privateSupplyLimit.
         * publicSupply is incremented in the mint function, and it starts from 0 up to limit.
         * privateSupply is incremented in the privateMint funciton, and starts from 2000 up to limit.
         * the totalSupply function returns  ( publicSupply + ( privateSupply - 2000),
         * effectivly giving us the total minted supply.
         * both limits can be modified in their respective functions.
         */
        privateSupply = 2000;
        publicSupply = 0;
        publicSupplyLimit = 2000;
        privateSupplyLimit = 2100;
    }

    function mint(bytes calldata sig)
        external
        payable
        nonReentrant
        whenNotPaused
        mintingChecks(sig, publicMintActive, regularSigner, false)
    {
        _safeMint(msg.sender, ++publicSupply);
        emit tokenMinted(msg.sender, publicSupply);
    }

    function privateMint(bytes calldata sig)
        external
        payable
        nonReentrant
        whenNotPaused
        mintingChecks(sig, privateMintActive, privateSigner, true)
    {
        _safeMint(msg.sender, ++privateSupply);
        emit tokenMinted(msg.sender, privateSupply);
    }

    function ownerMint(address _reciever, uint256[] memory tokenIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _safeMint(_reciever, tokenIds[i]);
            if (tokenIds[i] <= 2000) ++publicSupply;
            else {
                require(
                    privateSupply + 1 <= privateSupplyLimit,
                    "private supply reached"
                );
                ++privateSupply;
            }
            emit tokenMinted(_reciever, publicSupply);
        }
    }

    /* 
    * @param sig, the signature to verify
    * @param mintActive, the mint access control paramter
    * @param signer, the public key to verify the signature against
    * @param privateSector, if it is true, that means the private mint functions
    * is being called. otherwise it is the public mint functions being called.

    * @notice the modifier checks if the publicSupply counter is below 2000 if privateSector is false
    * it verifies that we are still within the public mint limits
    * if the privateSector paramter is true, it checks if the privateSupply is <= 2100
    * privateSupply starts at 2000. This way, the privateMint function ALWAYS mint 
    * between 2000 (exclusive) and 2100 (inclusive). 
    */
    modifier mintingChecks(
        bytes calldata sig,
        bool mintActive,
        address signer,
        bool privateSector
    ) {
        require(mintActive, "minting not active");
        
        if(!privateSector)
        require(!mintingLedger[msg.sender], "already minted");
    
        else 
        require(!privateMintingLedger[msg.sender], "already minted private");

        require(tx.origin == msg.sender, "only accounts");

        bool verification = verify(msg.sender, sig, signer);
        require(verification, "you are not whitlisted");

        if (privateSector)
            require(
                privateSupply + 1 <= privateSupplyLimit,
                "no more private supply"
            );
        else
            require(
                publicSupply + 1 <= publicSupplyLimit,
                "no more public supply"
            );
        if(!privateSector)
            mintingLedger[msg.sender] = true;
        else privateMintingLedger[msg.sender] = true;
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        if (isRevealed == true) {
            if (tokenId <= 2000) return normalURI;
            else return whaleURI;
        } else return notRevealedUri;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return
            (OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
                address(proxyRegistry.proxies(owner)) == operator) ||
            super.isApprovedForAll(owner, operator);
    }

    // @notice, tokenLedger is updated after minting and tokenTransfers
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        tokenLedger[tokenId] = to;
    }

    function toggleMint() external onlyOwner {
        privateMintActive = !privateMintActive;
        publicMintActive = !publicMintActive;
    }

    function setIsRevealed(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyOwner
    {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _base) external onlyOwner {
        baseExtension = _base;
    }

    function setPublicSupplyLimit(uint16 _newLimit) external onlyOwner {
        publicSupplyLimit = _newLimit;
    }

    function setPrivateSupplyLimit(uint16 _newLimit) external onlyOwner {
        privateSupplyLimit = _newLimit;
    }

    function setPublicMintActive(bool _state) external onlyOwner {
        publicMintActive = _state;
    }

    function setRegularSigner(address _signer) external onlyOwner {
        regularSigner = _signer;
    }

    function setPrivateSigner(address _signer) external onlyOwner {
        privateSigner = _signer;
    }

    function setPrivateMintActive(bool _state) external onlyOwner {
        privateMintActive = _state;
    }

    function totalSupply() public view returns (uint256) {
        return publicSupply + (privateSupply - 2000);
    }

    function getTokenLedger() external view returns (address[3000] memory) {
        return tokenLedger;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setNormalURI(string memory _uri) external onlyOwner {
        normalURI = _uri;
    }

    function setWhaleURI(string memory _uri) external onlyOwner {
        whaleURI = _uri;
    }

    function withdraw(address[] memory _payees, uint256[] memory _shares)
        public
        onlyOwner
    {
        require(address(this).balance > 0, "No balance to withdraw");
        require(_shares.length == _payees.length);
        uint256 totalShares;

        for (uint256 i; i < _shares.length; i++) totalShares += _shares[i];

        require(totalShares == 1000, "invalid shares");
        delete totalShares;

        uint256 contractBalance = address(this).balance;
        for (uint256 i; i < _shares.length; i++)
            _withdraw(_payees[i], (contractBalance * _shares[i]) / 1000);
    }

    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}
}
