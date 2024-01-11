// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ECDSA.sol";

import "./ERC721A.sol";

contract Gem is ERC2981, ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;

    uint256 public _price;
    uint32 public _walletFreeLimit;
    uint32 public _maxSupply;

    uint32 public _teamSupply;
    uint32 public _teamMinted;

    uint32 public _boosterSupply;
    uint256 public _boosterTimeout;
    uint32 public _boosterMinted;
    bool public isTimeout = false;
    uint32 public _boosterLimit;
    
    bool public _started;
    string public _metadataURI = "https://metadata.mypinata.cloud/ipfs/QmTYyVNRYWeruHH3ifyM5NVMuGwUiWgdBw8QtipeP5pqRS/";
    string public notRevealedURI = "http://lfggemnft.wtf/";
    bool public revealed = true;

    address public signer;

    struct Status {
        uint256 price;
        uint32 walletFreeLimit;
        uint32 maxSupply;

        uint32 teamSupply;
        uint32 teamMinted;

        uint32 boosterSupply;
        uint256 boosterTimeout;
        uint32 boosterMinted;
        
        bool started;

        uint32 userMinted;
        bool soldout;
    }

    constructor(
        address _signer, 
        uint256 price,
        uint32 maxSupply,
        uint32 teamSupply,
        uint32 boosterSupply,
        uint32 walletFreeLimit
    ) ERC721A("LFG Gem", "LFGGEM", 200, maxSupply) {
        require(maxSupply > teamSupply);

        _price = price;
        _maxSupply = maxSupply;
        _teamSupply = teamSupply;
        _boosterSupply = boosterSupply;
        _boosterLimit = boosterSupply;
        _walletFreeLimit = walletFreeLimit;
        signer = _signer;

        _boosterTimeout = block.timestamp + 1800;
        setFeeNumerator(1000);
    }


    function mint(uint32 amount, bytes memory signature) external payable {
        require(_started, "Gem: Sale is not started");
        if (!isTimeout && block.timestamp >= _boosterTimeout) {
            isTimeout = true;
            _boosterLimit = _boosterMinted;
        }

        if(!isTimeout && signer == _signatureWallet(msg.sender, signature)) {
            if (_boosterMinted + amount <= _boosterLimit) {
                mint_pay(amount);
                _boosterMinted += amount;
            } else {
                uint32 publicAmount = amount - (_boosterLimit - _boosterMinted);
                require(publicAmount + _publicMinted() <= _publicSupply(), "Gem: Exceed max supply");
                mint_pay(amount);
                _boosterMinted = _boosterLimit;
            }
        } else {
            require(amount + _publicMinted() <= _publicSupply(), "Gem: Exceed max supply");
            mint_pay(amount);
        }
    }

    function mint_pay(uint32 amount) internal {
        uint32 minted = uint32(_numberMinted(msg.sender));
        uint256 requiredValue = 0;

        if (minted + amount > _walletFreeLimit) {
            uint32 payAmount = minted + amount - _walletFreeLimit;
            if (payAmount > amount)  payAmount = amount;
            requiredValue = payAmount * _price;
        }

        require(msg.value >= requiredValue, "Gem: Insufficient fund");

        _safeMint(msg.sender, amount);
        if (msg.value > requiredValue) {
            payable(msg.sender).sendValue(msg.value - requiredValue);
        }
    }
    
    function _signatureWallet (address sender, bytes memory signature) private pure returns (address){
        bytes32 hash = keccak256(
            abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender))
            )
        );
        (address s, ) = ECDSA.tryRecover(hash, signature);
        return s;
    }

    function _publicMinted() public view returns (uint32) {
        return uint32(totalSupply()) - _teamMinted - _boosterMinted;
    }

    function _publicSupply() public view returns (uint32) {
        return _maxSupply - _teamSupply - _boosterLimit;
    }

    function _status(address minter) external view returns (Status memory) {
        return Status({
            price: _price,
            walletFreeLimit: _walletFreeLimit,
            maxSupply: _maxSupply,

            teamSupply: _teamSupply,
            teamMinted: _teamMinted,

            boosterSupply: _boosterSupply,
            boosterTimeout: _boosterTimeout,
            boosterMinted: _boosterMinted,
        
            userMinted: uint32(_numberMinted(minter)),
            soldout: totalSupply() >= _maxSupply,
            started: _started
        });
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedURI;
        }

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function toggleRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function setNotRevealedURI(string memory newNotRevealedURI) external onlyOwner {
        notRevealedURI = newNotRevealedURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function devMint(address to, uint32 amount) external onlyOwner {
        _teamMinted += amount;
        require(_teamMinted <= _teamSupply, "Gem: Exceed max supply");
        _safeMint(to, amount);
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function setPrice(uint256 _newValue) external onlyOwner {
        _price = _newValue;
    }

    function setMaxSupply(uint32 _newValue) external onlyOwner {
        _maxSupply = _newValue;
    }

    function setTeamSupply(uint32 _newValue) external onlyOwner {
        _teamSupply = _newValue;
    }
    
    function setBoosterSupply(uint32 _newValue) external onlyOwner {
        require(!isTimeout, "Gem:Boost mint is timeout!");
        require(_newValue > _boosterMinted, "Gem: new value must be greater minted");
        _boosterSupply = _newValue;
        _boosterLimit = _newValue;
    }

    function setBoosterTimeout(uint256 time) external onlyOwner {
        require(time > _boosterTimeout, "Gem: new timeout must be greater now");
        _boosterTimeout = time;
        isTimeout = false;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    address private wallet1 = 0x37149e5EDB00cec8B14683D4887dD26ad9E7C652;
    address private wallet2 = 0xE8A741b16cD940B06FcC9D66AB8329114C2D74a3;

    function withdraw() external onlyOwner {
        payable(wallet1).sendValue(address(this).balance/2);
        payable(wallet2).sendValue(address(this).balance/2);
    }
}