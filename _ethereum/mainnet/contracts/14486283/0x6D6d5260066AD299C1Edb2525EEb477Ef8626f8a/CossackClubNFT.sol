// contracts/CossackClubNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CossackClubNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _whitelistSpotsCount;

    string private _tokenBaseURI = "";

    address public withdrawalAddress;

    bool public publicSaleOpened = false;
    bool public claimingOpened = false;

    uint256 public tokenCap = 10000; // Total whitelist + team caps
    uint256 public teamCap = 120;

    uint256 public whitelistSpotPrice = 0.1 ether;
    uint256 public whitelistSpotCap = 3;

    constructor() ERC721("CossackClub", "CCNFT") {}

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    // --- Only owner

    function setBaseURI(string memory baseURI) public onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function setWhitelistSpotPrice(uint256 price) public onlyOwner {
        whitelistSpotPrice = price;
    }

    function setWithdrawalAddress(address wallet) public onlyOwner {
        withdrawalAddress = wallet;
    }

    function setTokenCap(uint256 cap) public onlyOwner {
        tokenCap = cap;
    }

    function setTeamCap(uint256 cap) public onlyOwner {
        teamCap = cap;
    }

    function openPublicSale() public onlyOwner {
        publicSaleOpened = true;
    }

    function closePublicSale() public onlyOwner {
        publicSaleOpened = false;
    }

    function openClaiming() public onlyOwner {
        claimingOpened = true;
    }

    function closeClaiming() public onlyOwner {
        claimingOpened = false;
    }

    function withdraw() public onlyOwner {
        require(
            withdrawalAddress != address(0),
            "Withdrawal address must be set"
        );
        require(address(this).balance > 0, "Cannot withdraw zero balance");
        payable(withdrawalAddress).transfer(address(this).balance);
    }

    function _mintToken(address receiver) internal returns (uint256) {
        require(_tokenIds.current() < tokenCap, "Token cap exceeded");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        _setTokenURI(
            newItemId,
            string(abi.encodePacked(Strings.toString(newItemId), ".json"))
        );
        return newItemId;
    }

    function mint(address receiver) external onlyOwner returns (uint256) {
        return _mintToken(receiver);
    }

    // ---

    // --- Whitelist

    event WhitelistSpotTaken(address wallet, uint256 amount);

    struct WhitelistItem {
        uint256 spots;
        uint256 claims;
    }

    mapping(address => WhitelistItem) private _whitelist;

    function takeWhitelistSpots(uint256 amount)
        external
        payable
        returns (uint256)
    {
        require(publicSaleOpened, "Public sale is not opened");
        require(spotsLeft() >= amount, "Whitelist cap exceeded");
        require(
            canTakeWhitelistSpots(amount, msg.sender),
            "Whitelist spot cap exceeded"
        );
        require(msg.value >= whitelistSpotPrice * amount, "Not enough ether");

        _whitelist[msg.sender].spots = _whitelist[msg.sender].spots + amount;

        uint256 i = 0;
        while (i < amount) {
            _whitelistSpotsCount.increment();
            i++;
        }

        emit WhitelistSpotTaken(msg.sender, amount);

        return _whitelist[msg.sender].spots;
    }

    function claimFromWhitelist() external returns (uint256) {
        require(claimingOpened, "Claiming is not opened");
        require(
            availableWhitelistClaims(msg.sender) > 0,
            "You do not have spot"
        );

        uint256 tokenId = _mintToken(msg.sender);

        _whitelist[msg.sender].claims = _whitelist[msg.sender].claims + 1;

        return tokenId;
    }

    function availableWhitelistSpots(address wallet)
        public
        view
        returns (uint256)
    {
        return whitelistSpotCap - _whitelist[wallet].spots;
    }

    function availableWhitelistClaims(address wallet)
        public
        view
        returns (uint256)
    {
        return _whitelist[wallet].spots - _whitelist[wallet].claims;
    }

    function whitelistSpots(address wallet) public view returns (uint256) {
        return _whitelist[wallet].spots;
    }

    function whitelistClaims(address wallet) public view returns (uint256) {
        return _whitelist[wallet].claims;
    }

    function canTakeWhitelistSpots(uint256 amount, address wallet)
        public
        view
        returns (bool)
    {
        return availableWhitelistSpots(wallet) > amount - 1;
    }

    // ---

    function spotsLeft() public view returns (uint256) {
        return tokenCap - teamCap - _whitelistSpotsCount.current();
    }

    function tokensAvailable() public view returns (uint256) {
        return tokenCap - _tokenIds.current();
    }
}
