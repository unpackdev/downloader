// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./Pausable.sol";
import "./ERC721A.sol";

contract ETHWalkersMintPass is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    uint8 public constant maxMintPassPurchase = 10;
    uint public maxMintPass = 500;
    uint private _EWMPReserve = 100;
    mapping(address => uint8) numberMinted;
    address payable public payoutsAddress = payable(address(0x2608b7D6D6E7d98f1b9474527C3c1A0eD54bE399));
    uint public allowListSale = 1656691200; // 7/1 at 9am PDT
    uint public publicSale = 1656691200; // 7/1 at 9am PDT
    uint public endSale = 1656864000; // 7/3 at 9am PDT

    uint256 private _MintPassPrice = 150000000000000000; // 0.15 ETH
    string private baseURI;
    address public whitelistSigner = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

    constructor() ERC721A("ETH Walkers Mint Pass", "EWMP") { }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _MintPassPrice = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _MintPassPrice;
    }

    function setSaleTimes(uint[] memory _newTimes) external onlyOwner {
        require(_newTimes.length == 3, "You need to update all times at once");
        allowListSale = _newTimes[0];
        publicSale = _newTimes[1];
        endSale = _newTimes[2];
    }

    function reserveWalkerPass(address _to, uint256 _reserveAmount) public onlyOwner {
        require(_reserveAmount > 0 && _reserveAmount <= _EWMPReserve, "Reserve limit has been reached");
        require(totalSupply().add(_reserveAmount) <= maxMintPass, "No more tokens left to mint");
        _EWMPReserve = _EWMPReserve.sub(_reserveAmount);
        _safeMint(_to ,_reserveAmount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setSignerAddress(address signer) public onlyOwner {
        whitelistSigner = signer;
    }

    //Constants for signing whitelist
    bytes32 constant DOMAIN_SEPERATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("Signer NFT Distributor"),
            keccak256("1"),
            uint256(1),
            address(0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC)
        ));

    bytes32 constant ENTRY_TYPEHASH = keccak256("Entry(uint256 index,address wallet)");

    function allowlistETHWalkerMintPass(uint8 numberOfTokens, uint index, bytes memory signature) external payable whenNotPaused {
        require(block.timestamp >= allowListSale && block.timestamp <= endSale, "Allowlist-sale must be started");
        require(numberMinted[_msgSender()] + numberOfTokens <= maxMintPassPurchase, "Exceeds maximum per wallet");
        require(!isContract(msg.sender), "I fight for the user! No contracts");

        // verify signature
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPERATOR,
                keccak256(abi.encode(
                    ENTRY_TYPEHASH,
                    index,
                    _msgSender()
                ))
            ));
        address claimSigner = ECDSA.recover(digest, signature);
        require(claimSigner == whitelistSigner, "Invalid Message Signer.");

        _mint(_msgSender(), numberOfTokens);
        numberMinted[_msgSender()] += numberOfTokens;

        (bool sent, ) = payoutsAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with payoutsAddress");
    }

    function mintETHWalkerMintPass(uint numberOfTokens) external payable whenNotPaused {
        require(numberOfTokens > 0 && numberOfTokens <= maxMintPassPurchase, "Oops - you can only mint 10 passes at a time");
        require(msg.value >= _MintPassPrice.mul(numberOfTokens), "Ether value is incorrect. Check and try again");
        require(!isContract(msg.sender), "I fight for the user! No contracts");
        require(totalSupply().add(numberOfTokens) <= maxMintPass, "Purchase exceeds max supply of passes");
        require(block.timestamp >= publicSale && block.timestamp <= endSale, "Public sale not started");

        _mint(_msgSender(), numberOfTokens);

        (bool sent, ) = payoutsAddress.call{value: address(this).balance}("");
        require(sent, "Something wrong with payoutsAddress");
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            uint256 current_token = 0;
            for (index = 0; index < totalSupply() && current_token < tokenCount; index++) {
                if (ownerOf(index) == _owner){
                    result[current_token] = index;
                    current_token++;
                }
            }
            return result;
        }
    }

}