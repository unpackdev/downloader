//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./ECDSA.sol";

contract Renegade_Comics is ERC1155 {
    using ECDSA for bytes32;

    uint256 private issueIdsCounter;
    uint256 private tokenIdsCounter;

    string public name;
    string public symbol;

    struct Issue {
        string title;
        string[] rarities;
        uint256[] mintAmount;
        uint256[] mintAvailable;
        uint256 totalAvailable;
        string uri;
        uint256 whitelistMintPrice;
        uint256 publicMintPrice;
        bool mintingPaused;
    }

    mapping(uint256 => Issue) public issues;
    mapping(uint256 => mapping(uint256 => uint256)) public tokenIds; //issueId[rarity] => tokenId
    mapping(uint256 => uint256) public tokenIdToIssueId; //tokenId => IssueId
    mapping(address => mapping(uint256 => uint256)) public userMinted; // userAddress[issueId] => tokenId

	address internal immutable owner = msg.sender;

    address public immutable whitelistToken;
    bool public whitelistEnabled;

    bool private signatureEnabled;
    address private signatureTrustedSigner;

    event IssueAdded(uint256 issueId, string title, string[] rarities, uint256[] mintAmount, string uri);

    error OnlyOwner();
    error OnlyWhitelisted();
    error IssueUnexisting();
    error IssueUnavailable();
    error IssuePaused();
    error IssueDataMissmatch();
    error IssueAlreadyMinted();
    error Underpaid();
    error WrongSignature();

    constructor(address _whitelistToken, string memory _name, string memory _symbol) 
        ERC1155("")
    {
        whitelistToken = _whitelistToken;
        whitelistEnabled = true;
        signatureEnabled = false;
        name = _name;
        symbol = _symbol;
        unchecked{ 
            ++tokenIdsCounter;
        }
    }

    function addIssue(string calldata _title, string[] calldata _rarities, uint256[] calldata _amounts, string calldata _uri, uint256 _whitelistMintPrice, uint256 _publicMintPrice) 
        public
        onlyOwner 
    {
        if(_rarities.length != _amounts.length) revert IssueDataMissmatch();

        unchecked{ 
            ++issueIdsCounter; 
        }
        uint256 _issueId = issueIdsCounter;

        uint256 _totalAvailable = 0;
        for(uint256 _i=0; _i<_amounts.length; ){
            tokenIds[_issueId][_i] = tokenIdsCounter;
            tokenIdToIssueId[tokenIdsCounter] = _issueId;
            unchecked {
                _totalAvailable += _amounts[_i];
                tokenIdsCounter++;
                ++_i;
            }
        }

        issues[_issueId] = Issue(_title, _rarities, _amounts, _amounts, _totalAvailable, _uri, _whitelistMintPrice, _publicMintPrice, false);

        emit IssueAdded(_issueId, _title, _rarities, _amounts,  _uri);
    }

    function pauseIssueMinting(uint256 _issueId, bool _paused)
        public
        onlyOwner
    {
        if(issues[_issueId].rarities.length == 0) revert IssueUnexisting();
        issues[_issueId].mintingPaused = _paused;
    }

    function getIssue(uint256 _issueId) 
        external 
        view 
        returns (Issue memory)
    {
        return issues[_issueId];
    }

    function setWhitelistEnabled(bool _whitelistEnabled)
        public
        onlyOwner
    {
        whitelistEnabled = _whitelistEnabled;
    }

    function setSignatureEnabled(bool _signatureEnabled, address _trustedSigner)
        public
        onlyOwner
    {
        signatureEnabled = _signatureEnabled;
        signatureTrustedSigner = _trustedSigner;
    }

    function mint(uint256 _issueId, bytes memory _signature) 
        external 
        payable 
        onlyWhitelisted
    {
        if(issues[_issueId].rarities.length == 0) revert IssueUnexisting();
        if(issues[_issueId].totalAvailable == 0) revert IssueUnavailable();
        if(issues[_issueId].mintingPaused) revert IssuePaused();
        if(msg.value < getMintPrice(_issueId)) revert Underpaid();
        if(userMinted[_msgSender()][_issueId] != 0) revert IssueAlreadyMinted();

        if(signatureEnabled) {
            string memory _sender = _toAsciiString(_msgSender());
            bytes32 _messageHash = keccak256(abi.encodePacked(_sender,"_issueId_",_uint2str(_issueId)));
            if(_messageHash.toEthSignedMessageHash().recover(_signature) != signatureTrustedSigner){
                revert WrongSignature();
            }
        }

        // Get the rarity
        uint256 _rarity;
        uint256 _attempt = 0;
        do{
            _rarity = _getRarity(_issueId, _attempt);
            unchecked {
                ++_attempt;
            }
        }while(issues[_issueId].mintAvailable[_rarity] == 0);

        unchecked {
            --issues[_issueId].mintAvailable[_rarity];
            --issues[_issueId].totalAvailable;
        }

        userMinted[_msgSender()][_issueId] = tokenIds[_issueId][_rarity];

        _mint(_msgSender(), tokenIds[_issueId][_rarity], 1, "");
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return issues[tokenIdToIssueId[_tokenId]].uri;
    }

    function getMintPrice(uint256 _issueId)
        public
        view
        returns (uint256)
    {
        return whitelistEnabled ? issues[_issueId].whitelistMintPrice : issues[_issueId].publicMintPrice;
    }

    function withdraw() 
        external 
        onlyOwner 
    {
        payable(owner).transfer(address(this).balance);
    }

    function _getRarity(uint256 _issueId, uint256 _attempt) 
        internal 
        view
        returns (uint256)
    {
        if(issues[_issueId].rarities.length == 0) revert IssueUnexisting();

        uint256 _random = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, issues[_issueId].mintAvailable, _attempt)));
        return _random % issues[_issueId].rarities.length;
    }

    function _toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);            
        }
        return string(abi.encodePacked("0x",s));
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    modifier onlyOwner() {
        if(owner != _msgSender()) revert OnlyOwner();
        _;
    }

    modifier onlyWhitelisted() {
        if(whitelistEnabled){
            if(IERC20(whitelistToken).balanceOf(_msgSender()) <= 0) revert OnlyWhitelisted();
        }
        _;
    }
}