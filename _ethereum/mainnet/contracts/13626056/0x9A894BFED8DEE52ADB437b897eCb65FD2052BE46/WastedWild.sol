// SPDX-License-Identifier: MIT

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.0;

contract WastedWild is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    
    IERC721 public _arbo1;
    IERC721 public _arbo2;
    IERC721 public _arfes;
    IERC721 public _arfw;

    //price variables
    uint256 public constant PRICE_PER_TOKEN = 0.07 ether;

    //supply variables
    uint256 public _maxSupply = 6666;
    uint256 public _maxPerTxn = 5;
    uint256 public _reservedArtistEdtns = 12; //Artist editions to reserve in the beginning

    //sale state control variables
    bool public _isBurningEnabled;
    bool public _isMintingEnabled = true;
    bool public _isClaimingEnabled = true;
    uint256 public _startSaleTimestamp = 1637078400; //11/16/2021 11:00AM EST
    uint256 public _firstWindow = 172800; //48 hours
    uint256 public _secondWindow = 86400; //24 hours
    uint256 public _thirdWindow = 86400; //24 hours
    uint256 public _fourthWindow = 86400; //24 hours

    //wallet to withdraw to
    address payable public _abar =
        payable(address(0x96f10441b25f56AfE30FDB03c6853f0fEC70F389));

    //metadata variables
    string private _baseURI_ = "ipfs://QmW1iuCkEcVekJHtW1wR4S2DUu8Qvsvwfifwch3waRa33f/";
    uint256 private _tokenId;

    //provenance variables
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    string public provenanceHash;

    //build token claimed mapping
    mapping(uint256 => bool) public _buildTokenClaimed;

    //white lsit mapping
    mapping(address => bool) public _whiteList;

    constructor(address arbo1, address arbo2, address arfes, address arfw) ERC721("Wasted Wild", "WAWI") {
        _arbo1 = IERC721(arbo1);
        _arbo2 = IERC721(arbo2);
        _arfes = IERC721(arfes);
        _arfw = IERC721(arfw);
    }

    function setMaxSupply(uint256 maxSupply) external onlyOwner {
        _maxSupply = maxSupply;
    }

    function setMaxPerTxn(uint256 maxPerTxn) external onlyOwner {
        _maxPerTxn = maxPerTxn;
    }

    function toggleBurningEnabled() external onlyOwner {
        _isBurningEnabled = !_isBurningEnabled;
    }

    function toggleMintingEnabled() external onlyOwner {
        _isMintingEnabled = !_isMintingEnabled;
    }

    function toggleClaimingEnabled() external onlyOwner {
        _isClaimingEnabled = !_isClaimingEnabled;
    }

    function setStartSaleTimestamp(uint256 startSaleTimestamp) external onlyOwner {
        _startSaleTimestamp = startSaleTimestamp;
    }

    function setWindows(uint256 firstWindow, uint256 secondWindow, uint256 thirdWindow, uint256 fourthWindow) external onlyOwner {
        _firstWindow = firstWindow;
        _secondWindow = secondWindow;
        _thirdWindow = thirdWindow;
        _fourthWindow = fourthWindow;
    }

    function setWhiteList(address[] calldata addresses) external onlyOwner {
        uint256 count = addresses.length;
        for (uint256 i = 0; i < count; i++) {
            _whiteList[addresses[i]] = true;
        }
    }

    function _mintToken(address to) internal {
        ++_tokenId;
        uint256 newTokenId = _tokenId;

        _safeMint(to, newTokenId);
    }

    function reserveTokens(uint256 tokensToReserve) external onlyOwner {
        for (uint256 i = 0; i < tokensToReserve; i++) {
            _mintToken(msg.sender);
        }
    }

    function claim(uint256 buildTokenId, uint256 additionalTokensToClaim) external payable{
        require(block.timestamp >= _startSaleTimestamp, "sale has not started");
        require(_isClaimingEnabled, "claiming is not enabled");
        require(totalSupply() < _maxSupply, "sold out");
        require(additionalTokensToClaim + 1 <= _maxPerTxn, "max 5 tokens per txn");
        require(
            buildTokenId >= 357,
            "token ID entered is not a BUILD token"
        );
        require(
            _arfes.ownerOf(buildTokenId) == msg.sender,
            "not the owner of the BUILD token entered"
        );
        require(
            _buildTokenClaimed[buildTokenId] == false,
            "WAWI already claimed for this BUILD token"
        );
        require(
            msg.value == additionalTokensToClaim * PRICE_PER_TOKEN,
            "wrong value"
        );

        _buildTokenClaimed[buildTokenId] = true;

        for (uint256 i = 0; i < additionalTokensToClaim + 1; i++) {
            _mintToken(msg.sender);
        }

        //if we haven't set the starting index and this is the first token to be minted after the end of pre-sale, set the starting index block
        //this startingIndexBlock (which serves the purpose of randomness, because we don't know which block it will be on) will then be used to 
        //set the offset for provenance in setStartingIndex
        if (startingIndexBlock == 0 && block.timestamp >= _startSaleTimestamp) {
            startingIndexBlock = block.number;
        } 
    }

    function mint(uint256 tokensToMint) external payable {
        require(block.timestamp >= _startSaleTimestamp + _firstWindow, "minting for non build token holders has not started");
        require(_isMintingEnabled, "minting is not enabled");
        require(totalSupply() < _maxSupply, "sold out");
        require(tokensToMint <= _maxPerTxn, "max 5 tokens per txn");
        require(msg.value == tokensToMint * PRICE_PER_TOKEN, "wrong value");

        if(block.timestamp < _startSaleTimestamp + _firstWindow + _secondWindow){
            require(
                _arfw.balanceOf(msg.sender) + _arfes.balanceOf(msg.sender) > 0,
                "need at least one Firework or Festival token to mint in this window"
            );
        } else if(block.timestamp < _startSaleTimestamp + _firstWindow + _secondWindow + _thirdWindow){
            require(
                _arfw.balanceOf(msg.sender) + _arfes.balanceOf(msg.sender) + _arbo1.balanceOf(msg.sender) + _arbo2.balanceOf(msg.sender) > 0,
                "need at least one Firework, Festival, or ABAR Tree token to mint in this window"
            );
        } else if(block.timestamp < _startSaleTimestamp + _firstWindow + _secondWindow + _thirdWindow + _fourthWindow){
            require(
                (_arfw.balanceOf(msg.sender) + _arfes.balanceOf(msg.sender) + _arbo1.balanceOf(msg.sender) + _arbo2.balanceOf(msg.sender) > 0) || _whiteList[msg.sender] == true,
                "need at least one Firework, Festival, ABAR Tree token, or be on the Whitelist to mint in this window"
            );
        } 

        for (uint256 i = 0; i < tokensToMint; i++) {
            _mintToken(msg.sender);
        }
    }

    function setStartingIndex() external {
        require(startingIndex == 0, "already set");
        require(startingIndexBlock != 0, "startingIndexBlock must be set");
        
        startingIndex = uint256(blockhash(startingIndexBlock)) % (_maxSupply - _reservedArtistEdtns);
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % (_maxSupply - _reservedArtistEdtns);
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }
    
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
            provenanceHash = _provenanceHash;
    }

    function burn(uint256 tokenId) public {
        require(_isBurningEnabled, "burning is not enabled");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        _abar.transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI_ = newBaseURI;
    }
}