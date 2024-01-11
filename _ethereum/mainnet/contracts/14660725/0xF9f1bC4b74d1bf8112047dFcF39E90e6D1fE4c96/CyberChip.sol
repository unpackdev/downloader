pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./Strings.sol";

contract CyberChip is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    enum MintingStage {
        DISABLED,
        PHASE1,
        PHASE2
    }

    MintingStage private stage;

    address private tokenAddress;
    address private cyberKeyNFTAddress;
    address private cyberSnailNFTAddress;

    uint256 private price;
    uint256 private maxSupply;

    string private baseURIMain;
    string private baseURIEnding;

    mapping(address => uint256) private addressMapping;

    mapping(address => bool) private phase1AddresMapping;
    mapping(uint256 => bool) private phase1CyberKeyMapping;

    mapping(uint256 => bool) private phase2CyberKeyMapping;
    mapping(uint256 => bool) private phase2CyberSnailMapping;

    constructor(
        address _tokenAddress,
        address _cyberKeyNFTAddress,
        address _cyberSnailNFTAddress
    ) ERC721("Cyber Chip", "Cyber Chip") {
        tokenAddress = _tokenAddress;
        cyberKeyNFTAddress = _cyberKeyNFTAddress;
        cyberSnailNFTAddress = _cyberSnailNFTAddress;

        price = 20000;
        maxSupply = 3333;
        stage = MintingStage.DISABLED;
    }
    function _checkAddressEligibilityPhase1(address addr)
        internal
        view
        returns (bool res)
    {
        if (phase1AddresMapping[addr]) return false;
        for (uint256 i = 0; i < ERC721(cyberKeyNFTAddress).balanceOf(addr); i++) {
            uint256 id = ERC721Enumerable(cyberKeyNFTAddress).tokenOfOwnerByIndex(
                addr,
                i
            );
            if (!phase1CyberKeyMapping[id]) return true;
        }
        return false;
    }

    function _mapUsedNFTsAndAddressPhase1(address addr) internal {
        for (uint256 i = 0; i < ERC721(cyberKeyNFTAddress).balanceOf(addr); i++) {
            uint256 id = ERC721Enumerable(cyberKeyNFTAddress).tokenOfOwnerByIndex(
                addr,
                i
            );
            if (!phase1CyberKeyMapping[id]) phase1CyberKeyMapping[id] = true;
        }
        phase1AddresMapping[addr] = true;
        addressMapping[addr] = 1;
    }

    function _checkAddressEligibilityPhase2(address addr)
        internal
        view
        returns (uint256 res)
    {
        if (addressMapping[addr] > 0) return 5-addressMapping[addr];
        for (uint256 i = 0; i < ERC721(cyberKeyNFTAddress).balanceOf(addr); i++) {
            uint256 id = ERC721Enumerable(cyberKeyNFTAddress).tokenOfOwnerByIndex(
                addr,
                i
            );
            if (!phase2CyberKeyMapping[id]) {
                if (phase1CyberKeyMapping[id] || phase1AddresMapping[addr]) return 4;
                else return 5;
            }
        }
        for (uint256 i = 0; i < ERC721(cyberSnailNFTAddress).balanceOf(addr); i++) {
            uint256 id = ERC721Enumerable(cyberSnailNFTAddress).tokenOfOwnerByIndex(
                addr,
                i
            );
            if (!phase2CyberSnailMapping[id]) {
                if (phase1AddresMapping[addr]) return 4;
                else return 5;
            }
        }
        return 0;
    }

    function _mapUsedNFTsAndAddressPhase2(address addr, uint256 count) internal {
        for (uint256 i = 0; i < ERC721(cyberKeyNFTAddress).balanceOf(addr); i++) {
            uint256 id = ERC721Enumerable(cyberKeyNFTAddress).tokenOfOwnerByIndex(
                addr,
                i
            );
            if (!phase2CyberKeyMapping[id]) phase2CyberKeyMapping[id] = true;
        }
        for (uint256 i = 0; i < ERC721(cyberSnailNFTAddress).balanceOf(addr); i++) {
            uint256 id = ERC721Enumerable(cyberSnailNFTAddress).tokenOfOwnerByIndex(
                addr,
                i
            );
            if (!phase2CyberSnailMapping[id]) phase2CyberSnailMapping[id] = true;
        }
        addressMapping[addr] = addressMapping[addr] + count;
    }

    function _incrementSafeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < maxSupply, "All NFTs are minted");

        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _mintPhase1(address addr) internal {
        require(_checkAddressEligibilityPhase1(addr), "address not eligible");
        if (price > 0)
            IERC20(tokenAddress).transferFrom(addr, address(this), price);
        _mapUsedNFTsAndAddressPhase1(addr);
        _incrementSafeMint(addr);
    }

    function _mintPhase2(address addr, uint256 count) internal {
        require(
            (maxSupply - _tokenIdCounter.current()) > count,
            "max supply not big enough"
        );
        uint256 eligibleCount = _checkAddressEligibilityPhase2(addr);
        require(eligibleCount != 0, "address not eligible");
        require(eligibleCount >= count, "count too high");
        if (price > 0)
            IERC20(tokenAddress).transferFrom(
                addr,
                address(this),
                price * count
            );
        _mapUsedNFTsAndAddressPhase2(addr, count);
        for (uint256 i = 0; i < count; i++) {
            _incrementSafeMint(addr);
        }
    }

    function safeMint(address to, uint256 count) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            _incrementSafeMint(to);
        }
    }

    function mint(uint256 count) public {
        require(stage != MintingStage.DISABLED, "This fuinction is not active");
        if (stage == MintingStage.PHASE1) {
            require(count == 1, "phase1 only accepts single mints");
            _mintPhase1(msg.sender);
        } else {
            _mintPhase2(msg.sender, count);
        }
    }

    function getAddressEligibilityPhase1(address addr)
        public
        view
        returns (bool)
    {
        return _checkAddressEligibilityPhase1(addr);
    }

    function getAddressEligibilityPhase2(address addr)
        public
        view
        returns (uint256)
    {
        return _checkAddressEligibilityPhase2(addr);
    }

    function setStage(uint256 s) public onlyOwner {
        if (s == 1) {
            stage = MintingStage.PHASE1;
        } else if (s == 2) {
            stage = MintingStage.PHASE2;
        } else {
            stage = MintingStage.DISABLED;
        }
    }

    function readStage() public view returns (MintingStage _stage) {
        return stage;
    }

    function setURI(string memory main, string memory ending) public onlyOwner {
        baseURIMain = main;
        baseURIEnding = ending;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenIdCounter.current() > tokenId, "tokenId not minted");
        return
            string(
                abi.encodePacked(
                    baseURIMain,
                    Strings.toString(tokenId),
                    baseURIEnding
                )
            );
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
