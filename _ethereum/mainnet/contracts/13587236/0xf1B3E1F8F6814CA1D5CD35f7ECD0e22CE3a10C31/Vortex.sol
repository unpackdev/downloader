// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "ECDSA.sol";

contract Vortex is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32;

    uint8 private _giftCount = 0;
    uint256 private _maxSupply;

    string private _tokenBaseURI;
    string private _defaultBaseURI;
    address private _signerWalet = 0x5f6B7aCbDcB4a43B67c4ba137F2DfEA32CbE371b;

    mapping(address => uint8) private presaleNumPerAddress;

    bool public locked;
    bool public bigBang;
    bool public presaleLive;
    bool public revealed;

    event NameGiven(uint256 indexed tokenId, string name);
    event StoryGiven(uint256 indexed tokenId, string story);
    event SolarEclipse(uint256 indexed tokenId, address observedAddress);

    /**
     * @dev Throws if called when BigBang has not happened yet
     */
    modifier alreadyRevealed() {
        require(revealed, "Wait for reveal!");
        _;
    }

    /**
     * @dev Throws if called when method is locked for usage
     */
    modifier notLocked() {
        require(!locked, "Methods are locked");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _max
    ) ERC721(_name, _symbol) {
        _tokenBaseURI = _uri;
        _maxSupply = _max;
    }

    function setBaseURI(string calldata _newUri) external onlyOwner notLocked {
        _tokenBaseURI = _newUri;
    }

    function setDefaultBaseURI(string calldata _newUri) external onlyOwner {
        _defaultBaseURI = _newUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");

        return
            bytes(_tokenBaseURI).length > 0
                ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString()))
                : _defaultBaseURI;
    }

    function lock() external onlyOwner {
        locked = true;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function executeBigBang() external onlyOwner {
        bigBang = !bigBang;
    }

    function togglePresale() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    /**
     * @dev In case the wallet is compromised
     */
    function setSignatureWallet(address _newSignerWallet) external onlyOwner {
        _signerWalet = _newSignerWallet;
    }

    function setName(uint256 _tokenId, string memory _name)
        external
        alreadyRevealed
    {
        require(_exists(_tokenId), "Cannot update non-existent token");
        require(ownerOf(_tokenId) == msg.sender, "You don't own this General!");
        emit NameGiven(_tokenId, _name);
    }

    function setStory(uint256 _tokenId, string memory _story)
        external
        alreadyRevealed
    {
        require(_exists(_tokenId), "Cannot update non-existent token");
        require(ownerOf(_tokenId) == msg.sender, "You don't own this General!");
        emit StoryGiven(_tokenId, _story);
    }

    /**
     * @dev Gift Generals to provided addresses.
     * @param _recipients List of addresses that will receive General
     */
    function gift(address[] memory _recipients) external onlyOwner {
        require(
            _giftCount + _recipients.length <= 100,
            "Max gift limit Reached!"
        );
        require(
            totalSupply().add(_recipients.length) <= _maxSupply,
            "All Generals are sold out. Sorry!"
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], totalSupply() + 1);
            _giftCount = _giftCount + 1;
        }
    }

    function mintPresale(
        uint8 _num,
        bytes calldata _signature,
        uint256 _maxLimit
    ) public payable {
        require(presaleLive, "Presale has not yet started.");
        require(
            totalSupply().add(uint256(_num)) <= _maxSupply,
            "All Generals are sold out. Sorry!"
        );
        require(
            presaleNumPerAddress[msg.sender] + _num <= _maxLimit,
            "Can't purchase more than allowed presale Generals"
        );
        require(
            msg.value >= uint256(_num).mul(5e16),
            "You need to pay the required price."
        );

        bytes32 messageHash = hashMessage(msg.sender, _maxLimit);
        require(messageHash.recover(_signature) == _signerWalet, "Wrong Hash");

        presaleNumPerAddress[msg.sender] += _num;
        _mintTokens(_num);
    }

    /**
     * @dev Mint to msg.sender.
     * @param _num addresses of the future owner of the token
     */
    function mint(uint8 _num) external payable {
        require(bigBang, "Wait for BigBang!");
        require(
            totalSupply().add(uint256(_num)) <= _maxSupply,
            "All Generals are sold out. Sorry!"
        );
        require(_num <= 5, "Max mint limit breached!");
        require(
            msg.value >= uint256(_num).mul(5e16),
            "You need to pay the required price."
        );
        _mintTokens(_num);
    }

    /**
     * @dev Helper function to mint list of tokens
     */
    function _mintTokens(uint8 _num) private {
        for (uint8 i = 0; i < _num; i++) {
            uint256 newTokenId = totalSupply() + 1;
            _mint(msg.sender, newTokenId);
            if (newTokenId % 100 == 0) {
                uint256 amount = random() % 100;
                uint256 realId = newTokenId - amount;
                address luckyAddress = ownerOf(realId);
                payable(luckyAddress).transfer(5e16);
                emit SolarEclipse(realId, luckyAddress);
            }
        }
    }

    /**
     * @dev generates a random number based on block info
     */
    function random() private view returns (uint256) {
        bytes32 randomHash = keccak256(
            abi.encode(
                block.timestamp,
                block.difficulty,
                block.coinbase,
                msg.sender
            )
        );
        return uint256(randomHash);
    }

    function hashMessage(address _sender, uint256 _maxLimit)
        internal
        pure
        returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_sender, _maxLimit))
            )
        );
        return hash;
    }
}
