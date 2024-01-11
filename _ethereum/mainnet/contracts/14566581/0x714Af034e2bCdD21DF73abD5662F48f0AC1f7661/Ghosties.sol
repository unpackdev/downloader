// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract Ghosties is ERC721Enumerable, Ownable, AccessControl {
    using Strings for uint256;

    bytes32 public constant WHITE_LIST_ROLE = keccak256("WHITE_LIST_ROLE");
    uint256 public constant PRICE = 0.07 ether;
    uint256 public constant EARLY_NEIGHBOR_PRICE = 0.04 ether;
    uint256 public constant PREMINT_PRICE = 0.05 ether;
    uint256 public constant TOTAL_NUMBER_OF_GHOSTIES = 10000;

    uint256 public giveaway_reserved = 300;
    uint256 public pre_mint_reserved = 2000;

    mapping(address => bool) private _early_neighbors;
    mapping(address => bool) private _pre_sale_minters;

    bool public paused_mint = true;
    bool public paused_pre_mint = true;
    string private _baseTokenURI = "";
    string private suffix = "";


    // initial team
    address ghostieseth = 0x9F692c1c9E5c7ef1d55a80196B8914F274c30f02;

    modifier whenMintNotPaused() {
        require(!paused_mint, "Ghosties: mint is paused");
        _;
    }

    modifier whenPreMintNotPaused() {
        require(!paused_pre_mint, "Ghosties: pre mint is paused");
        _;
    }

    modifier preMintAllowedAccount(address account) {
        require(is_pre_mint_allowed(account), "Ghosties: account is not allowed to pre mint");
        _;
    }

    event MintPaused(address account);
    event MintUnpaused(address account);
    event PreMintPaused(address account);
    event PreMintUnpaused(address account);
    event setPreMintRole(address account);
    event redeemedPreMint(address account);

    constructor(
        string memory _name,
        string memory _symbol
    )
        ERC721(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, ghostieseth);

        _setupRole(WHITE_LIST_ROLE, msg.sender);
        _setupRole(WHITE_LIST_ROLE, ghostieseth);
    }

    fallback() external payable { }

    receive() external payable { }

    function mint(uint256 num) public payable whenMintNotPaused() {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);
        require( num <= 10,                                                             "Ghosties: You can mint a maximum of 10 Ghosties" );
        require( tokenCount + num <= 10,                                                "Ghosties: You can mint a maximum of 10 Ghosties per wallet" );
        require( supply + num <= TOTAL_NUMBER_OF_GHOSTIES - giveaway_reserved,          "Ghosties: Exceeds maximum supply" );
        require( msg.value >= PRICE * num,                                              "Ghosties: Ether sent is less than PRICE * num" );

        for(uint256 i; i < num; i++) {
            _safeMint( msg.sender, supply + i );
        }
    }

    function pre_mint(uint256 num) public payable whenPreMintNotPaused() preMintAllowedAccount(msg.sender){
        require( pre_mint_reserved >= num,                        "Ghosties: Exceeds pre mint reserved Ghosties supply");
        if (_pre_sale_minters[msg.sender]) {
            require( msg.value >= PREMINT_PRICE * num,            "Ghosties: Ether sent is less than PRICE");
        } else {
            require( msg.value >= EARLY_NEIGHBOR_PRICE * num,     "Ghosties: Ether sent is less than PRICE");
        }
        _pre_sale_minters[msg.sender] = false;
        _early_neighbors[msg.sender] = false;
        pre_mint_reserved -= num;
        uint256 supply = totalSupply();
        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
        emit redeemedPreMint(msg.sender);
    }

    function giveAway(address _to) external onlyRole(WHITE_LIST_ROLE) {
        require(giveaway_reserved > 0, "Ghosties: Exceeds giveaway reserved Ghosties supply" );
        giveaway_reserved -= 1;
        uint256 supply = totalSupply();
        _safeMint( _to, supply);
    }

    function pauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = true;
        emit MintPaused(msg.sender);
    }

    function unpauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = false;
        emit MintUnpaused(msg.sender);
    }

    function pausePreMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_pre_mint = true;
        emit PreMintPaused(msg.sender);
    }

    function unpausePreMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_pre_mint = false;
        emit PreMintUnpaused(msg.sender);
    }

    function setPreMintRoleBatch(address[] calldata _addresses) external onlyRole(WHITE_LIST_ROLE) {
        for(uint256 i; i < _addresses.length; i++) {
            _pre_sale_minters[_addresses[i]] = true;
            emit setPreMintRole(_addresses[i]);
        }
    }

    function setEarlyNeighborRoleBatch(address[] calldata _addresses) external onlyRole(WHITE_LIST_ROLE) {
        for(uint256 i; i < _addresses.length; i++) {
            _early_neighbors[_addresses[i]] = true;
        }
    }

    function setBaseURI(string memory baseURI) public onlyRole(WHITE_LIST_ROLE) {
        _baseTokenURI = baseURI;
    }

    function withdrawAmount(uint256 amount) public onlyRole(WHITE_LIST_ROLE) {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "Ghosties: withdraw amount call without balance");
        require(_balance - amount >= 0, "Ghosties: withdraw amount call with more than the balance");
        require(payable(ghostieseth).send(amount), "Ghosties: FAILED withdraw amount call");
    }

    function withdrawAmount() public onlyRole(WHITE_LIST_ROLE) {
        uint256 _balance = address(this).balance ;
        require(_balance > 0, "Ghosties: withdraw all call without balance");
        require(payable(ghostieseth).send(_balance), "Ghosties: FAILED withdraw all call");
    }

    function setSuffixURI(string memory _suffix) public onlyRole(WHITE_LIST_ROLE) {
        suffix = _suffix;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Ghosties: URI query for nonexistent token");

        string memory baseURI = getBaseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), suffix))
            : '';
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function is_pre_mint_allowed(address account) public view returns (bool) {
        return _pre_sale_minters[account] || _early_neighbors[account];
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
}
