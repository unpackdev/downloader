// SPDX-License-Identifier: MIT LICENSE
/*
 * @title NFN - Non-Fungible Names
 * @author Marcus J. Carey, @marcusjcarey
 * @notice $NFN is a ERC-721 Token to allow owners to use
 * one name across blockchains for transactions.
 */

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract NFN is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    address public payee;

    bool public affiliateProgramActive = true;
    bool private paused = false;
    bool public verificationRequired = false;

    string uriPrefix = 'https://www.nfn.cash/api/nfn/metadata/';
    string uriSuffix = '.json';

    uint256 public cost = 0.01 ether;

    uint256 public affiliateCommission = 25;
    uint256 public affiliateDiscount = 10;

    mapping(uint256 => bool) public banned;
    mapping(address => bool) public verified;

    mapping(address => bool) public admins;
    mapping(string => bool) private reservedWords;
    mapping(uint256 => string) public idToName;
    mapping(string => uint256) public nameToId;
    mapping(string => bool) public minted;

    mapping(uint256 => mapping(string => string)) private data;

    constructor() ERC721('Non-Fungible Names', 'NFN') {
        admins[msg.sender] = true;
        payee = msg.sender;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], 'Sender not owner or admin.');
        _;
    }

    /**
     * @dev Function provies quick lookup to see if sender owns the name
     */
    function isOwnerOfToken(uint256 _id) public view {
        require(ownerOf(_id) == msg.sender, 'Sender does not own token!!');
    }

    function isNameReserved(string memory _name) public view {
        require(!reservedWords[_name], 'Name has been reserved.');
    }

    function isNameValid(string memory _name) public view {
        uint256 _length = bytes(_name).length;
        require(!minted[_name], 'Name already exists!');
        require(_length > 1, 'Name must be at least two characters.');
    }

    function updateBanned(uint256 _id, bool _bool) public onlyAdmin {
        banned[_id] = _bool;
    }

    function updateAdmin(address _address, bool _bool) public onlyOwner {
        admins[_address] = _bool;
    }

    function updatePaused(bool _bool) public onlyAdmin {
        paused = _bool;
    }

    function updateReservedWords(string[] memory _reservedWords, bool _bool)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < _reservedWords.length; i++) {
            reservedWords[_reservedWords[i]] = _bool;
        }
    }

    /**
     * @dev updatedVerified() allows admin to add/remove bulk verified addresses
     */
    function updateVerified(address[] memory _verifiedAddresses, bool _bool)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < _verifiedAddresses.length; i++) {
            verified[_verifiedAddresses[i]] = _bool;
        }
    }

    function affiliateCost(string memory _name) public view returns (uint256) {
        isNameReserved(_name);

        return
            calculateCost(_name, cost) -
            (calculateCost(_name, cost) * affiliateDiscount) /
            100;
    }

    /**
     * @dev configureAffiliateProgram allows admin to set program variables all at once
     */
    function configureAffiliateProgram(
        uint256 _affiliateCommission,
        uint256 _affiliateDiscount,
        bool _affiliateProgramActive,
        bool _verificationRequired
    ) public onlyAdmin {
        affiliateCommission = _affiliateCommission;
        affiliateDiscount = _affiliateDiscount;
        affiliateProgramActive = _affiliateProgramActive;
        verificationRequired = _verificationRequired;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function _mint(address _to, string memory _name) private {
        require(!paused, 'The contract is paused!');
        isNameValid(_name);

        _safeMint(_to, supply.current());
        idToName[supply.current()] = _name;
        nameToId[_name] = supply.current();
        minted[_name] = true;
        supply.increment();
    }

    function mint(string memory _name) public payable {
        isNameReserved(_name);
        require(
            msg.value >= calculateCost(_name, cost),
            'Payment is insufficient!'
        );
        _mint(msg.sender, _name);
    }

    /**
     * @dev mintForAddress allows airdrop of name and intentionally bypasses reserved words lookup
     * Admin needs to remove any names from the reserved words mapping for them to use name
     */
    function mintForAddress(string memory _name, address _receiver)
        public
        onlyAdmin
    {
        _mint(_receiver, _name);
    }

    /**
     * @dev mintViaAffiliate allows sender to mint at discount and it sends commission to the affiliate
     */
    function mintViaAffiliate(string memory _name, string memory _affiliate)
        public
        payable
    {
        isNameReserved(_name);
        require(!banned[nameToId[_name]], 'Affiliate is banned');
        require(affiliateProgramActive, 'Afilliate program not active!');
        require(minted[_affiliate], 'Affiliate does not exist!');
        if (verificationRequired) {
            require(
                verified[ownerOf(nameToId[_affiliate])],
                'Affiliate is not verified.'
            );
        }

        require(msg.value >= affiliateCost(_name), 'Payment is insufficient!');

        _mint(msg.sender, _name);
        payable(ownerOf(nameToId[_affiliate])).transfer(
            (affiliateCost(_name) * affiliateCommission) / 100
        );
    }

    function getData(uint256 _id, string calldata _key)
        public
        view
        returns (string memory)
    {
        return data[_id][_key];
    }

    function updateData(
        uint256 _id,
        string calldata _key,
        string calldata _value
    ) public {
        isOwnerOfToken(_id);
        data[_id][_key] = _value;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount &&
            currentTokenId <= supply.current()
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

    function getNames() public view returns (string[] memory) {
        uint256[] memory _ids = walletOfOwner(msg.sender);
        string[] memory _names = new string[](_ids.length);

        for (uint256 i = 0; i < _ids.length; i++) {
            _names[i] = idToName[_ids[i]];
        }
        return _names;
    }

    function calculateCost(string memory _name, uint256 _baseCost)
        public
        pure
        returns (uint256 x)
    {
        uint256 length = bytes(_name).length;
        assembly {
            switch length
            case 2 {
                x := 1000
            }
            case 3 {
                x := 900
            }
            case 4 {
                x := 800
            }
            case 5 {
                x := 700
            }
            case 6 {
                x := 600
            }
            case 7 {
                x := 500
            }
            case 8 {
                x := 400
            }
            case 9 {
                x := 300
            }
            default {
                x := 250
            }
        }
        return _baseCost + (_baseCost * x) / 100;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyAdmin {
        uriPrefix = _uriPrefix;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );

        return
            bytes(uriPrefix).length > 0
                ? string(
                    abi.encodePacked(uriPrefix, _tokenId.toString(), uriSuffix)
                )
                : '';
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function setPayee(address _payee) public onlyAdmin {
        payee = _payee;
    }

    function setCost(uint256 _cost) public onlyAdmin {
        cost = _cost;
    }

    function withdraw() public onlyAdmin {
        (bool os, ) = payable(payee).call{value: address(this).balance}('');
        require(os);
    }

    function withdrawToken(address _address) external onlyAdmin {
        IERC20 token = IERC20(_address);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(payee, amount);
    }
}
