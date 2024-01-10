// SPDX-License-Identifier: NONE
pragma solidity ^0.8.2;
import "./console.sol";

import "./AccessControl.sol";
import "./ERC721Enumerable.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract ManualMintCollection is ERC721Enumerable, AccessControl, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;
    EnumerableSet.AddressSet private referencedAccounts;
    mapping(address => uint256) private accountCuts;
    mapping(address => uint256) private accountHolding;
    uint64 private maxSplitPool = 0;
    string private uriBase = '';
    uint256 public maxSupply = 0;
    uint64 public maxMintAmount = 5;
    uint256 public mintingPrice;
    bool public isSaleStarted = false;
    struct Split {
        address account;
        uint64 split;
    }

    bytes32 public constant SALE_STARTER_ROLE = keccak256('SALE_STARTER_ROLE');

    function uri(uint256 id) public view virtual returns (string memory) {
        //return _uri;
        return string(abi.encodePacked(uriBase, Strings.toString(id)));
    }

    modifier supplyLeft(uint64 _mintAmount) {
        if (super.totalSupply() + _mintAmount > maxSupply) {
            revert('Max supply is reached!');
        }
        _;
    }

    modifier saleStarted() {
        if (!isSaleStarted) {
            revert('Sale is not started!');
        }
        _;
    }

    constructor(
        string memory _collectionName,
        string memory _collectionSymbol,
        string memory _baseUri,
        Split[] memory _splits,
        uint256 _maxSupply,
        uint64 _maxMintAmount,
        uint256 _mintingPrice,
        bool _isSaleStarted
    ) ERC721(_collectionName, _collectionSymbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SALE_STARTER_ROLE, msg.sender);
        isSaleStarted = _isSaleStarted;
        uriBase = _baseUri;
        maxSupply = _maxSupply;
        mintingPrice = _mintingPrice;
        maxMintAmount = _maxMintAmount;
        tokenIdCounter.increment();
        for (uint64 counter = 0; counter < _splits.length; counter++) {
            EnumerableSet.add(referencedAccounts, _splits[counter].account);
            _setupRole(SALE_STARTER_ROLE, _splits[counter].account);
            require(_splits[counter].split > 0, 'Splits have to be positive!');
            maxSplitPool += _splits[counter].split;
            accountCuts[_splits[counter].account] = _splits[counter].split;
        }
    }

    function nativeCoinMint(uint64 _mintAmount)
        public
        payable
        supplyLeft(_mintAmount)
        saleStarted
        returns (uint256[] memory)
    {
        require(
            _mintAmount <= maxMintAmount,
            'You try to mint too much at once!'
        );
        require(_mintAmount > 0, 'You have to mint something!');
        require(msg.value >= mintingPrice * _mintAmount, 'Amount is too low!');
        uint256[] memory result = new uint256[](_mintAmount);
        uint256 tokenId;
        for (uint64 counter = 0; counter < _mintAmount; counter++) {
            tokenId = tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
            tokenIdCounter.increment();
            result[counter] = tokenId;
        }
        for (
            uint64 splitCounter = 0;
            splitCounter < EnumerableSet.length(referencedAccounts);
            splitCounter++
        ) {
            accountHolding[
                EnumerableSet.at(referencedAccounts, splitCounter)
            ] +=
                (accountCuts[
                    EnumerableSet.at(referencedAccounts, splitCounter)
                ] * msg.value) /
                maxSplitPool;
        }
        return result;
    }

    function setSaleState(bool _state) public onlyRole(SALE_STARTER_ROLE) {
        isSaleStarted = _state;
    }

    function withdrawBalance() external {
        uint256 share = accountHolding[msg.sender];
        require(share > 0, 'Nothing to withdraw!');
        accountHolding[msg.sender] = 0;
        payable(msg.sender).transfer(share);
    }

    function withdrawableBalance() public view returns (uint256) {
        return accountHolding[msg.sender];
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return uriBase;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(uriBase, Strings.toString(_tokenId), '.json')
            );
    }
}
