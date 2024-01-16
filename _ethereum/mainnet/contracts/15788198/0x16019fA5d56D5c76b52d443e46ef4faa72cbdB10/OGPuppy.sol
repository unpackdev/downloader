// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract OGPuppy is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public mintMax;
    uint256 public holdMax;
    uint256 public earnings;
    bool public whitelisted = true;
    string public baseURI;
    address public signer;
    bool public open;
    mapping(uint256 => string) private _tokenURIs;

    event Received(address, uint256);
    event WithdrawalSuccess(uint256 amount);

    struct SettingsStruct {
        string name;
        string symbol;
        string baseURI;
        uint256 mintPrice;
        uint256 mintMax;
        uint256 maxSupply;
        uint256 holdMax;
        uint256 totalMinted;
        uint256 totalBurned;
        uint256 totalSupply;
        uint256 earnings;
        address signer;
        bool whitelisted;
        bool open;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _mintMax,
        uint256 _holdMax,
        address _signer
    ) ERC721A(_name, _symbol) {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        mintMax = _mintMax;
        holdMax = _holdMax;
        signer = _signer;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function setBaseURI(string memory newuri) external onlyOwner {
        require(bytes(newuri).length > 0, "New URL Invalid");
        baseURI = newuri;
    }

    function setTokenURI(uint256 id, string memory newURL) external onlyOwner {
        require(_exists(id), "Invalid Token Id");
        require(bytes(newURL).length > 0, "New URL Invalid");
        _tokenURIs[id] = newURL;
    }

    function setMaxSupply(uint256 newSupply) public payable onlyOwner nonReentrant {
        require(newSupply > 0 && newSupply > maxSupply, "Invalid amount");
        maxSupply = newSupply;
    }

    function setSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "200:ZERO_ADDRESS");
        require(newSigner != signer, "It is the same current address");
        signer = newSigner;
    }

    function setOpen(bool _open) external onlyOwner {
        open = _open;
    }

    function setWhitelisted(bool _whitelisted) external onlyOwner {
        whitelisted = _whitelisted;
    }

    function setMintPrice(uint256 newMintPrice) public payable onlyOwner nonReentrant {
        require(newMintPrice > 0, "Invalid amount");
        mintPrice = newMintPrice;
    }

    function setMintMax(uint256 newMintMax) public payable onlyOwner nonReentrant {
        require(newMintMax > 0, "Invalid amount");
        mintMax = newMintMax;
    }

    function setHoldMax(uint256 newHoldMax) public payable onlyOwner nonReentrant {
        require(newHoldMax > 0, "Invalid amount");
        require(whitelisted, "Presale is over");
        holdMax = newHoldMax;
    }

    function airdrop(address receiver, uint256 amount)
        public
        onlyOwner
        nonReentrant
    {
        require(amount > 0 && amount <= mintMax, "Minting limit reached");
        require(maxSupply >= amount + _totalMinted(), "Supply limit");
        _buy(receiver, amount);
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function mint(bytes memory signature, uint256 quantity)
        public
        payable
        nonReentrant
    {
        require(open, "Contract closed");
        require(quantity > 0, "Invalid quantity");
        require(quantity <= mintMax, "Minting limit reached");
        require(msg.value >= quantity * mintPrice, "Insufficient ETH amount");
        require(
            maxSupply >= quantity + _totalMinted(),
            "Quantity exceeds total supplied"
        );
        if (whitelisted) {
            require(_verify(signature, quantity), "Wallet is not whitelisted");
            require(
                _numberMinted(msg.sender) + quantity <= holdMax,
                "Hold limit reached by address"
            );
        }
        _buy(msg.sender, quantity);
        earnings += quantity * mintPrice;
    }

    function _buy(address to, uint256 quantity) internal {
        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId, bool approvalCheck)
        public
        payable
        nonReentrant
    {
        _burn(tokenId, approvalCheck);
    }

    function withdrawByOwner(address _address, uint256 amount)
        public
        nonReentrant
        onlyOwner
    {
        require(_address != address(0), "200:ZERO_ADDRESS");
        require(amount > 0, "Invalid amount");
        require(address(this).balance >= amount, "Insuficient balance");
        (bool success, ) = _address.call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawalSuccess(amount);
    }

    function _verify(bytes memory signature, uint256 tokenAmount)
        internal
        view
        returns (bool)
    {
        bytes32 freshHash = keccak256(abi.encode(msg.sender, tokenAmount));
        bytes32 candidateHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );
        return _verifyHashSignature(candidateHash, signature);
    }

    function _verifyHashSignature(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address recoverySigner = address(0);
        // If the version is correct, gather info
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            recoverySigner = ecrecover(hash, v, r, s);
        }
        return signer == recoverySigner;
    }

    function setMultiple(
        uint256 _maxSupply,
        uint256 _mintPrice,
        uint256 _mintMax,
        uint256 _holdMax
    ) external onlyOwner {
        require(_maxSupply > _totalMinted(), "Total supply too low");
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        mintMax = _mintMax;
        holdMax = _holdMax;
    }

    function getSettings()
        public
        view
        returns (SettingsStruct memory)
    {
        SettingsStruct memory settings = SettingsStruct({
            name: name(),
            symbol: symbol(),
            baseURI: baseURI,
            mintPrice: mintPrice,
            mintMax: mintMax,
            maxSupply: maxSupply,
            holdMax: holdMax,
            totalMinted: _totalMinted(),
            totalBurned: _totalBurned(),
            totalSupply: totalSupply(),
            earnings: earnings,
            signer: signer,
            whitelisted: whitelisted,
            open: open
        });
        return settings;
    }
}
