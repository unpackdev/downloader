// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract JPEffect is ERC721A, ERC721ABurnable, Ownable {
    uint256 public price;
    uint256 public maxSupply;
    uint256 maxAmountPerTx;
    uint256 allowListRequired;
    string contractURL;
    string baseURI;
    address proxyRegistryAddress;
    bytes32 public merkleRoot;
    address public crossmintAddress; // 0xdab1a1854214684ace522439684a145e62505233
    mapping(address => uint256) private _minted;

    constructor(string memory _uri) ERC721A("The JP Effect", "JPE") {
        price = 123400000000000000;
        maxSupply = 1234;
        maxAmountPerTx = 3;
        allowListRequired = 1;
        baseURI = _uri;
    }

    function isOnAllowlist(bytes32[] memory _proof, address _claimer)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_claimer));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    // set merkle root
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        require(
            _supply > maxSupply,
            "New supply should be bigger than old one."
        );
        maxSupply = _supply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // Set allowlisting on/off (1/0)
    function setAllowListRequired(uint256 _value) public onlyOwner {
        allowListRequired = _value;
    }

    function isAllowListRequired() public view returns (uint256) {
        return allowListRequired;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    function mintedBalanceOf(address _address) public view returns (uint256) {
        return _minted[_address];
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     * Update it with setProxyAddress
     */
    function setProxyAddress(address _a) public onlyOwner {
        proxyRegistryAddress = _a;
    }

    function airdrop(address[] memory _addresses) public onlyOwner {
        uint256 length = _addresses.length;
        require(
            _totalMinted() + length <= maxSupply,
            "Cannot mint that many tokens."
        );
        for (uint256 i = 0; i < length; i++) {
            _mint(_addresses[i], 1);
            _minted[_addresses[i]] += 1;
        }
    }

    function airdrop(address _address, uint256 _amount) public onlyOwner {
        require(
            _totalMinted() + _amount <= maxSupply,
            "Cannot mint that many tokens."
        );
        _mint(_address, _amount);
        _minted[_address] += _amount;
    }

    // include a setting function so that you can change this later
    function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
        crossmintAddress = _crossmintAddress;
    }

    function mintPublic(uint256 quantity) external payable {
        require(allowListRequired == 0, "Must use the allow list.");
        require(quantity <= maxAmountPerTx, "Cannot mint that many tokens.");
        require(
            _totalMinted() + quantity <= maxSupply,
            "Cannot mint that many tokens."
        );
        require(msg.value >= quantity * price, "Not enough to pay for that.");

        _mint(msg.sender, quantity);
        _minted[_msgSender()] += quantity;
    }

    function mintAllowed(uint256 quantity, bytes32[] memory _proof)
        external
        payable
    {
        require(allowListRequired == 1, "Allow list is disabled.");
        require(quantity <= maxAmountPerTx, "Cannot mint that many tokens.");
        require(
            isOnAllowlist(_proof, _msgSender()),
            "You are not on the allow list."
        );
        require(
            _totalMinted() + quantity <= maxSupply,
            "Cannot mint that many tokens."
        );
        require(msg.value >= quantity * price, "Not enough to pay for that");

        _mint(msg.sender, quantity);
        _minted[_msgSender()] += quantity;
    }

    function crossmint(
        address _to,
        uint256 _quantity,
        bytes32[] memory _proof
    ) public payable {
        require(
            msg.sender == crossmintAddress,
            "This function is for Crossmint only."
        );
        require(_quantity <= maxAmountPerTx, "Cannot mint that many tokens.");
        if (allowListRequired == 1) {
            require(
                isOnAllowlist(_proof, address(msg.sender)),
                "You are not on the allow list."
            );
        }
        require(
            _totalMinted() + _quantity <= maxSupply,
            "Cannot mint that many tokens."
        );
        require(msg.value >= price * _quantity, "Not enough to pay for that");

        _mint(_to, _quantity);
        _minted[_to] += _quantity;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
