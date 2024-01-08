// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract Ethnets is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokensIds;

    uint256 public netPrice = 0.05 ether;

    string public _baseTokenURI = "";

    string public NET_PROVENANCE = "";

    string public LICENSE_TEXT = "";

    bool licenseLocked = false;

    uint256 public startTime = 1639353600;

    uint256 public MAX_MINTABLE_PER_ADDR = 1;

    uint256 public constant MAX_NETS = 18;

    uint public netReserve = 10;

    bool public saleIsActive = false;

    event licenseIsLocked(string _license);

    constructor() ERC721("Ethnets", "ETHNETS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        _baseTokenURI = __baseURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        NET_PROVENANCE = provenanceHash;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Token ID out of range");
        return LICENSE_TEXT;
    }

    function lockLicense() public onlyOwner {
        licenseLocked = true;
        emit licenseIsLocked(LICENSE_TEXT);
    }

    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License is already locked");
        LICENSE_TEXT = _license;
    }

    function setSaleState(bool _saleIsActive) public onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        netPrice = _newPrice;
    }

    function setStartTime(uint256 newStartTime) public onlyOwner {
        startTime = newStartTime;
    }

    function setMaxMintablePerAddr(uint256 _newMaxMintablePerAddr) public onlyOwner {
        MAX_MINTABLE_PER_ADDR = _newMaxMintablePerAddr;
    }

    function reserveNet(address _to) public onlyOwner {
        require(netReserve > 0, "Out of reserves");

        _safeMint(_to, _tokensIds.current());
        _tokensIds.increment();

        netReserve = netReserve.sub(1);
    }

    function mintNet() public payable {
        require(saleIsActive, "Current sale is inactive");
        require(block.timestamp >= startTime, "Drop has yet started");
        require(totalSupply().add(1) <= MAX_NETS, "All nets have been minted");
        require(balanceOf(msg.sender) < MAX_MINTABLE_PER_ADDR, "Limit max mintable per wallet at sales");
        require(msg.value >= netPrice.mul(1), "Must send at least unit price of net");

        _safeMint(msg.sender, _tokensIds.current());
        _tokensIds.increment();
    }

}
