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

contract Gods is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    SignatureVerifier
{
    using Strings for uint256;

    mapping(address => bool) public mintingLedger;
    address[2000] public tokenLedger;

    uint256 publicMintCost;
    uint256 privateMintCost;

    /* entire storage slot */
    address regularSigner;
    uint16 public privateSupply;
    uint16 public publicSupply;
    uint16 public privateSupplyLimit;
    uint16 public publicSupplyLimit;
    bool publicMintActive;
    bool isRevealed;
    bool privateMintActive;
    bool teamClaimed;
    /* entire storage slot */

    address privateSigner;
    string public baseURI;
    string public notRevealedUri;
    string public baseExtension;
    address public reciever_1;
    address public reciever_2;
    address proxyRegistryAddress;

    event tokenMinted(address, uint256);

    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721_init("GODS", "GODSGAME");
        publicMintCost = 0.1 ether;
        privateMintCost = 0.3 ether;
        publicMintActive = false;
        privateMintActive = false;
        regularSigner = 0x545e3416EA6B609fa805A6fF980Bfa4b4BA39178;
        privateSigner = 0xAAEce8a08236FbdE6e2917167e111d29aC6AFdab;
        baseExtension = ".json";

        reciever_1 = 0x7d43Fe4a7F0DFCec5C2D2902561F4903b99651a8;
        reciever_2 = 0x6f02f5996653c2877Fc08cd20EFC2c595AcBc7C2;
        proxyRegistryAddress = 0xe850eB266384A133844976aC66B98A44eDBFCb0d;
        /* we are keeping track of two different counters.
         * privateSupply, which is limited by the privateSupplyLimit.
         * and publicSupply, which is limited by the privateSupplyLimit.
         * publicSupply is incremented in the mint function, and it starts from 70 up to limit.
         * privateSupply is incremented in the privateMint funciton, and starts from 0 up to limit.
         * the totalSupply function returns  ( privateSupply + ( publicSupply - 70),
         * effectivly giving us the total minted supply.
         * both limits can be modified in their respective functions.
         */
        privateSupply = 0;
        publicSupply = 70;
        privateSupplyLimit = 70;
        publicSupplyLimit = 999;
    }

    function mint(bytes calldata sig)
        external
        payable
        nonReentrant
        whenNotPaused
        mintingChecks(
            sig,
            publicMintActive,
            regularSigner,
            publicMintCost,
            false
        )
    {
        _safeMint(msg.sender, ++publicSupply);
        emit tokenMinted(msg.sender, publicSupply);
    }

    function privateMint(bytes calldata sig)
        external
        payable
        nonReentrant
        whenNotPaused
        mintingChecks(
            sig,
            privateMintActive,
            privateSigner,
            privateMintCost,
            true
        )
    {
        _safeMint(msg.sender, ++privateSupply);
        emit tokenMinted(msg.sender, privateSupply);
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
        uint256 cost,
        bool privateSector
    ) {
        require(mintActive, "minting not active");
        require(!mintingLedger[msg.sender], "already minted");
        require(tx.origin == msg.sender, "only accounts");

        bool verification = verify(msg.sender, sig, signer);
        require(verification, "you are not whitlisted");
        require(msg.value >= cost, "not enough funds");

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
        mintingLedger[msg.sender] = true;
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
        } else return notRevealedUri;
    }

    function teamAirdrop(
        uint256[] calldata quantity,
        address[] calldata recipient
    ) external onlyOwner {
        require(
            quantity.length == recipient.length,
            "Quantity length is not equal to recipients"
        );

        require(!teamClaimed, "team already claimed");
        teamClaimed = true;

        uint256 totalQuantity;
        for (uint256 i; i < quantity.length; ++i) {
            totalQuantity += quantity[i];
        }

        require(
            privateSupply + totalQuantity <= privateSupplyLimit,
            "no more privateSupply"
        );

        delete totalQuantity;

        for (uint256 i; i < recipient.length; ++i) {
            for (uint256 j; j < quantity[i]; ++j) {
                _safeMint(recipient[i], ++privateSupply);
                emit tokenMinted(recipient[i], privateSupply);
            }
        }
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

    function withdraw() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No balance to withdraw");
        uint256 contractBalance = address(this).balance;

        _withdraw(reciever_1, (contractBalance * 4) / 100);
        _withdraw(reciever_2, (contractBalance * 96) / 100);
    }

    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        tokenLedger[tokenId] = to;
    }

    function setIsRevealed(bool _state) external onlyOwner {
        isRevealed = _state;
    }

    function setPublicSupplyLimit(uint16 _newLimit) external onlyOwner {
        publicSupplyLimit = _newLimit;
    }

    function setPrivateSupplyLimit(uint16 _newLimit) external onlyOwner {
        privateSupplyLimit = _newLimit;
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

    function setPublicMintCost(uint256 _cost) external onlyOwner {
        publicMintCost = _cost;
    }

    function setPrivateMintCost(uint256 _cost) external onlyOwner {
        privateMintCost = _cost;
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

    function totalSupply() external view returns (uint256) {
        return privateSupply + (publicSupply - 70);
    }

    function getTokenLedger() external view returns (address[2000] memory) {
        return tokenLedger;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setReciever_1(address _addr) external onlyOwner {
        reciever_1 = _addr;
    }

    function setReciever_2(address _addr) external onlyOwner {
        reciever_2 = _addr;
    }
}
