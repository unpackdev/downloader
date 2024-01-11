// SPDX-License-Identifier: MIT
// File: contracts/TrapVerse.sol
pragma solidity >=0.8.12;
import "./Ownable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./MerkleProof.sol";
//   ______            _   __               
//  /_  __/______ ____| | / /__ _______ ___ 
//   / / / __/ _ `/ _ \ |/ / -_) __(_-</ -_)
//  /_/ /_/  \_,_/ .__/___/\__/_/ /___/\__/ 
//              /_/                         
contract TrapVerse is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private supply;
    bool public paused;
    bool public revealed;
    bool public presale;
    uint256 public constant maxSupply = 3333;
    uint256 public cost = 0.0666 ether;
    uint256 public maxMintAmountPerTx = 5;
    uint256 public maxPerPresaleAddress = 5;
    uint256 public reserveCount;
    uint256 public reserveLimit = 100;
    address public constant projAddress = 0x2584DE60596137817535330F04591fd35341E1Dd;
    address public constant devAddress = 0xcf04ec9Ef36DB4c7ab37f1F1471f182cAa4BAbE9;
    address public constant devtwoAddress = 0x769c507Ac7E1bE1E38834C414b0EeAc6b83Dd5a9;
    address public constant commAddress = 0x901026613BF616D4Bc15e33EB0bccBbEd3e7892b;
    bytes32 public merkleRoot;
    string public uriPrefix;
    string public uriSuffix;
    string public uriHidden;
    mapping(address => uint256) private _presaleClaimed;
    constructor(bytes32 _merkleRoot, string memory _uriHidden)
        ERC721("TrapVerse", "TRAP")
    {
        merkleRoot = _merkleRoot;
        uriPrefix = "UNREVEALED";
        uriSuffix = ".json";
        uriHidden = _uriHidden;
        reserveCount = 0;
        paused = true;
        revealed = false;
        presale = true;
    }
    function mintPresale(
        address account,
        uint256 _mintAmount,
        bytes32[] calldata merkleProof
    ) public payable mintCompliance(_mintAmount) {
        bytes32 node = keccak256(abi.encodePacked(account, maxPerPresaleAddress));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid whitelist proof."
        );
        require(presale, "No presale minting currently.");
        require(msg.value >= cost * _mintAmount, "Insufficient funds.");
        require(
            _presaleClaimed[account] + _mintAmount <= maxPerPresaleAddress,
            "Exceeds max mints for presale."
        );
        _mintLoop(account, _mintAmount);
        _presaleClaimed[account] += _mintAmount;
    }
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
    {
        require(!presale, "Only presale minting currently.");
        require(msg.value >= cost * _mintAmount, "Insufficient funds.");
        _mintLoop(msg.sender, _mintAmount);
    }
    modifier mintCompliance(uint256 _mintAmount) {
        require(!paused, "The sale is paused.");
        require(_mintAmount > 0, "Must be greater than 0.");
        require(_mintAmount <= maxMintAmountPerTx, "Invalid mint amount.");
        require(
            supply.current() + _mintAmount <= maxSupply,
            "Max supply exceeded."
        );
        _;
    }
    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }
    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        require(
            reserveCount + _mintAmount <= reserveLimit,
            "Exceeds max of 100 reserved."
        );
        _mintLoop(_receiver, _mintAmount);
        reserveCount += _mintAmount;
    }
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );
        if (revealed == false) {
            return uriHidden;
        }
        string memory currentBaseURI = uriPrefix;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }
    function setMerkleRoot(bytes32 newRoot) public onlyOwner {
        merkleRoot = newRoot;
    }
    function setUriHidden(string memory _uriHidden) public onlyOwner {
        uriHidden = _uriHidden;
    }
    function setUriPrefix(string memory uriPrefixNew) public onlyOwner {
        uriPrefix = uriPrefixNew;
    }
    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }
    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }
    function setReserveLimit(uint256 _newLimit) public onlyOwner {
        reserveLimit = _newLimit;
    }
    function setMaxPerPresaleAddress(uint256 _maxPerPresaleAddress) public onlyOwner {
        maxPerPresaleAddress = _maxPerPresaleAddress;
    }
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }
    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }
    function setPresale(bool _state) public onlyOwner {
        presale = _state;
    }
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(devAddress, ((balance * 5) / 100));
        _widthdraw(devtwoAddress, ((balance * 5) / 100));
        _widthdraw(commAddress, ((balance * 5) / 100));
        _widthdraw(projAddress, address(this).balance);
    }  
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}
